#!/bin/tcsh
#
# This script updates the SG-3100 device's LEDs with WAN and bandwidth status
#

# Usage: customleds.tcsh <mvneta0-2>

# Some notes
# based on gwstatus, set color of first LED
# circle    square    diamond
# led 2  -  led 1  -  led 0
# 6 7 8  -  3 4 5  -  0 1 2 
#
# mvneta0 is OPT
# mvneta1 is LAN
# mvneta2 is WAN

# Some constants
set if = ${1}
set l1 =    900000;
set l2 =  50000000;
set l3 =  90000000;
set l4 = 200000000;
set l5 = 500000000;


switch ($if)
case "mvneta0":
    set lednum = 0
    set pinr = 0
    set ping = 1
    set pinb = 2
    breaksw
case "mvneta1": 
    set lednum = 1
    set pinr = 3
    set ping = 4
    set pinb = 5
    breaksw
case "mvneta2": 
    set lednum = 2
    set pinr = 6
    set ping = 7
    set pinb = 8
    breaksw
endsw


# disable dark time between light bursts
/sbin/sysctl dev.gpio.0.pin.$pinr.T0=0
/sbin/sysctl dev.gpio.0.pin.$pinr.T4=0
/sbin/sysctl dev.gpio.0.pin.$ping.T0=0
/sbin/sysctl dev.gpio.0.pin.$ping.T4=0
/sbin/sysctl dev.gpio.0.pin.$pinb.T0=0
/sbin/sysctl dev.gpio.0.pin.$pinb.T4=0



### the WAN LED is special in that we can monitor it's link status
### make the LED flash red if the WAN link is down.
### otherwise, do the normal color scheme

### Get WAN state (if needed)
if ($if == "mvneta2") then
    echo getting wan things
    set gw = `/usr/local/bin/php /usr/local/sbin/pfSsh.php playback gatewaystatus | grep WAN `
    set gwping = `echo $gw | awk '{ ORS="  "; print $6 }' `
    set gwstatus = `echo $gw | awk '{ ORS="  "; print $7 }' `
else
    echo skipping WAN things
    set gwstatus = "none"
endif

### Get bandwidth usage
# -w X collects for X seconds
# -q 1 quits after one iteration
set sum = `netstat -w 60 -I $if -q 1 | tail -1 | awk '{ ORS="  "; print $4 }' `
#set outbytes = `netstat -w 60 -I $if -q 1 | tail -1 | awk '{ ORS="  "; print $7 }' `
#@ sum = $inbytes + $outbytes

switch ($gwstatus)
case "none":
case "Online": 

    ### The WAN is up, set the color to bandwidth usage
    if ($sum <= $l1) then
        echo no traffic, led dark
        /sbin/sysctl dev.gpio.0.led.$lednum.pwm=1
        /usr/sbin/gpioctl $pinr duty 4
        /usr/sbin/gpioctl $ping duty 4
        /usr/sbin/gpioctl $pinb duty 4

    else if ($sum <= $l2) then
        echo low traffic, led solid green
        /sbin/sysctl dev.gpio.0.led.$lednum.pwm=1
        /usr/sbin/gpioctl $pinr duty 0
        /usr/sbin/gpioctl $ping duty 32
        /usr/sbin/gpioctl $pinb duty 0

    else if ($sum <= $l3) then
        echo medium traffic, led solid blue
        /sbin/sysctl dev.gpio.0.led.$lednum.pwm=1
        /usr/sbin/gpioctl $pinr duty 0
        /usr/sbin/gpioctl $ping duty 0
        /usr/sbin/gpioctl $pinb duty 32

    else if ($sum <= $l4) then
        echo medium-high traffic, led slow flashing purple
        /sbin/sysctl dev.gpio.0.led.$lednum.pwm=0
        /sbin/sysctl dev.gpio.0.led.$lednum.T2=1040
        /sbin/sysctl dev.gpio.0.led.$lednum.T1-T3=520
        /usr/sbin/gpioctl $pinr duty 32
        /usr/sbin/gpioctl $ping duty 0
        /usr/sbin/gpioctl $pinb duty 32

    else if ($sum <= $l5) then
        echo high traffic, led fast flashing bright purple
        # Fast flashing purple
        /sbin/sysctl dev.gpio.0.led.$lednum.pwm=0
        /sbin/sysctl dev.gpio.0.led.$lednum.T2=0
        /sbin/sysctl dev.gpio.0.led.$lednum.T1-T3=520
        /usr/sbin/gpioctl $pinr duty 128
        /usr/sbin/gpioctl $ping duty 0
        /usr/sbin/gpioctl $pinb duty 128

    else
        echo very high traffic, led fast flashing bright orange
        /sbin/sysctl dev.gpio.0.led.$lednum.pwm=0
        /sbin/sysctl dev.gpio.0.led.$lednum.T2=0
        /sbin/sysctl dev.gpio.0.led.$lednum.T1-T3=520
        /usr/sbin/gpioctl $pinr duty 128
        /usr/sbin/gpioctl $ping duty 8
        /usr/sbin/gpioctl $pinb duty 0
    endif
    breaksw



case "down": 
case "Offline":
    echo link down, led red
    /sbin/sysctl dev.gpio.0.led.$lednum.pwm=0
    /sbin/sysctl dev.gpio.0.led.$lednum.T2=520
    /sbin/sysctl dev.gpio.0.led.$lednum.T1-T3=520
    /usr/sbin/gpioctl $pinr duty 128
    /usr/sbin/gpioctl $ping duty 0
    /usr/sbin/gpioctl $pinb duty 0
    breaksw

case "highloss":
case "loss": 
case "highdelay":
case "delay":
case "Warning": 
    echo link decay, led yellow
    /sbin/sysctl dev.gpio.0.led.$lednum.pwm=0
    /sbin/sysctl dev.gpio.0.led.$lednum.T2=520
    /sbin/sysctl dev.gpio.0.led.$lednum.T1-T3=520
    /usr/sbin/gpioctl $pinr duty 128
    /usr/sbin/gpioctl $ping duty 32
    /usr/sbin/gpioctl $pinb duty 0
    breaksw

default:
    echo link state unknown, led white
    /sbin/sysctl dev.gpio.0.led.$lednum.pwm=0
    /sbin/sysctl dev.gpio.0.led.$lednum.T2=520
    /sbin/sysctl dev.gpio.0.led.$lednum.T1-T3=520
    /usr/sbin/gpioctl $pinr duty 128
    /usr/sbin/gpioctl $ping duty 128
    /usr/sbin/gpioctl $pinb duty 128

endsw

