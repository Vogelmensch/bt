#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/touying:0.7.1": *
#import "chessboard.typ": board1, board2, board3

== SSH Fingerprints

#align(center+horizon,
  {
    show raw: set text(size: 16pt)
    grid(
      columns: 2,
      gutter: 20pt,
      [
        `7f:21:fa:08:d6:a6:47:28:a5:d0:ef:71:66:59:32:d9`
      ],

      no-codly[
        ```
        +-----------------+
        |                 |
        |                 |
        |   .     o       |
        |  . . . + E      |
        |   . + .S=. .    |
        |    o +.*o . .   |
        |     oo*+ . .    |
        |     ..+.o .     |
        |      ... .      |
        +-----------------+
        ```
      ]
    )
  }
)

== From Fingerprint to List of Directions
#{
  set text(size: 22pt)
  table(
      columns: 10,
      rows: 3,
      row-gutter: 10pt,
      stroke: none,
      align: (x, y) => if y > 0 and x > 0 {left} else {center},
      [Fingerprint], [7f], [:], [21], [:], [fa] , [:], [...], [:], [d9],
      [Bits], [01 11 11 11], [:], [00 10 00 01], [:], [11 11 10 10], [:], [...], [:], [11 01 10 01],
  )
}

== From Fingerprint to List of Directions

#{
  set text(size: 22pt)
  table(
      columns: 10,
      rows: 3,
      row-gutter: 10pt,
      stroke: none,
      align: (x, y) => if y > 0 and x > 0 {left} else {center},
      [Fingerprint], [7f], [:], [21], [:], [fa] , [:], [...], [:], [d9],
      [Bits], [01 11 11 11], [:], [00 10 00 01], [:], [11 11 10 10], [:], [...], [:], [11 01 10 01],
  )
}

- Read bytes from left to\ right
- Within byte, Read bit-\ pairs from right to left 

== From Fingerprint to List of Directions

#{
  set text(size: 22pt)
  table(
      columns: 10,
      rows: 3,
      row-gutter: 10pt,
      stroke: none,
      align: (x, y) => if y > 0 and x > 0 {left} else {center},
      [Fingerprint], [7f], [:], [21], [:], [fa] , [:], [...], [:], [d9],
      [Bits], [01 11 11 11], [:], [00 10 00 01], [:], [11 11 10 10], [:], [...], [:], [11 01 10 01],
  )
}

#grid(
  columns: 3,
  column-gutter: 10pt,
  [
    - Read bytes from left to right
    - Within byte, Read bit-pairs from right to left 
  ],
  table(
    columns: 3,
    stroke: none,
    align: center,
    row-gutter: 5pt,
    table.header([Step], [Bits], [Direction]),
    table.hline(),
    [1], [11], uncover(2, [↘]),
    [2], [11], uncover(2, [↘]),
    [3], [11], uncover(2, [↘]),
    [4], [01], uncover(2, [↗]),
    [5], [01], uncover(2, [↗]),
  ),
  uncover(2,
    table(
      columns: 2,
      rows: 4,
      align: center,
      row-gutter: 5pt,
      stroke: none,
      table.header([Bits], [Direction]),
      table.hline(),
      [00], [↖],
      [01], [↗],
      [10], [↙],
      [11], [↘]
    )
  )
)

== Bishop Movement

#align(center,
  grid(
      columns: 2,
      column-gutter: 2cm,
      board1, board2,
      )
)

== Bishop's Footprint

#grid(
  columns: (33%, 33%, 33%),
  align: center+horizon,
  table(
      columns: 3,
      stroke: none,
      align: center,
      row-gutter: 5pt,
      table.header([Step], [Bits], [Direction]),
      table.hline(),
      [1], [11], [↘],
      [2], [11], [↘],
      [3], [11], [↘],
      [4], [01], [↗],
      [5], [01], [↗],
      [6], [00], [↖],
      [7], [10], [↙],
      [8], [00], [↖]
  ),
  board3,
  {
  show raw: set text(size: 16pt)
  no-codly[
    ```
    +-----+
    |     |
    | E . |
    |  S .|
    |   ..|
    |    o|
    +-----+

    ```
  ]
  }
)


== Drunken Bishop: Layout

#grid(
    columns: 2,
    gutter: 15pt,
    [
      ```sql
      WITH RECURSIVE bishop (

          x,          
          y, 

          bitlist,    
          is_end      
      ) AS (
          <base case>
              
          UNION ALL

          <recursive step>
      )
      <outer query>

      ```
    ],
    [
      ```sql
      WITH RECURSIVE bishop (
          idx,
          x,          
          y, 
          sym_id,     

          is_end      
      ) USING KEY (x, y) AS (
          <base case>
              
          UNION

          (<recursive step>)
      )
      <outer query>
      ```
    ]
  )

  == Drunken Bishop: Recursive Step (classic)

#grid(
  columns: 2,
  column-gutter: .5cm,
  ```sql
    SELECT
        CASE 
            WHEN bitlist[1][2] == '0' 
            THEN greatest(0, x-1)       
            ELSE least(width()-1, x+1)
        END,
        CASE 
            WHEN bitlist[1][1] == '0' 
            THEN greatest(0, y-1)       
            ELSE least(height()-1, y+1)
        END,
        array_pop_front(bitlist),
        length(bitlist) = 1             
    FROM bishop
    WHERE length(bitlist) > 0
    ```,
    table(
      columns: 2,
      rows: 4,
      align: center,
      row-gutter: 5pt,
      stroke: none,
      table.header([Bits], [Direction]),
      table.hline(),
      [00], [↖],
      [01], [↗],
      [10], [↙],
      [11], [↘]
    )
)

== Drunken Bishop: Recursive Step (USING KEY)

```sql
    WITH new(idx, x, y, is_end) AS (
        <classic recursive step>
    )
    SELECT 
        new.idx,
        new.x,
        new.y,
        coalesce(field_to.sym_id + 1, 1),
        new.is_end
    FROM 
        new 
        LEFT OUTER JOIN recurring.bishop AS field_to ON field_to.x = new.x AND 
                                                        field_to.y = new.y
    ```

== Drunken Bishop: Measurements (Methods)

- generated random arrays of hex-numbers
- length $l in {200, 400, ..., 5000}$
- ten arrays per length

== Drunken Bishop: Measurements (Results)

#grid(
    columns: 2,
    image("../thesis/chapters/images/bishop_0315_all_time.svg"),
    image("../thesis/chapters/images/bishop_0315_all_memory.svg")
)