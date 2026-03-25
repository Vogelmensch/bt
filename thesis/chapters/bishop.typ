#import "definitions.typ": redbox
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "chessboard.typ": board1, board2, board3
#show: codly-init.with()
#codly(
  languages: (
    sql: (name: "SQL", icon: emoji.duck)
  )
)

#set heading(numbering: "1.1")

== Drunken Bishop <drunken-bishop>

SSH is a network protocol that allows users to securely access remote computers over an unsecured network. It is based on the client-server-model and uses asymmetric cryptography methods for authentication. When a user accesses a server for the first time, the server sends a unique fingerprint, which is based on its public key. To ensure that the client is communicating with the correct server, and not with, say, an attacker, the client must make sure that they receive the correct fingerprint @ssh.

A fingerprint is a string of hexadecimal numbers, which proves to be impractical to remember and compare. Thus, OpenSSH 5.1 introduced a method to draw an ASCII-based image from a fingerprint string, images being easier to remember and compare by humans. @fingerprint_example shows an example for a fingerprint string and its ASCII-representation. The algorithm that draws the image from the fingerprint string is known as the _drunken bishop algorithm_.

#figure(
  caption: "Example ssh-fingerprint as string of hexadecimal numbers (left) and as an image (right)",
  grid(
    columns: 2,
    gutter: 15pt,
    align: horizon,
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
) <fingerprint_example>


=== Creating an image from a fingerprint

#let width = "width"
#let height = "height"

The rules of converting a string of hexadecimal numbers to an ASCII-image are straightforward. The basic idea is to place a bishop, the chess piece, on a two dimensional board and track its movement, which is defined by the fingerprint.

At the start, our board is an empty grid of dimensions $width times height$, where $width = 17$ and $height = 9$ for the standard implementation. We place the bishop in the middle of this grid.

In chess, bishops can only move diagonally. The same applies to our bishop. However, at each step, our bishop can only make exactly one step in one of the four directions, in contrast to the chess piece that can take arbitrarily many steps. For our bishop, the fingerprint defines which of the four directions to take. The bishop cannot move beyond the edges of the board. When given a direction that would lead beyond an edge, the bishop must move parallel to the edge. Becaues of this, the bishop is able to visit every square of the board, in contrast to the chess piece. @chessboards illustrates the bishop's movement possibilities.

@bishop_conversion shows how the fingerprint is translated and read. First, we convert the fingerprint from hexadecimal to binary representation. The resulting bytes are then read from left to right, and within each byte, the bit-pairs are read from right to left.
For one bit-pair, the bishop takes the direction matching the value in @bishop_directions. 

#figure(
  caption: [Order of bit-processing. The first and second row show the fingerprint in hexadecimal- and bit-representation respectively; the third row shows the processing order of the bit-pairs.],
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


The bishop leaves a footprint on every square it visits. When visiting the same square multiple times, the footprint gets "deeper" for each visit. This creates a unique trail for the path the bishop takes. To represent the "depth" of the footprints, we work through the symbols shown in @footprints. Additionally, we mark the start- and end-positions of the bishop with the letters S and E, respectively. @chessboards shows the resulting path after reading `7f:21` as input.

#figure(
  caption: [ASCII symbols to represent the bishop's trail. We count the number of visits for each field of the board and visualize it with the respective symbol.],
  table(
    columns: 16,
    rows: 2,
    stroke: 0.5pt,
    [Number of visits], ..range(15).map(str),
    [Symbol], [], [.], [o], [+], [=], [\*], [B], [O], [X], [@], [%], [&], [\#], [/], [^]
  )
) <footprints>

#figure(
  caption: [Small example boards. Marked on the left and middle board are the positions the bishop can go to on the next move. Notice how the bishop may be restrictred to move parallel to the border on the middle board. The right board shows the footprint after reading the fingerprint `7f:21`.],
  grid(
    columns: 3,
    board1, board2, board3
  )
) <chessboards>

=== Query layout <bishop_chapter_layout>

We implemented two different approaches to represent the bit-pairs in SQL, shown in @bitlist_representations. For the first approach, we create a list of structs, each of which holds two bits. In each iteration, we read the first element of this so-called _bitlist_ to get the bishop's direction for this step. The tail of the bitlist then gets handed to the next iteration while the head gets discarded using `array_pop_front(bitlist)`.
For the second approach, we represent the bit-pairs using a table `bits`, each row of which represents the bishop's direction for step `idx`. In each iteration, we read the row corresponding to the current `idx` and then increase `idx` for the next iteration.

It turns out that classic performs reasonable well under both strategies, the approach using an SQL list being more performant than using a table. However, for using-key, using a table for the bitlist is crucial. For the SQL list representation, runtime increases quadratically and quickly becomes uncomparable to the other strategies. @measure_bishop looks into this in depth.

#figure(
  caption: [Representations for bit-pairs using a list (left) and a table (right).],
  grid(
    columns: 2,
    gutter: 15pt,
    ```sql
    CREATE MACRO bitlist() AS [(1,0), (1, 1), ...];
    ```,

    ```sql
    CREATE TABLE bits (
      idx INTEGER,
      y INTEGER,
      x INTEGER
    );

    INSERT INTO bits VALUES 
      (1, 0),
      (1, 1),
      ...;
    ```
  )
) <bitlist_representations>

We represent the image dimensions with macros `width()` and `height()`. The layout for the two CTE variants is shown in @bishop_layout. Both CTEs use columns `x` and `y` to represent the board, and the boolean-valued `is_end` to mark the bishop's final position. Additionally, classic hands down the entire shrinking `bitlist` in every iteration, while using-key stores the iteration's index `idx` to access the appropriate bits for each iteration, as well as the id of the current symbol, `sym_id` (the "depth" of the footprint).

#figure(
  caption: [Layout of drunken bishop for classic (left) and using-key (right).],
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
) <bishop_layout>

=== Base case

@bishop_base_case shows the base cases. In both variants, the bishop starts in the center of the board, defining the initial values for `x` and `y`. Also, the start position may not be the end position, defining `false` to be the initial value for `is_end`. Additionally, for classic, we start with the entire `bitlist()`. For using-key, we start with the `idx` of the first element in `bits`, which is `0`, as well as a value of `1` for `sym_id`, as the bishop has now stepped exactly once on the center field.

#figure(
  caption: [Base case of drunken bishop for classic (left) and using-key (right).],
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
        0,
        (width()/2) :: INTEGER,
        (height()/2) :: INTEGER,
        1,

        false
      ```
    ]
  )
) <bishop_base_case>

=== Outer queries

Before we look at the recursive step, let us examine the outer queries in @bishop_outer_queries to get a feeling for the key difference between the CTE variants. In contrast to the other algorithms, the outer queries for drunken bishops are quite concise.

The overall goal of the queries is to count the number of times the bishop has stood on each field on the board. In using-key, we store this number in the column `sym_id` of the recurring table and increase it with every step. We can thus simply select the final values for all fields in the outer query. In classic, we do not store any such counter during the iteration. Instead, we simply let the bishop walk and, as is the nature of classic recursive CTEs, store every one of its steps in the union table. Only at the end we count the number of times the bishop has been on each field, using a simple `count(*)` on the union table. 

#figure(
  caption: [Outer query of drunken bishop for classic (left) and using-key (right).],
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

=== Recursive step: classic <bishop_classic_chapter>

With the exception of the different approaches to handling the bitlist, the classic variant of drunken bishop is contained within the using-key variant. We thus start with the former.

The recursive step, shown in @bishop_rec_classic, implements the movement rules from @bishop_directions using `CASE` expressions to update `x` and `y`. The `greatest` and `least` functions within the `CASE` expressions assure that the bishop does not move beyond the boards borders. The `bitlist` is being traversed by selecting its tail for the next iteration (@bishop_rec_classic:12), which is why we always select its first element to get the current bits in @bishop_rec_classic:3 and @bishop_rec_classic:8. A field is the final field if and only if `length(bitlist) = 1`. We iterate until the bitlist is empty (@bishop_rec_classic:15).


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
) <bishop_rec_classic>


=== Recursive step: using-key <bishop_using-key_chapter>

The recursive step of the using-key variant is shown in @bishop_rec_using_key. It is itself a CTE named `new` that calculates most of its values in the inner query, similarly to classic. However, in order to increase `sym_id` in-place, we need to access the recurring table at the correct coordinates (@bishop_rec_using_key:25) and either increase the respective value by one, or set the value to `1` if the current field has not been visited before (@bishop_rec_using_key:21). See @rec_step_using_key_chapter for an explanation of the `coalesce` function.

The inner query differs from classic because of the different bitlist representation. As explained in @bishop_chapter_layout, using-key uses the `bits` table for efficiency reasons. We thus access the current bits by `JOIN`ing the table at the current `idx`, @bishop_rec_using_key:15, and simply accessing it in the `CASE` expressions. The `CASE` expressions themselves are then equivalent to the ones in classic. Furthermore, we increase `bishop.idx` by one to access the next bit-pair in the next iteration, and mark a field as final if and only if the maximal `idx` has been reached (@bishop_rec_using_key:14).

#figure(
  caption: [Recursive step of drunken bishop for using-key],
  [
    ```sql
    WITH new(idx, x, y, is_end) AS (
        SELECT 
            bishop.idx + 1,
            CASE 
                WHEN bits.x = 0
                THEN greatest(0, bishop.x-1)
                ELSE least(width()-1, bishop.x+1)
            END,
            CASE 
                WHEN bits.y = 0
                THEN greatest(0, bishop.y-1)
                ELSE least(height()-1, bishop.y+1)
            END,
            bishop.idx = (SELECT max(idx) FROM bits)
        FROM bishop JOIN bits ON bishop.idx = bits.idx
    )
    SELECT 
        new.idx,
        new.x,
        new.y,
        coalesce(field_to.sym_id + 1, 1),
        new.is_end
    FROM 
        new 
        LEFT OUTER JOIN recurring.bishop AS field_to ON field_to.x = new.x and 
                                                        field_to.y = new.y

    ```
  ]
) <bishop_rec_using_key>