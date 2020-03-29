# LED status script

The script in this repository changes the LEDs on the front of the SG3100
based on network interface state and bandwidth.

All LEDs will flash different colors based on bandwidth usage.

The LED on the far left is hooked to the WAN interface. It is special in that
it will flash red or yellow on upstream link errors.
The LED in the middle is for LAN and on the right is for OPT1.

See script for more info.

# Installation
First go to Diagnostics -> Edit File and add the script at /root/customleds.tcsh

Then add a few cron entries (may need Cron package) that runs the following commands every minute by the root user.

/usr/bin/nice -n20 /bin/tcsh /root/customleds.tcsh mvneta0 > /dev/null 2>&1
/usr/bin/nice -n20 /bin/tcsh /root/customleds.tcsh mvneta1 > /dev/null 2>&1
/usr/bin/nice -n20 /bin/tcsh /root/customleds.tcsh mvneta2 > /dev/null 2>&1


# Dev Notes

Netgate forum https://forum.netgate.com/topic/122407/netgate-sg-3100-leds/28

Blog https://www.zacharyschneider.ca/blog/post/2019/12/customizing-leds-netgate-sg-3100

Netstat man page https://www.freebsd.org/cgi/man.cgi?query=netstat&sektion=1

Crons execute in their own process or thread so no need to fork
