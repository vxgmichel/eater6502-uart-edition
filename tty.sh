#!/bin/bash
stty -F /dev/ttyUSB0 speed 4800 cs8 cstopb parenb -parodd -cmspar -hupcl clocal -cread crtscts -onlcr
{ cat; cat /dev/zero; } | head -c $1 > /dev/ttyUSB0