# Assembly programs for Ben Eater 6502 computer

## Instructions

Assemble using [customasm](https://github.com/hlorenzi/customasm):
```bash
$ customasm hello_world.bin
```

Run with [x6502](https://github.com/dbuchwald/x6502/tree/master/src) emulator:
```bash
$ ./x6502 hello_world.bin -r
```

Write to EPROM with [minipro](https://gitlab.com/DavidGriffith/minipro):
```bash
$ sudo ./minipro -p AT28C256 -w hello_world.bin
```

## Programs

- `hello_world.asm`: Display "Hello, World!" on the LCD screen with a delay between each character.
- `random.asm`: Display a random 8-bit number in hexadecimal every second. It uses an [4261412736-cycle xorshift algorithm](https://github.com/edrosten/8bit_rng).