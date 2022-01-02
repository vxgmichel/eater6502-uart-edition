#!/usr/bin/env python
"""
Communicate with ttyUSB0 by successively sending and receiving a line.
"""

import sys
import subprocess

def main():
    subprocess.run("""\
stty -F /dev/ttyUSB0 \
  speed 4800 \
  cs8 cstopb parenb -parodd -cmspar \
  -hupcl clocal cread crtscts \
  -ocrnl -ofdel -ofill -olcuc -onlcr -onlret -onocr -opost \
  raw -echo""", shell=True, check=True, capture_output=True)

    with open(sys.argv[1]) as input_file:
        with open("/dev/ttyUSB0", "r+b", buffering=0) as tty:
            for line in input_file:
                data_in = line.encode()
                print(f"> {data_in!r}", file=sys.stderr)
                tty.write(data_in)
                data_out = tty.readline()
                print(f"< {data_out!r}", file=sys.stderr)
                sys.stdout.buffer.write(data_out)
                sys.stdout.flush()

if __name__ == "__main__":
    main()