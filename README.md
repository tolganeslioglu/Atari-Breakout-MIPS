# Atari Breakout (MIPS Assembly)

A MIPS-assembly implementation of the classic Atari Breakout game, designed to run under a MIPS simulator (e.g. MARS or Saturn) with a bitmap display.

---

## Table of Contents

* [Features](#features)
* [Prerequisites](#prerequisites)
* [Running](#running)
* [Controls](#controls)
* [Configuration](#configuration)

---

## Features

* **Paddle control & ball physics**: Move a paddle horizontally to bounce a single-pixel ball around the playfield.
* **Brick layout & collision detection**: Seven rows of bricks are laid out beneath a top border; collisions flip the ball’s X or Y vector and optionally erase bricks.
* **Score tracking & dynamic speed**: Each brick hit increments the score; game speed automatically increases every 5 points.
* **Game over screen**: Upon losing, a 32×32 pixel “Game Over” image is displayed before allowing restart.

---

## Prerequisites

* **MIPS simulator**: e.g. [MARS](http://courses.missouristate.edu/KenVollmar/MARS/) or [Saturn](https://github.com/ethanjperez/saturn).

---

## Running

1. **Download** this repository.
2. **Open** `breakout.asm` in your chosen MIPS IDE (we have used Saturn mainly).
3. **Ensure** `gameover_image.asm` is in the same directory.
4. **Assemble and run**:

   * **MARS**: Connect to Bitmap Display and then connect to Keyboard using the Display MMIO Simulator.
   * **Saturn**: Select the **Bitmap** tab; click on the display window to capture keyboard input.

---

## Controls

|  Key  | Action                         |
| :---: | :----------------------------- |
| **a** | Move paddle left               |
| **d** | Move paddle right              |
| **p** | Pause / Start game             |
| **q** | Quit immediately (game over)   |
| **r** | Restart after game over screen |

---

## Configuration

* **Display base address**: `0x10008000` (`$gp`).
* **Keyboard base address**: `0xffff0000`.