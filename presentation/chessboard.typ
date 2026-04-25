#let boardsize = 5

#let b = grid.cell(text([♝], size: 35pt), inset: 0pt, align: center + horizon)
#let m = grid.cell([], stroke: 1.2pt + red)
#let s(s) = grid.cell(text([#s], size: 30pt), inset: 0pt, align: center + horizon)


#let board1 = grid(
    rows: boardsize+1,
    columns: boardsize+1,
    stroke: (x,y) => if x>0 and y>0 {0.3pt},
    inset: 16pt,
    fill: (x, y) => if x>0 and y>0 and calc.rem(x+y, 2) == 1 {aqua},


    [], ..range(1, boardsize+1).map(str),
    [1], [], [], [], [], [],
    [2], [], [], m, [], m, 
    [3], [], [], [], b, [],
    [4], [], [], m, [], m,
    [5], [], [], [], [], [],
)
#board1

#let board2 = grid(
    rows: boardsize+1,
    columns: boardsize+1,
    stroke: (x,y) => if x>0 and y>0 {0.3pt},
    inset: 16pt,
    fill: (x, y) => if x>0 and y>0 and calc.rem(x+y, 2) == 1 {aqua},


    [], ..range(1, boardsize+1).map(str),
    [1], [], [], [], [], [],
    [2], [], [], [], m, m, 
    [3], [], [], [], [], b,
    [4], [], [], [], m, m,
    [5], [], [], [], [], [],
)
#board2

#let board3 = grid(
    rows: boardsize+1,
    columns: boardsize+1,
    stroke: (x,y) => if x>0 and y>0 {0.3pt},
    inset: 14pt,
    fill: (x, y) => if x>0 and y>0 and calc.rem(x+y, 2) == 1 {aqua},


    [], ..range(1, boardsize+1).map(str),
    [1], [], [], [], [], [],
    [2], [], s("E"), [], s("."), [], 
    [3], [], [], s("S"), [], s("."),
    [4], [], [], [], s("."), s("."),
    [5], [], [], [], [], s("o"),
)
#board3

