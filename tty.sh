#!/bin/bash
# 4800 character per seconds, close to 4807 Hz (1MHz / 16 / 13)
# 8-bit characters, 2 stop bits, 1 even parity bit, no sticky bit
# No modem controls, allow input, use RTS/CTS flow control
# Disable all output processing

>&2 echo "> configuring tty..."
stty -F /dev/ttyUSB0 \
  speed 4800 \
  cs8 cstopb parenb -parodd -cmspar \
  -hupcl clocal cread crtscts \
  -ocrnl -ofdel -ofill -olcuc -onlcr -onlret -onocr -opost \
  raw 1>/dev/null
sleep 0.1
>&2 echo "> tty configured!"

if [ -z $1 ]
then
    >&2 echo "> writing to tty..."
    cat > /dev/ttyUSB0
    >&2 echo "> tty written!"
elif [ ! $1 -eq 0 ]
then
    >&2 echo "> writing $1 bytes to tty..."
    { cat; cat /dev/zero; } | head -c $1 > /dev/ttyUSB0
    >&2 echo "> tty written!"
fi

>&2 echo "> reading from tty..."
stdbuf -i0 -o0 -e0 cat /dev/ttyUSB0
