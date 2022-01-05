# Ben Eater 6502 computer - UART edition

An updated design for Ben Eater 6502 computer that allows the flashing of new programs directly from a USB serial line.

No EEPROM programmer required!*

<sub>\*: Except once for the bootloader</sub>

## Introduction

The 6502 computer by Ben Eater is great, but constantly moving the EEPROM from the computer to the programer and back every time a new program needs to be flashed can quickly get annoying. This README file provides the instructions to add a USB-to-UART interface in order to communicate with another computer. The existing design is also changed a bit in order to allow the 6502 CPU to write to the EEPROM, essentially becoming its own programmer. This way, new programs can be read from the serial interface and written to the EEPROM, allowing developers to flash their programs through a simple write to a tty. In order to properly manage the writing of those subprograms, a bootloader first need to be written to the EEPROM. This repository provides this bootloader along with some subprograms including a random number generator and a solver for the first problem in the Advent of Code 2021.

Have fun :)

## New components

Only three new components are required:

- The **FT232** USB UART board
- The [TL16C550CN](https://www.ti.com/product/TL16C550C) UART element
- The **74HCT04N** hex inverter (6 NOT-gates)

## New wiring

First, note that the 6502 computer can now be powered through USB using the FT232 board.

The new UART component is wired as such:

```
              ╭────────────────────╮
         D0 ──┤ D0             VCC ├─── VCC
         D1 ──┤ D1             /RI ├───x
         D2 ──┤ D2            /DCD ├───x
         D3 ──┤ D3            /DSR ├───x
         D4 ──┤ D4            /CTS ├─── FT232 /RTS
         D5 ──┤ D5              MR ├─── /(/RESET)
         D6 ──┤ D6           /OUT1 ├───x
         D7 ──┤ D7            /DTR ├───x
   /BAUDOUT ──┤ RLCK          /RTS ├─── FT232 /CTS
  FT232 TXD ──┤ SIN          /OUT2 ├───x
  FT232 RXD ──┤ SOUT           INT ├───x
       /A13 ──┤ CS0          RXRDY ├───x
        A14 ──┤ CS1             A0 ├─── A0
/(CLK./A15) ──┤ /CS2            A1 ├─── A1
       RCLK ──┤ /BAUDOUT        A2 ├─── A2
       PHI2 ──┤ XIN           /ADS ├─── GND
           x──┤ XOUT         TXRDY ├───x
        R/W ──┤ /WR1          DDIS ├───x
        GND ──┤ WR2            RD2 ├─── R/W
        GND ──┤ VSS           /RD1 ├─── VCC
              ╰────────────────────╯
```

The control logic needs to be updated so we can write to the ROM:

```
        ╭─────────╮
/RST ───┤  NOT    ├─── UART MR
        │         │
 A13 ───┤  NOT    ├─── UART CS0
        │         │
 R/W ───┤  NOT    ├─── ROM /OE
        │         │
 A15 ───┤  NOT    ├─── /A15
        ╰─────────╯

        ╭─────────╮
 A15 ───┤  NAND   ├─── ROM /CS
PHI2 ───┤         │
        │         │
/A15 ───┤  NAND   ├──┬ RAM /CS
PHI2 ───┤         │  ╰ UART /CS2
        │         │
/A15 ───┤  NAND   ├─── VIA /CS2
 A14 ───┤         │
        ╰─────────╯
```

Note that the boot program expects the following wiring on the VIA ports:
- Port A pin 0: an LED
- Port A pin 1: an active-low push button
- Port A pin 5: LCD display RS
- Port A pin 6: LCD display R/W
- Port A pin 7: LCD display E
- Port B pin 0-7: LCD display 0-7

## Memory map and layouts

The original memory map is left mostly unchanged, except for the insertion of the UART element that mirrors its 8 registers 1024 times over the `0x4000-0x5fff` range (originally part of the RAM).

Several memory layouts for different usage are defined in the following files:
- [map/eater.asm](./map/eater.asm): The original memory layout
- [map/rameater.asm](./map/eater.asm): A memory layout where the program is copied to the ram before being jumped to run
- [map/subeater.asm](./map/eater.asm): The memory layout dedicated to the execution of subprograms
- [map/booteater.asm](./map/eater.asm): The memory layout used by the bootloader program


## The bootloader program

The bootloader program is assemble using the latest version of [customasm](https://github.com/hlorenzi/customasm):
```bash
# Install rust and cargo
$ curl https://sh.rustup.rs -sSf | sh
# Install customasm
$ cargo install customasm
# Assemble the boot program
$ customasm boot.asm
customasm v0.11.12 (x86_64-unknown-linux-gnu)
assembling `boot.asm`...
writing `boot.bin`...
success after 2 iterations
```

Then write the `boot.bin` program to the EEPROM using a programmer and [minipro](https://gitlab.com/DavidGriffith/minipro/):
```bash
# This either require sudo priviledges or udev configuration:
# https://gitlab.com/DavidGriffith/minipro/#udev-configuration-recommended
$ ./tools/minipro -p AT28C256 -w boot.bin
```

Put the EEPROM back into the computer, power it on, keep the button on `PA1` pressed and press reset. You should see the following message:
```
Ready for input
```

If `PA1` is **not** pressed, the boot program runs the current subprogram. At the moment, the subprogram does nothing so let's flash a more interesting one.

## Flashing a subprogram

First choose and assemble a subprogram, e.g `random.asm`:
```bash
$ customasm random.asm
customasm v0.11.12 (x86_64-unknown-linux-gnu)
assembling `random.asm`...
writing `random.bin`...
success after 2 iterations
```

Subprogram size is only 4096 bytes (4 KB):
```bash
$ wc random.bin -c
4096 random.bin
```

The program is then sent to the 6502 computer through `/dev/ttyUSB0`. The tty needs to be configured correctly which is done automatically by `scripts/tty.sh`:
```
$ cat random.bin | scripts/tty.sh 4096
> configuring tty...
> tty configured!
> writing 4096 bytes to tty...
> tty written!
```

If the 6502 computer is in `Ready for input` mode, the light should start blinking while the subprogram is being written to the EEPROM. After a while, the message `Transfer complete!` should appear and the subprogram automatically starts after a second. In this case it should start displaying randomly generated numbers every second:
```
Random: 8c
```
Note that the RNG algorithm uses an [4261412736-cycle xorshift algorithm](https://github.com/edrosten/8bit_rng), which means it's going to take about 130 years before the sequence of random numbers starts repeating.

## Subprogram list

- [hello_word.asm](./hello_world.asm): Simply prints `Hello, World!`, one character at a time
    ```bash
    customasm hello_world.asm && cat hello_world.bin | ./scripts/tty.sh 4096
    ```
- [random.asm](./random.asm): Display a randomly generated 8-bit number in hexadecimal every second
    ```bash
    customasm random.asm && cat random.bin | scripts/tty.sh 4096
    ```
- [test_rom.asm](./test_rom.asm): Check that the ROM can properly be written
    ```bash
    customasm test_rom.asm && cat test_rom.bin | ./scripts/tty.sh 4096
    ```
- [typing.asm](./typing.asm): Use [typing.py](./scripts/typing.py) to type to the LCD display.
    ```bash
    customasm typing.asm && cat typing.bin | ./scripts/tty.sh 4096 && ./scripts/typing.py
    ```
- [accumulate.asm](./accumulate.asm): Accumulate the line-separated decimal numbers sent through the serial line
    ```bash
    customasm accumulate.asm && cat accumulate.bin | ./scripts/tty.sh 4096 && cat data/aoc-2021-01-sample.txt | ./scripts/tty.sh
    ```
- [aoc-2021-01.asm](./aoc-2021-01.asm): Solve the first problem of the Advent of Code 2021
    ```bash
    customasm aoc-2021-01.asm && cat aoc-2021-01.bin | ./scripts/tty.sh 4096 && cat data/aoc-2021-01-data.txt | ./scripts/tty.sh
    ```

## The greasy details

Writing the EEPROM is not as simple as it seems. There's a reason why this chip is different from the RAM: it is persistent yes, but it also take much more time to write it. Data can be written to the EEPROM in bulks of 64 bytes using the following procedure:
- Write `0xaa` at address `0x5555`
- Write `0x55` at address `0x2aaa`
- Write `0xa0` at address `0x5555`
- Write 64 contiguous bytes from a specific page
- Wait until bit 6 of subsequent read requests stops toggling

This wait time corresponds to the EEPROM actually writing itself and it can take up to 10ms. Since the EEPROM will not be available for reading during this period of time, this means that the code that performs this procedure cannot be stored in the EEPROM. Instead it has to be copied to the RAM and jumped to
in order to make sure that the CPU will not try to read instructions from the EEPROM during its writing.

This trick is implemented in the file [lib/rom.asm](./lib/rom.asm).


## Acknowledgments

Many thanks to Florent for helping and putting up with the wiring of those 200 pins :)
