---
title: Simply Solving Sudoku
date: 2015-09-10T22:03:00
author: Graham Wheeler
category: Programming
comments: enabled
---

It's been a long time since I last blogged. I've been meaning to for oh so long but you know what they say about the road to hell. For a while I maintained my [math blog](http://www.magimathics.com) but even that has been fallow for some time.

Fortunately, I stumbled upon Peter Norvig's [article](http://norvig.com/sudoku.html) about solving Sudoku, and that has provided the impetus. His approach is probably the most sensible I have seen for a while; there seem to be some really bad solvers out there. I was unimpressed with the one by Skiena in the  [Algorithm Design Manual](http://www.algorist.com/),  although the truly ridiculous one has to be the so-overblown-I-took-a-whole-book approach in [Programming Sudoku](https://amzn.to/3mHJsy9);  the mind simply boggles at how complex some people make trivial things.

Because solving Sudoku is indeed trivial. There is nothing to it. All you need is a very simple backtracking search. I wrote the solver below originally more than 10 years ago in Javascript and it was used as a generator running on extremely low-powered Microsoft SPOT smart watches. For fun I dug it out, turned it into Python, and tested it on ["the world's hardest Sudoku puzzle"](https://www.kristanix.com/sudokuepic/worlds-hardest-sudoku.php). How fast can you blink?
<!-- TEASER_END -->

But still some people [make a big deal out of it all](https://gigaom.com/2012/10/12/meet-the-algorithm-thats-way-better-than-you-at-sudoku/)...

    #!python
    rows = [0xffff] * 9
    cols = [0xffff] * 9
    rgns = [0xffff] * 9
    board = [0]*81
    
    def init(puz):
        global board, rows, cols, rgns, board
        for r, row in enumerate(puz):
            for c, ch in enumerate(row):
                board[r * 9 + c] = ch
                if ch == '.':
                    continue
                m = ~(1 << (ord(ch) - 48))
                rows[r] &= m
                cols[c] &= m
                rgns[(r // 3) * 3 + (c // 3)] &= m
    
    def fill(pos):
        global board, rows, cols, rgns
        if pos == 81:
            return True
        elif board[pos] != '.':
            return fill(pos + 1)
        r = pos // 9
        c = pos % 9
        allowed = rows[r] & cols[c]
        if allowed:
            rg = (r // 3) * 3 + (c // 3)
            allowed &= rgns[rg]
            if allowed:
                for i in range(1, 10):
                    tm = 1 << i
                    if allowed & tm:
                        im = ~tm
                        rows[r] &= im
                        cols[c] &= im
                        rgns[rg] &= im
                        if fill(pos + 1):
                            board[pos] = chr(48 + i)
                            return True
                        rows[r] |= tm
                        cols[c] |= tm
                        rgns[rg] |= tm
        return False
    
    def solve(puz):
        init(puz)
        return fill(0)
    
    if solve([
    "1....7.9.",
    ".3..2...8",
    "..96..5..",
    "..53..9..",
    ".1..8...2",
    "6....4...",
    "3......1.",
    ".4......7",
    "..7...3.."
    ]):
        for i in xrange(0, 81, 9):
            print ''.join(board[i:i+9])    




