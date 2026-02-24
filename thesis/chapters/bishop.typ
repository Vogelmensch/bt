#import "../definitions.typ": redbox

= Drunken Bishop

SSH is a network protocol that allows users to securely access remote computers over an unsecured network. It is based on the client-server-model and uses asymmetric cryptography methods for authentication. When a user accesses a server for the first time, the server sends a unique fingerprint, which is based on its public key. To ensure that the client is communicating with the correct server, and not with, say, an attacker, the client must make sure that they receive the correct fingerprint.

A fingerprint is a string of hexadecimal numbers. In practice, remembering and comparing such a string proves to be impractical. Thus, OpenSSH 5.1 introduced a method to draw an ASCII-based image from an fingerprint string, images being easier to remember and compare by humans. @fingerprint_example shows an example for a fingerprint string and its ASCII-representation. The algorithm that draws the image from the fingerprint string is called the "drunken bishop algorithm".

#figure(
  caption: "Example ssh-fingerprint as string of hexadecimal numbers (left) and as an image (right)",
  grid(
    columns: 2,
    gutter: 15pt,
    align: horizon,
    [
      `fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7`
    ],
    [
      ```
      +-----------------+
      |       .=o.  .   |
      |     . *+*. o    |
      |      =.*..o     |
      |       o + ..    |
      |        S o.     |
      |         o  .    |
      |          .  . . |
      |              o .|
      |               E.|
      +-----------------+
      ```
    ]
  )
) <fingerprint_example>


== Creating an image from a fingerprint

#let width = "width"
#let height = "height"

The rules of converting an array of hexadecimal numbers to an ASCII-image are quite simple. The basic idea is to place a bishop, the chess piece, on a two dimensional field and track its movement, which is defined by the fingerprint.

We start on an empty grid of dimensions $width times height$, where $width = 17$ and $height = 9$ for the standard implementation. We place the bishop in the middle of the board. 

In chess, the bishops can only move diagonally. The same applies to our bishop. However, at each step, our bishop can only make exactly one step in one of the four (or less, if it is at a corner) directions. Which of those directions the bishop takes in each step is being defined by the fingerprint.

@bishop_conversion shows how the fingerprint is translated and read. First, we convert the fingerprint from hexadecimal to binary representation. The resulting bytes are then read from left to right, and within each byte, the bit-pairs are read from right to left.
For one bit-pair, the bishop takes the direction matching the value in @bishop_directions. 

#figure(
  table(
    columns: 12,
    rows: 3,
    stroke: none,
    [Fingerprint], [fc], [:], [94], [:], [b0], [:], [c1], [:], [...], [:], [b7],
    [Bits], [11 11 11 00], [:], [10 01 01 00], [:], [10 11 00 00], [:], [11 00 00 01], [:], [...], [:], [10 11 01 11],
    [Step], 
  )
) <bishop_conversion>

#figure(
  caption: [],
  table(
    columns: 2,
    rows: 4,
    stroke: none,
    table.header([Bits], [Direction]),
    table.hline(stroke: 0.5pt),
    [00], [up-left],
    [01], [up-right],
    [10], [down-left],
    [11], [down-right]
  )
) <bishop_directions>


The bishop leaves a trail ... TODO

== Query start

#figure(
  caption: [],
  [
    ```sql
    CREATE OR REPLACE MACRO width() AS 17;
    CREATE OR REPLACE MACRO height() AS 9;

    CREATE OR REPLACE MACRO bitlist() AS [(1,0), ...];
    ```
  ]
) <bishop_macros>

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
          SELECT 
              (width()/2) :: INTEGER,
              (height()/2) :: INTEGER,
              
              bitlist(),
              false
              
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
          SELECT 
              (width()/2) :: INTEGER,
              (height()/2) :: INTEGER,
              1,
              bitlist(),
              false
              
          UNION

          <recursive step>
      )
      <outer query>
      ```
    ]
  )
) <bisho_base_case>

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