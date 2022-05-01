---
title: A Clean Sweep
date: 2015-09-16T20:49:00
author: Graham Wheeler
category: Programming
comments: enabled
---

A long time ago when dinosaurs roamed the earth I was following an academic career. That got subverted but I
enjoyed it while it lasted. Apart from graduate courses in compilers, I got to teach everything from 
computer architecture to assembly language programming to an introductory computing course for social
science students.

When teaching assembly language (in which I was lucky enough to be able to use the M68000, a dream of a 
processor), one of the samples I used to illustrate a number of topics like multi-dimensional arrays,
recursion and function pointers, was a Mine Sweeper game. I recently dug it out and turned in into Python
just for the heck of it.

So here it is. There are no fancy graphics, the field is just printed out as a 2D array of ASCII characters.
To enter a move you use coordinates using a number for the row and letter for the column. E.g. 1C is the
first row, third column (rows are numbered from 1, not 0). You can plant a flag (or clear it) by preceding 
your move with a '-'.
<!-- TEASER_END -->

At some point I might look at using PyQt or something to turn it into a mouse-driven more attractive looking
game. But the interesting stuff is the recursive traversal of the board.

    #!python
    import random
    
    DIMENSION = 8
    MINES = 4
    EXPOSED = 0x10
    FLAG = 0x20
    MINE = 0x40
    
    exposed = 0
    
    def traverse(field, r, c, fn):
        for row in [r-1, r, r+1]:
            if 0 <= row < DIMENSION:
                for col in [c-1, c, c+1]:
                    if 0 <= col < DIMENSION and (row != r or col != c) and
                            not field[row][col] & EXPOSED:
                        fn(field, r, c, row, col)
    
    def check_neighbor(field, r, c, row, col):
        field[r][c] += 1 if field[row][col] & MINE else 0
    
    def init_field():
        field = [[0] * DIMENSION for i in range(0, DIMENSION)]
        # Place mines.
        m = MINES
        while m:
            r = random.randrange(DIMENSION)
            c = random.randrange(DIMENSION)
            if field[r][c] != MINE:
                m -= 1
                field[r][c] = MINE
        # Compute neighbor scores		
        for r in range(0, DIMENSION):
            for c in range(0, DIMENSION):
                if field[r][c] != MINE:
                    traverse(field, r, c, check_neighbor)
        return field
    
    def recursive_expose(field, r, c, row, col):
        global exposed
        cell = field[row][col]
        if cell < 0x10:  # Not a mine, flag or exposed
            exposed += 1
            field[row][col] |= EXPOSED
            if cell == 0:
                traverse(field, row, col, recursive_expose);
    
    def expose(field, r, c):
        recursive_expose(field, 0, 0, r, c)
        return field[r][c] & MINE
    
    def print_field(field):
        print('   ' + ''.join([chr(65 + i) for i in range(0, DIMENSION)]))
        for r in range(0, DIMENSION):
            cells = []
            for c in range(0, DIMENSION):
                if field[r][c] & FLAG:
                    cells.append('F')  # no newline
                elif field[r][c] & EXPOSED:
                    cells.append('*' if field[r][c] & MINE else chr(ord('0') + (field[r][c] & 0xf)))
                else:
                    cells.append('#')
            print('%02d ' % (r + 1) + ''.join(cells))
    
    field = init_field()
    result = "CLEAR"
    while exposed < (DIMENSION * DIMENSION - MINES):
        print_field(field)
        move = raw_input("Move?")
        r = int(move[:-1])
        c = ord(move[-1]) - 65
        if r < 0:
            field[-r - 1][c] ^= FLAG
        elif expose(field, r - 1, c):
            result = "BOOM!"
            break
    
    print_field(field)
    print(result)
    

