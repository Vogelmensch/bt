#import "definitions.typ": orange

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

#let t(len, left, up, diag, color) = table.cell(
    grid(
        rows: 2,
        columns: 2,
        gutter: 3pt,
        if diag [↖] else [#text(color)[↖]],
        if up [↑] else [#text(color)[↑]],
        if left [←] else [#text(color)[←]], 
        [#len]
    ),
    fill: color
)

#let e = t("", false, false, false, white)

= Needleman-Wunsch <needleman-wunsch>

Say you are given two distinct strings of DNA originating from two different species, and you want to find out in which way those two species are related to each other. Maybe they share a common ancestor, or one species originated from the other. Maybe they are far apart on the evolutionary tree, despite sharing similar features. To answer this and similar questions, we want to find out how one DNA string can be transformed into the other, using as few operations as possible. In bioinformatics, this problem is known as the _sequence alignment problem_. In 1969, Saul B. Needleman and Christian D. Wunsch proposed a dynamic programming algorithm to solve this problem, which is now known as the _Needleman-Wunsch algorithm_ @needleman.


== How DNA changes

A DNA sequence is a sequence of nucleotides. A nucleotide is a type of organic molecule of which four distinct flavors exist within DNA. Here, we will simply encode those types with the letters C, G, A and T. 

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

== Finding the best alignment

Similar to LCS, our approach will be to iteratively fill the dynamic programming table. At each step, we use values from previous iterations (or the base case) to calculate the best solution for all prefix-combinations of `s1` and `s2` we have sufficient information about. @needleman_table_empty shows the empty dynamic programming table we are about to fill.

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

== Query Layout
#codly-enable()

Equivalent to the layout of LCS in @letters_definition, we create macros `s1()` and `s2()` to hold the input strings, and create the `letters` table to hold all combinations of characters from those strings. Additionally, we define the scoring system using macros, see @scoring_macros.

#figure(
    caption: [Definition of exemplary scoring function using macros],
    ```sql
    CREATE MACRO match_score() AS 1;
    CREATE MACRO mismatch_score() AS -1;
    CREATE MACRO indel_score() AS -1;
    ``` 
) <scoring_macros>



Also equivalent to LCS is the approach of filling the dynamic programming table not with partial solutions, but with integer-valued scores and boolean-valued directions instead. After the table has been filled, we will backtrack the entries to construct the actual solutions.

We thus use the following columns for our CTes. `xidx` and `yidx` identify each row as a table cell with a distinct position. 

#figure(
    caption: [Layout of Needleman-Wunsch for classic (left) and using-key (right)],
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


== Base case

The base case is equivalent for both variants. It is divided into three sections, marked in @needleman_base_case using SQL comments. Case ❶ takes care of the base case shown in @base_case_function. Cases ❷ and ❸ define all the cases occuring within @needleman_recurrence_relation in which either $a = epsilon$ or $b = epsilon$. Intuitively, in those cases, one word has already been written down completely, while the other has still letters left. Those letters are then all being paired with indels. See TODO for backtracking.

#figure(
    caption: [Base case for Needleman-Wunsch],
    ```sql
    -- ❶ a = b = ε
    SELECT 
        xidx, yidx,
        xidx * indel_score(),
        false, false, false
    FROM letters
    WHERE xidx = 0 and yidx = 0

    UNION 

    -- ❷ a = ε, b ≠ ε
    SELECT 
        xidx, yidx,
        yidx * indel_score(),
        false, true, false
    FROM letters
    WHERE xidx = 0 and yidx > 0

    UNION

    -- ❸ a ≠ ε, b = ε
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


== Recursive step: using-key

Again, we examine using-key first and address classic later, because using-key will be contained within classic.

...

#figure(
    caption: [Recursive step of Needleman-Wunsch for using-key],
    ```sql
    WITH scores_intermediate (
        xidx, yidx, 
        lft, up, diag
    ) AS (
        SELECT 
            ltrs.xidx, ltrs.yidx,
            lft.score + indel_score(),
            up.score + indel_score(),
            CASE 
                WHEN ltrs.xsym = ltrs.ysym         
                THEN diag.score + match_score()
                ELSE diag.score + mismatch_score()
            END
        FROM 
            letters AS ltrs                                 JOIN
            recurring.needleman AS diag ON diag.xidx = ltrs.xidx-1 and 
                                           diag.yidx = ltrs.yidx-1      JOIN
            recurring.needleman AS lft  ON lft.xidx = ltrs.xidx-1 and 
                                           lft.yidx = ltrs.yidx         JOIN
            recurring.needleman AS up   ON up.xidx = ltrs.xidx and 
                                           up.yidx = ltrs.yidx-1        LEFT OUTER JOIN
            recurring.needleman AS this ON this.xidx = ltrs.xidx and 
                                           this.yidx = ltrs.yidx
        WHERE this.score IS NULL 
    ),
    scores (
        xidx, yidx, 
        lft, up, diag, max
    ) AS (
        SELECT 
            xidx, yidx,
            lft, up, diag, greatest(lft, up, diag)
        FROM scores_intermediate
    )

    SELECT 
        xidx, yidx,
        max,
        lft = max, up = max, diag = max
    FROM scores
    ```
) <needleman_recursive_using_key>


#figure(
    caption: [],
    grid(
        columns: 2,
        gutter: 20pt,

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, lime), e, e, e,
            [*A*], t(-2, false, true, false, white), e, e, e, e,
            [*T*], t(-3, false, true, false, white), e, e, e, e,
            [*G*], t(-4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, lime), e, e,
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, lime), e, e, e,
            [*T*], t(-3, false, true, false, white), e, e, e, e,
            [*G*], t(-4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, lime), e,
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, lime), e, e,
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, lime), e, e, e,
            [*G*], t(-4, false, true, false, white), e, e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, lime),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, lime), e,
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, lime), e, e,
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, lime), e, e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, white), t(0, false, false, true, lime),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, white), t(-1, false, false, true, lime), e,
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, lime), e, e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, white), t(-1, false, false, true, white), t(-1, false, true, false, lime),
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, white), t(0, false, false, true, lime), e,
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, white), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, white), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, white), t(-1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, white), t(-1, false, false, true, white), t(-1, false, true, false, white),
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, white), t(0, false, false, true, white), t(-1, true, false, false, lime),
        ),

        table(
            rows: 6,
            columns: 6,
            stroke: 0.5pt,
            [], table.vline(stroke: 1pt), [*$epsilon$*], [*G*], [*A*], [*G*], [*A*],
            table.hline(stroke: 1pt),
            [*$epsilon$*], t(0, false, false, false, orange), t(-1, true, false, false, white), t(-2, true, false, false, white), t(-3, true, false, false, white), t(-4, true, false, false, white),
            [*A*], t(-1, false, true, false, white), t(-1, false, false, true, orange), t(0, false, false, true, white), t(-1, true, false, false, white), t(-2, true, false, true, white),
            [*A*], t(-2, false, true, false, white), t(-2, false, true, true, white), t(0, false, false, true, orange), t(-1, true, false, true, white), t(0, false, false, true, white),
            [*T*], t(-3, false, true, false, white), t(-3, false, true, true, white), t(-1, false, true, false, orange), t(-1, false, false, true, white), t(-1, false, true, false, white),
            [*G*], t(-4, false, true, false, white), t(-2, false, false, true, white), t(-2, false, true, false, white), t(0, false, false, true, orange), t(-1, true, false, false, orange),
        ),
    )
) <needleman_example>

== Recursive step: classic

#figure(
    caption: [Recursive step of needleman for classic],
    ```sql
    <using-key recursive step>

    UNION 

    FROM needleman
    WHERE (SELECT count(*) FROM needleman) < (SELECT count(*) FROM letters)
    ```
) <needleman_recursive_classic>