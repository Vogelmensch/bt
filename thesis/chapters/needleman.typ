#import "definitions.typ": orange, t, e

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  languages: (
    sql: (name: "SQL", icon: "🦆", )
  )
)
#codly-enable()

#set math.equation(numbering: "(1)")

== Needleman-Wunsch <needleman-wunsch>

Say you are given two distinct strings of DNA originating from two different species, and you want to find out in which way those two species are related to each other. Maybe they share a common ancestor, or one species originated from the other. Maybe they are far apart on the evolutionary tree, despite sharing similar features. To answer this and similar questions, we want to find out how one DNA string can be transformed into the other, using as few operations as possible. In bioinformatics, this problem is known as the _sequence alignment problem_. In 1969, Saul B. Needleman and Christian D. Wunsch proposed a dynamic programming algorithm to solve this problem, which is now known as the _Needleman-Wunsch algorithm_ @needleman.


=== How DNA changes

A DNA sequence is a sequence of nucleotides. A nucleotide is a type of organic molecule of which four distinct flavors exist within DNA. Here, we encode those types with the letters C, G, A and T. 

@changing_dna shows the three operations that can be used to convert one DNA sequence into another. First, a nucleotide within the sequence can change its flavor. We call this substitution. Secondly, a nucleotide can be removed. We call this deletion. Lastly, a new nucleotide can be inserted. 

#figure(
    caption: [Example DNA sequence being changed to a different one by substitution (left), deletion (middle) and insertion (right).],
    grid(
        columns: 3,
        rows: 3,
        gutter: 15pt,
        [`GTA`], [`GTA`], [`GTA`],
        [`↓`], [`↓`], [`↓`],
        [`GTC`], [`GA`], [`GTGA`]
    )
) <changing_dna>

There are infinitely many ways to combine these three operations in order to turn one given DNA sequence into the other. We are interested in the combination that needs the minimal amount of operations. In order to find this combination, we need a way of displaying and rating the changes made between two sequences. 
We compare two given sequences by writing them one above the other. Equal letters are written directly on top of each other; they mark unchanged characters. To mark characters that were changed - i.e. inserted or deleted -  we insert a special symbol called the "indel", denoted with the sign "`-`". @aligning_dna continues the previous example and aligns each sequence pair in this way.

#codly-disable()
#figure(
    caption: [Aligning the sequences from @changing_dna. The left alignment shows the substitution of `A` to `C`. The middle alignment shows the deletion of `T`, while the right alignment shows the insertion of `G`.],
    grid(
        columns: 3,
        rows: 1,
        gutter: 15pt,
        [```
        GTA 
        GTC
        ```], 
        [```
        GTA
        G-A
        ```], 
        [```
        GT-A
        GTGA
        ```]
    )
) <aligning_dna>


To rate an alignment, we assign scores to each of its pairs of letters, based on a scoring function. There are many different scoring functions to choose from; we choose the following, very basic one: let $(a, b)$ be a pair of letters. Then:

$
  "score"(a, b) = cases(
    +1 &"if" a = b &"match",
    -1 &"if" a != b &"mismatch",
    -1 &"if" a = "\"-\"" "or" b = "\"-\"" &"indel"
  )
$ <scoring_function>

The scores for all letter-pairs in an alignment are then added to yield the total value of the alignment. 

To illustrate this with another example, let us consider the sequences `s1 = GAGA` and `s2 = AATG`. @alignment_example shows four different way to align `s1` and `s2`, and it shows the application of the scoring function for each of them. The highest value is reached by the rightmost example, which also turns out to be the overall best alignment, i.e., the one resulting in the highest value.

#figure(
    caption: [Four different ways of aligning the sequences `GAGA` and `AATG`, and their respective values. For each pair of letters, `+` denotes a score of $+1$ and `-` denotes a score of $-1$.],
    grid(
        columns: 4,
        gutter:20pt,
        [```
        GAGA
        AATG
        -+-- = -2
        ```],
        [```
        GAGA-
        -AATG
        -+--- = -3
        ```],
        [```
        GA-GA
        -AATG
        -+--- = -3
        ```],
        [```
        GA-GA
        AATG-
        -+-+- = -1
        ```],
    )
) <alignment_example>

=== Finding the best alignment

Similar to LCS, our approach is to iteratively fill the dynamic programming table. At each step, we use values from previous iterations (or the base case) to calculate the best solution for all prefix-combinations of `s1` and `s2` we have sufficient information about. @needleman_table_empty shows the empty dynamic programming table we are about to fill.

#figure(
    caption: [Empty dynamic programming table],
    table(
        rows: 6,
        columns: 6,
        stroke: 0.5pt,
        [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
        table.hline(stroke: 1pt),
        [*$epsilon$*], [], [], [], [], [],
        [*A*], [], [], [], [], [],
        [*A*], [], [], [], [], [],
        [*T*], [], [], [], [], [],
        [*G*], [], [], [], [], [],
    ),
) <needleman_table_empty>

We want to find a recurrence relation that we can use to fill the table. 
Let $Sigma$ be an alphabet and $Sigma^*$ the set of all words over $Sigma$. Let $a, b in Sigma$ and $s_1, s_2 in Sigma*$, and $+$ the concatenation operator.

#let score = "score"
#let value = "value"

The base case is defined by 
$
  value(s_1+a, s_2+b) &= 0, "if" a = b = epsilon\
  <=> value(epsilon, epsilon) &= 0
$ <base_case_function>

Keep in mind that we are examining the last letter of the respective string. Thus, if $a = epsilon$, it follows that $s_1 = epsilon$, because if $s_1 != epsilon$, a last letter $a != epsilon$ would also exist.

In @needleman_table_empty, we fill this value into the cell at the top-leftmost corner. The table is then filled iteratively using 

$
  value(s_1 + a, s_2 + b) = max cases(
    value(s_1 + a, &s_2 &) &+ score("-", b),
    value(s_1, &s_2 + b &) &+ score(a, "-"),
    value(s_1, &s_2 &) &+ score(a, b)
  ),
$ <needleman_recurrence_relation>

where, because of @base_case_function, we can assume that either $a != epsilon$ or $b != epsilon$. 

@needleman_recurrence_relation simply applies all three cases of @scoring_function, and then chooses the case(s) with the highest overall value by applying itself recursively to remaining strings. The relation is guaranteed to terminate because the strings always get smaller.

=== Query Layout

#codly-enable()

Equivalent to the layout of LCS in @letters_definition, we create macros `s1()` and `s2()` to hold the input strings, and create the `letters` table to hold all combinations of characters from those strings. Additionally, we define the scoring system using macros `match_score()`, `mismatch_score()` and `indel_score()`.

Also equivalent to LCS is the approach of filling the dynamic programming table not with partial solutions, but with integer-valued scores and boolean-valued directions instead. After the table has been filled, we backtrack the entries to construct the actual solutions.

See @needleman_layout for the layout of the queries. `xidx` and `yidx` identify each row as a table cell with a distinct position. `val` is the value calculated for this cell, and `from_lft`, `from_up` and `from_diag` mark the respective direction for backtracking. To access the values for every cell when needed, we define `(xidx, yidx)` as key in using-key.

#figure(
    caption: [Layout of Needleman-Wunsch for classic (left) and using-key (right).],
    grid(
        columns: 2,
        gutter: 25pt,

        ```sql
        WITH RECURSIVE needleman (
            xidx, yidx,
            val,
            from_lft, from_up, from_diag
        ) AS (
            (<base case>)

            UNION ALL

            (<recursive step>)
        )
        <outer query>
        ```,

        ```sql
        WITH RECURSIVE needleman (
            xidx, yidx,
            val,
            from_lft, from_up, from_diag
        ) USING KEY (xidx, yidx) AS (
            (<base case>)

            UNION

            (<recursive step>)
        )
        <outer query>
        ```
    )
) <needleman_layout>


=== Base case

The base case is equivalent for both variants. It is divided into three sections, marked in @needleman_base_case using SQL comments. Case `(1)` takes care of the base case shown in @base_case_function. Cases `(2)` and `(3)` define all the cases occuring within @needleman_recurrence_relation in which either $a = epsilon$ or $b = epsilon$. Intuitively, in those cases, one word has already been written down completely, while the other has still letters left. These letters are then all paired with indels. 

#figure(
    caption: [Base case for Needleman-Wunsch],
    placement: auto,
    ```sql
    -- (1) a = b = ε
    SELECT 
        xidx, yidx,
        xidx * indel_score(),
        false, false, false
    FROM letters
    WHERE xidx = 0 and yidx = 0

    UNION 

    -- (2) a = ε, b ≠ ε
    SELECT 
        xidx, yidx,
        yidx * indel_score(),
        false, true, false
    FROM letters
    WHERE xidx = 0 and yidx > 0

    UNION

    -- (3) a ≠ ε, b = ε
    SELECT 
        xidx, yidx,
        xidx * indel_score(),
        true, false, false
    FROM letters
    WHERE xidx > 0 and yidx = 0
    ```
) <needleman_base_case>


@needleman_table_after_base_case shows the dynamic programming table after the base case.

#figure(
    caption: [Dynamic programming table after base case],
    table(
        rows: 6,
        columns: 6,
        stroke: 0.5pt,
        [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
        table.hline(stroke: 1pt),
        [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
        [*A*], t(-1, false, true, false, white), e, e, e, e,
        [*A*], t(-2, false, true, false, white), e, e, e, e,
        [*T*], t(-3, false, true, false, white), e, e, e, e,
        [*G*], t(-4, false, true, false, white), e, e, e, e,
    ),
) <needleman_table_after_base_case>


=== Recursive step: using-key

Again, we examine using-key first and address classic later, because using-key is contained within classic.
@needleman_recursive_using_key shows the query. It uses two CTEs: `vals_intermediate` `(1)` calculates the three values for each direction based on @needleman_recurrence_relation; out of these three values, the CTE `vals` `(2)` additionally selects the greatest, named `max`. Finally, the outer query `(3)` selects `max` and marks the direction for backtracking by comparing each of the three values with `max`. 

Let us examine the first CTE, `vals_intermediate` `(1)`, in depth. Have a look at the `FROM` clause. We select from two tables: once from `letters AS ltrs` and four times from the recurring table, `recurring.needleman`. Each `JOIN` of the recurring table corresponds to one cell in the dynamic programming table, defined by the coordinates in the respective `ON` clause, and named accordingly: `this` is an empty cell, as specified in the `WHERE` clause. `diag`, `lft` and `up` are respectively positioned diagonally, left and up to `this`. In each iteration, all cells existing in these configuration are selected. Notice that we use a `LEFT OUTER JOIN` for `this` to allow for `this.score` to be `NULL`. Also notice that `this` and `ltrs` are joined on the same coordinates; in order to select the correct values for `this`, we need to examine the corresponding coordinates.

In the `SELECT` clause, we first, take the coordinates from `ltrs`.
We then apply each case of @needleman_recurrence_relation to get all three values. The first two cases, the `indel_score` is added to the values of `lft` and `up`, respectively. In the third case, the value depends on whether `xsym` and `ysym` are equal or not, as defined in @scoring_function. We implement this with a `CASE` expression, adding the respective score to `diag.val`.

The second CTE, `vals`, selects all values from `vals_intermediate`, and the greatest of its three values, `greatest(lft, up, diag)`, as `max`.

Finally, the outer query then selects `xidx`, `yidx` and `max` from `vals`, and additionally marks the path for backtracking by comparing each of `vals_intermediate`'s three values with `max`; backtracking will then take all paths (possibly more than one) for which the corresponding value is also the highest of the three.

@needleman_example visualizes the query's execution iteration-wise. The left and upper edges of each table correspond to `letters`. The cells within the table correspond to one entry of the recurring table each. In every iteration, the green cells correspond to the recurring table entries we call `this`; they are empty when selected, their values are calculated during iteration. Notice how the green cells are always exactly those empty cells that have filled neighbors on their upper, left and diagonal sides. The resulting values are shown as numbers in the cells, and the backtracking paths are shown as arrows. We show absolute values for spacing reasons here; the recurring table for this example does not actually contain any positive values.

#figure(
    caption: [Recursive step of Needleman-Wunsch for using-key],
    ```sql
    -- (1) Calculate values based on recurrence relation
    WITH vals_intermediate (
        xidx, yidx, 
        lft, up, diag
    ) AS (
        SELECT 
            ltrs.xidx, ltrs.yidx,
            lft.val + indel_score(),
            up.val + indel_score(),
            CASE 
                WHEN ltrs.xsym = ltrs.ysym         
                THEN diag.val + match_score()
                ELSE diag.val + mismatch_score()
            END
        FROM 
            letters                             AS ltrs
            JOIN recurring.needleman            AS diag ON diag.xidx = ltrs.xidx-1 and 
                                                           diag.yidx = ltrs.yidx-1
            JOIN recurring.needleman            AS lft  ON  lft.xidx = ltrs.xidx-1 and 
                                                            lft.yidx = ltrs.yidx
            JOIN recurring.needleman            AS up   ON   up.xidx = ltrs.xidx   and 
                                                             up.yidx = ltrs.yidx-1
            LEFT OUTER JOIN recurring.needleman AS this ON this.xidx = ltrs.xidx   and
                                                           this.yidx = ltrs.yidx
        WHERE this.val IS NULL 
    ),
    -- (2) Select greatest of the three values
    vals (
        xidx, yidx, 
        lft, up, diag, max
    ) AS (
        SELECT 
            xidx, yidx,
            lft, up, diag, greatest(lft, up, diag)
        FROM vals_intermediate
    )
    -- (3) Mark path for backtracking
    SELECT 
        xidx, yidx,
        max,
        lft = max, up = max, diag = max
    FROM vals
    ```
) <needleman_recursive_using_key>


#figure(
    caption: [Dynamic programming table in various iterations, in reading order. The arrows represent the boolean flags `from_left`, `from_up` and `from_diag`. The numbers represent *negative* values. Marked in green are the elements that are being added in the respective iteration. In the last table, the final path is marked in orange.],
    grid(
        columns: 3,
        gutter: 10pt,

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, lime), e, e, e,
            [*A*], t(2, false, true, false, white), e, e, e, e,
            [*T*], t(3, false, true, false, white), e, e, e, e,
            [*G*], t(4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, lime), e, e,
            [*A*], t(2, false, true, false, white), t(2, false, true, true, lime), e, e, e,
            [*T*], t(3, false, true, false, white), e, e, e, e,
            [*G*], t(4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, lime), e,
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, lime), e, e,
            [*T*], t(3, false, true, false, white), t(3, false, true, true, lime), e, e, e,
            [*G*], t(4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, lime),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, lime), e,
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, lime), e, e,
            [*G*], t(4, false, true, false, white), t(2, false, false, true, lime), e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, white), t(0, false, false, true, lime),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, white), t(1, false, false, true, lime), e,
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, lime), e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, white), t(1, false, false, true, white), t(1, false, true, false, lime),
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, white), t(0, false, false, true, lime), e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, white), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, white), t(1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, white), t(1, false, false, true, white), t(1, false, true, false, white),
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, white), t(0, false, false, true, white), t(1, true, false, false, lime),
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, orange), t(1, true, false, false, white), t(2, true, false, false, white), t(3, true, false, false, white), t(4, true, false, false, white),
            [*A*], t(1, false, true, false, white), t(1, false, false, true, orange), t(0, false, false, true, white), t(1, true, false, false, white), t(2, true, false, true, white),
            [*A*], t(2, false, true, false, white), t(2, false, true, true, white), t(0, false, false, true, orange), t(1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(3, false, true, false, white), t(3, false, true, true, white), t(1, false, true, false, orange), t(1, false, false, true, white), t(1, false, true, false, white),
            [*G*], t(4, false, true, false, white), t(2, false, false, true, white), t(2, false, true, false, white), t(0, false, false, true, orange), t(1, true, false, false, orange),
        ),
    )
) <needleman_example>

=== Recursive step: classic

As mentioned above, classic Needleman-Wunsch contains the using-key variant. However, in classic, we cannot access the recurring table, which we repeatedly do within using-key. We thus need to manually carry all calculated values by selecting the entire table `needleman` and unionizing it with the results of each recursive step. To guarantee termination, in the `WHERE` clause, we check whether the number of elements in the working table exceeds the number of elements in `letters`, which is the natural limit.

To access those carried values, we simply replace all occurences of `recurring.needleman` in @needleman_recursive_using_key with `needleman`. The difference between the two variants then boils down to a few additional lines shown in @needleman_recursive_classic.

#figure(
    caption: [Recursive step of needleman for classic],
    ```sql
    <using-key recursive step>

    UNION 

    FROM needleman
    WHERE (SELECT count(*) FROM needleman) < (SELECT count(*) FROM letters)
    ```
) <needleman_recursive_classic>