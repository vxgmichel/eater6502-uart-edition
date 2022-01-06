#!/usr/bin/env python
"""
Send raw unbuffer data from stdin to ttyUSB0
"""

import sys
import tty
import contextlib
import subprocess

@contextlib.contextmanager
def raw_stdin(stdin=None):
    # Get stdin file descriptor
    if stdin is None:
        stdin = sys.stdin
    fd = stdin.fileno()

    # Backup the current TTY configuration
    old_tty = tty.tcgetattr(fd)
    try:
        # Set stdin to raw and cbreak
        tty.setraw(fd)
        tty.setcbreak(fd)

        # Set stdin to non-blocking mode
        yield stdin

    # Restore stdin original configuration
    finally:
        tty.tcsetattr(fd, tty.TCSADRAIN, old_tty)


def main():
    subprocess.run("""\
stty -F /dev/ttyUSB0 \
  speed 4800 \
  cs8 cstopb parenb -parodd -cmspar \
  -hupcl clocal cread crtscts \
  -ocrnl -ofdel -ofill -olcuc -onlcr -onlret -onocr -opost \
  raw -echo""", shell=True, check=True, capture_output=True)
    with raw_stdin():
        with open("/dev/ttyUSB0", "wb", buffering=0) as serial:
            while True:
                char = sys.stdin.buffer.read(1)
                if char in b'\x03\x04':
                    break
                print(f"> {char!r}", end="\r\n", file=sys.stderr)
                serial.write(char)


if __name__ == "__main__":
    main()