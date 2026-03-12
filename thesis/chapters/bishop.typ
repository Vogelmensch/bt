#import "definitions.typ": redbox

= Drunken Bishop

SSH is a network protocol that allows users to securely access remote computers over an unsecured network. It is based on the client-server-model and uses asymmetric cryptography methods for authentication. When a user accesses a server for the first time, the server sends a unique fingerprint, which is based on its public key. To ensure that the client is communicating with the correct server, and not with, say, an attacker, the client must make sure that they receive the correct fingerprint @ssh.

A fingerprint is a string of hexadecimal numbers, which proves to be impractical to remember and compare. Thus, OpenSSH 5.1 introduced a method to draw an ASCII-based image from a fingerprint string, images being easier to remember and compare by humans. @fingerprint_example shows an example for a fingerprint string and its ASCII-representation. The algorithm that draws the image from the fingerprint string is called the "drunken bishop algorithm".

#figure(
  caption: "Example ssh-fingerprint as string of hexadecimal numbers (left) and as an image (right)",
  grid(
    columns: 2,
    gutter: 15pt,
    align: horizon,
    [
      `7f:21:fa:08:d6:a6:47:28:a5:d0:ef:71:66:59:32:d9`
    ],
    [
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
) <fingerprint_example>


== Creating an image from a fingerprint

#let width = "width"
#let height = "height"

The rules of converting an array of hexadecimal numbers to an ASCII-image are straightforward. The basic idea is to place a bishop, the chess piece, on a two dimensional field and track its movement, which is defined by the fingerprint.

We start on an empty grid of dimensions $width times height$, where $width = 17$ and $height = 9$ for the standard implementation. We place the bishop in the middle of the board. 

In chess, bishops can only move diagonally. The same applies to our bishop. However, at each step, our bishop can only make exactly one step in one of the four (or less, if it is at a corner) directions. The fingerprint defines Which of these directions the bishop takes in each step.

@bishop_conversion shows how the fingerprint is translated and read. First, we convert the fingerprint from hexadecimal to binary representation. The resulting bytes are then read from left to right, and within each byte, the bit-pairs are read from right to left.
For one bit-pair, the bishop takes the direction matching the value in @bishop_directions. The bishop cannot move beyond the edges of the board. When given a direction that would lead beyond an edge, the bishop must move parallel to the edge. Becaues of this, the bishop is able to visit every square of the board, in contrast to the bishops in chess.

#figure(
  caption: [Order of bit-processing],
  table(
    columns: 12,
    rows: 3,
    stroke: none,
    align: (x, y) => if y > 0 and x > 0 {left} else {center},
    [Fingerprint], [7f], [:], [21], [:], [fa], [:], [08], [:], [...], [:], [d9],
    [Bits], [01 11 11 11], [:], [00 10 00 01], [:], [11 11 10 10], [:], [00 00 10 00], [:], [...], [:], [11 01 10 01],
    [Step], [04 03 02 01], [], [08 07 06 05], [], [12 11 10 09], [], [16 15 14 13], [], [...], [], [64 63 62 61]
  )
) <bishop_conversion>

#figure(
  caption: [Direction the bishop takes for each bit-pair],
  table(
    columns: 2,
    rows: 4,
    stroke: none,
    table.header([Bits], [Direction]),
    table.hline(stroke: 0.5pt),
    [00], [↖],
    [01], [↗],
    [10], [↙],
    [11], [↘]
  )
) <bishop_directions>


The bishop leaves a footprint on every square they visit. When visiting the same square multiple times, the footprint gets "deeper" for each visit. This creates a unique trail for the path the bishop takes. To represent the "depth" of the footprints, we work through the symbols shown in @footprints. Additionally, we mark the start- and end-positions of the bishop with the letters S and E, respectively.

#figure(
  caption: [ASCII symbols to represent the bishop's trail],
  table(
    columns: 16,
    rows: 2,
    stroke: 0.5pt,
    [Step], ..range(15).map(str),
    [Symbol], [], [.], [o], [+], [=], [\*], [B], [O], [X], [@], [%], [&], [\#], [/], [^]
  )
) <footprints>

== Query layout

For simplicity, we assume the conversion of the fingerprint from a string of hexadecimal numbers to an array of binary numbers, from here on called the bitlist has already taken place. 
We define macros to hold the bitlist and the image dimensions, see @bishop_macros. 

#figure(
  caption: [Macros for drunken bishop. The bitlist is represented as an array of tuples. TODO: in sql, I think they are called "list" and "struct".],
  [
    ```sql
    CREATE OR REPLACE MACRO width() AS 17;
    CREATE OR REPLACE MACRO height() AS 9;

    CREATE OR REPLACE MACRO bitlist() AS [(1,0), ...];
    ```
  ]
) <bishop_macros>


@bishop_layout shows the layout for the two CTE variants. In both variants, the table `bishop` has columns for the coordinates of the board, `x` and `y`. Both also store the `bitlist`, which 

#figure(
  caption: [Base case of drunken bishop for classic (left) and using-key (right)],
  grid(
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
          x,          
          y, 
          sym_id,     
          bitlist,    
          is_end      
      ) USING KEY (x, y) AS (
          <base case>
              
          UNION

          <recursive step>
      )
      <outer query>
      ```
    ]
  )
) <bishop_layout>

== Base case

#figure(
  caption: [Base case of drunken bishop for classic (left) and using-key (right)],
  grid(
    columns: 2,
    gutter: 15pt,
    [
      ```sql
      SELECT 
        (width()/2) :: INTEGER,
        (height()/2) :: INTEGER,
        
        bitlist(),
        false
      ```
    ],
    [
      ```sql
      SELECT
        (width()/2) :: INTEGER,
        (height()/2) :: INTEGER,
        1,
        bitlist(),
        false
      ```
    ]
  )
) <bishop_base_case>

== Outer queries

Before we look at the recursive step, let us look at the outer queries to get a feeling for the key difference between the queries. In contrast to the other algorithms, the outer queries for drunken bishops are quite concise (@bishop_outer_queries).

#figure(
  caption: [Outer query of drunken bishop for classic (left) and using-key (right)],
  grid(
    columns: 2,
    gutter: 15pt,
    [
      ```sql
      SELECT x, y, count(*), bool_or(is_end)
      FROM bishop
      GROUP BY x, y;
      ```
    ],
    [
      ```sql
      SELECT x, y, sym_id, is_end
      FROM bishop;  
      ```
    ]
  )
) <bishop_outer_queries>

TODO: Explain further.

== Recursive step: classic

#figure(
  caption: [Recursive step of drunken bishop for classic],
  [
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
    ```
  ]
)


== Recursive step: using-key

#figure(
  caption: [Recursive step of drunken bishop for using-key],
  [
    ```sql
    WITH new(x, y, bitlist, is_end) AS (
        <classic recursive step>
    )
    SELECT 
        new.x,
        new.y,
        coalesce(field_to.sym_id + 1, 1),
        new.bitlist,
        new.is_end
    FROM 
        new 
        LEFT OUTER JOIN recurring.bishop AS field_to
                        ON field_to.x = new.x AND field_to.y = new.y

    ```
  ]
)

#bibliography("../references.bib")