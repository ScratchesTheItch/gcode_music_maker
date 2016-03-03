#!/bin/bash

#You must source this file at the top of the script in order for this all to 
#    work
. ../gcode-music.sh

#If you want to override the defaults in the source file above, include them 
#    here
Z_UPPER=210
Z_LOWER=190

#Music starts here
$START
$A4 $THREE_EIGTHS
$G4 $EIGTH
$F4
$G4
$A4
$A4
$A4 $HALF
$G4
$G4
$G4 $HALF
$A4
$C5
$C5 $HALF
$A4 $THREE_EIGTHS 
$G4 $EIGTH
$F4
$G4
$A4
$A4
$A4
$A4
$G4
$G4
$A4
$G4
$F4 $WHOLE

$STOP
