#!/bin/bash

################################################################################

# GLOBAL VARIABLES - Control playback, can be overridden by defining values
#                    within your music file

################################################################################
export TEMPO=240 #Defined as number of quarter notes/minute
export STEPS_PER_MM=80 #Change depending on your device
export SECS_PER_MIN=60 #Hopefully never change
export NUMBER_RE='^[0-9]+([.][0-9]+)?$' #Regex to check for a number

#These variables specify the range of z coordinates the hot end will traverse
#     in order to make music.  Works well for a Rostock Max V2.  If using
#     another printer, you may want to readjust which motor is commanded to
#     move in order to get the best playback
export Z_LOWER="150"
export Z_START="200"
export Z_UPPER="250"
export Z_CURRENT="${Z_START}"
export Z_DIRECTION="1"



################################################################################

# FUNCTIONS

################################################################################

# play [Frequency] [Duration]  , where
#    Frequency=decimal frequency in Hz, C4 if not specified
#    Duration=decimal length as compared to a whole note, Quarter note if not
#             specified

#    This function generates the g-code needed to make the printer make music.
#         It computes the correct feedrate to match desired frequency and
#         distance to match note duration.  It then computes the absolute
#         z-height of the hot end, makes sure its within the defined range, and
#         reverses the direction of travel, if needed.
function play(){

    #check for note frequency, if not provided (or a number), set to C4
    if ! [[ "$1" =~ $NUMBER_RE ]]; then
        FREQUENCY="261.63"
    else
        FREQUENCY="$1"
    fi
    #Turn frequency into feedrate (done in stages--thanks BASH math!)
    FREQUENCY="$(echo "scale=2; ${FREQUENCY} * ${SECS_PER_MIN}"|bc)"
    FREQUENCY="$(echo "scale=2; ${FREQUENCY} / ${STEPS_PER_MM}"|bc)"

    #check for note duration.  If not provided (or a number),
    #     set to 0.25 (a quarter note)
    if ! [[ "$2" =~ $NUMBER_RE ]]; then
        DURATION="0.25"
    else
        DURATION="$2"
    fi
    #Turn duration(time) into duration(distance).  Calculated in stages
    DURATION="$(echo "scale=2; ${DURATION} * 4"|bc)"
    DURATION="$(echo "scale=2; ${DURATION} - 0.010"|bc)"
    DURATION="$(echo "scale=2; ${DURATION} * ${FREQUENCY}"|bc)"
    DURATION="$(echo "scale=2; ${DURATION} / ${TEMPO}"|bc)"

    #If moving in the positive direction, check that we aren't exceeding our
    #     specified upper limit.  If so, reverse direction
    if [ "${Z_DIRECTION}" = "1" ]; then
        if [ "$(( $( echo "scale=0; ${Z_CURRENT} * 100"|bc|cut -d. -f1 ) + $( echo "scale=0; ${DURATION} * 100"|bc|cut -d. -f1 ) ))" -gt "$( echo "scale=0; ${Z_UPPER} * 100"|bc|cut -d. -f1)" ]; then
            Z_DIRECTION="-1"
        fi
    #Else, if moving in the positive direction, check that we aren't exceeding
    #     our specified lower limit.  If so, reverse direction
    else
        if [ "$(( $( echo "scale=0; ${Z_CURRENT} * 100"|bc|cut -d. -f1 ) - $( echo "scale=0; ${DURATION} * 100"|bc|cut -d. -f1 ) ))" -lt "$( echo "scale=0; ${Z_LOWER} * 100"|bc|cut -d. -f1)" ]; then
            Z_DIRECTION="1"
        fi
    fi 

    #Compute the new z-height that the hot end should travel to
    Z_CURRENT="$(echo "scale=2; ${Z_CURRENT} + (${DURATION} * ${Z_DIRECTION})"|bc)"

    #Output the required g-code to generate the desired note
    echo "G1 Z${Z_CURRENT} F${FREQUENCY}"
    echo "G4 P010" #Needed to make two of the same note sound like different notes
}

# pause [Duration]  , where
#    Duration=decimal length or pause as compared to a whole note, Quarter note
#             if not specified

#    This subroutine is called when a pause is needed in the music.  Turns a
#          pause given in fractional notes and outputs g-code in milliseconds
function pause(){

    #Check, to see if you've got a number.  If not (or not supplied), use the
    #     default value (quarter note)
    if ! [[ "$1" =~ $NUMBER_RE ]]; then
        DURATION="0.25"
    else
        DURATION="$1"
    fi

    #Do the maths to turn it into a number of milliseconds
    DURATION="$( echo "scale=2; ${DURATION} *4"|bc)"
    DURATION="$( echo "scale=0; (60000 * ${DURATION})/${TEMPO}"|bc|cut -d. -f1)"

    #Output the G-code
    echo "G4 P${DURATION}"
}

# start (takes no arguments)
#
#    This subroutine produces the start of the G-code for music.  In short,
#        it homes the arms, sends the hot end to the designated start position,
#        and waits half a second prior to playing music
function start(){
    echo "G28"
    echo "G1 Z${Z_CURRENT} F15000"
    echo "G4 P500"
}

# stop (takes no arguments)
#
#    This subroutine produces the final G-code after the music plays.  In short,
#        it waits half a second and then homes the arms.
function stop(){
echo "G4 P500"
echo "G28"
}

################################################################################

#     MUSIC VARIABLES -- One variable each for start, stop, pause.  Two ways to
#         specify the most common note lengths.  One variable for each musical
#         note (exception is the FLAT/SHARP, it has two).  Please see included
#         sample music files for examples of how it all goes together.

START="start"
STOP="stop"
PAUSE="pause"

EIGTH="0.125"
QUARTER="0.25"
THREE_EIGTHS="0.375"
HALF="0.5"
THREE_QUARTERS="0.75"
WHOLE="1"

EIGHT_NOTE="0.125"
QUARTER_NOTE="0.25"
THREE_EIGTH_NOTE="0.375"
HALF_NOTE="0.5"
THREE_QUARTER_NOTE="0.75"
WHOLE_NOTE="1"

C0="play 16.35"
C0SHARP="play 17.32"
D0FLAT="play 17.32"
D0="play 18.35"
D0SHARP="play 19.45"
E0FLAT="play 19.45"
E0="play 20.60"
F0="play 21.83"
F0SHARP="play 23.12"
G0FLAT="play 23.12"
G0="play 24.50"
G0SHARP="play 25.96"
A0FLAT="play 25.96"
A0="play 27.50"
A0SHARP="play 29.14"
B0FLAT="play 29.14"
B0="play 30.87"
C1="play 32.70"
C1SHARP="play 34.65"
D1FLAT="play 34.65"
D1="play 36.71"
D1SHARP="play 38.89"
E1FLAT="play 38.89"
E1="play 41.20"
F1="play 43.65"
F1SHARP="play 46.25"
G1FLAT="play 46.25"
G1="play 49.00"
G1SHARP="play 51.91"
A1FLAT="play 51.91"
A1="play 55.00"
A1SHARP="play 58.27"
B1FLAT="play 58.27"
B1="play 61.74"
C2="play 65.41"
C2SHARP="play 69.30"
D2FLAT="play 69.30"
D2="play 73.42"
D2SHARP="play 77.78"
E2FLAT="play 77.78"
E2="play 82.41"
F2="play 87.31"
F2SHARP="play 92.50"
G2FLAT="play 92.50"
G2="play 98.00"
G2SHARP="play 103.83"
A2FLAT="play 103.83"
A2="play 110.00"
A2SHARP="play 116.54"
B2FLAT="play 116.54"
B2="play 123.47"
C3="play 130.81"
C3SHARP="play 138.59"
D3FLAT="play 138.59"
D3="play 146.83"
D3SHARP="play 155.56"
E3FLAT="play 155.56"
E3="play 164.81"
F3="play 174.61"
F3SHARP="play 185.00"
G3FLAT="play 185.00"
G3="play 196.00"
G3SHARP="play 207.65"
A3FLAT="play 207.65"
A3="play 220.00"
A3SHARP="play 233.08"
B3FLAT="play 233.08"
B3="play 246.94"
C4="play 261.63"
C4SHARP="play 277.18"
D4FLAT="play 277.18"
D4="play 293.66"
D4SHARP="play 311.13"
E4FLAT="play 311.13"
E4="play 329.63"
F4="play 349.23"
F4SHARP="play 369.99"
G4FLAT="play 369.99"
G4="play 392.00"
G4SHARP="play 415.30"
A4FLAT="play 415.30"
A4="play 440.00"
A4SHARP="play 466.16"
B4FLAT="play 466.16"
B4="play 493.88"
C5="play 523.25"
C5SHARP="play 554.37"
D5FLAT="play 554.37"
D5="play 587.33"
D5SHARP="play 622.25"
E5FLAT="play 622.25"
E5="play 659.25"
F5="play 698.46"
F5SHARP="play 739.99"
G5FLAT="play 739.99"
G5="play 783.99"
G5SHARP="play 830.61"
A5FLAT="play 830.61"
A5="play 880.00"
A5SHARP="play 932.33"
B5FLAT="play 932.33"
B5="play 987.77"
C6="play 1046.50"
C6SHARP="play 1108.73"
D6FLAT="play 1108.73"
D6="play 1174.66"
D6SHARP="play 1244.51"
E6FLAT="play 1244.51"
E6="play 1318.51"
F6="play 1396.91"
F6SHARP="play 1479.98"
G6FLAT="play 1479.98"
G6="play 1567.98"
G6SHARP="play 1661.22"
A6FLAT="play 1661.22"
A6="play 1760.00"
A6SHARP="play 1864.66"
B6FLAT="play 1864.66"
B6="play 1975.53"
C7="play 2093.00"
C7SHARP="play 2217.46"
D7FLAT="play 2217.46"
D7="play 2349.32"
D7SHARP="play 2849.02"
E7FLAT="play 2489.02"
E7="play 2637.02"
F7="play 2793.83"
F7SHARP="play 2959.96"
G7FLAT="play 2959.96"
G7="play 3135.96"
G7SHARP="play 3322.44"
A7FLAT="play 3322.44"
A7="play 3520.00"
A7SHARP="play 3729.31"
B7FLAT="play 3729.31"
B7="play 3951.07"
C8="play 4186.01"
C8SHARP="play 4434.92"
D8FLAT="play 4434.92"
D8="play 4698.63"
D8SHARP="play 4978.03"
E8FLAT="play 4978.03"
E8="play 5274.04"
F8="play 5587.65"
F8SHARP="play 5919.91"
G8FLAT="play 5919.91"
G8="play 6271.93"
G8SHARP="play 6644.88"
A8FLAT="play 6644.88"
A8="play 7040.00"
A8SHARP="play 7458.62"
B8FLAT="play 7458.62"
B8="play 7902.13"
