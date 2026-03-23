#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  languages: (
    sql: (name: "SQL", icon: emoji.duck, )
  )
)

#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")

#import "rec_ctes_img.typ" as graphs

#let colgut = 15pt
#let rowgut = 10pt
#let gap = 15pt

= How to loop in SQL <basics>

== CTEs: Binding intermediate results

As queries get more complex, the good query author wants to keep their code well organized. Using too many subqueries often result in hard-to-read code. What if SQL had a way to define intermediate queries beforehand and bind their result tables to names, similar to variables in imperative programming languages? 

SQLs way of doing this is called the *Common Table Expression* (CTE). The general outline is shown in @cte_general, together with the example of calculating $(1+1) dot 2$. A CTE is defined via the `WITH` clause, followed by the cte name, followed by an arbitrarily large list of column names. The inner query is evaluated before the outer query, and its result is stored into a table named `cte_name`. This table has the columns specified in the CTE definition; their data types are derived from the inner query. The outer query can then reference this table. In the example, we implicitly create the table `one_plus_one` with one column named `x`. The inner query, `SELECT 1+1`, defines the instance of `one_plus_one` to be a single row with value `2` and, derived from the value, the data type of `x` to be `INTEGER`. In the outer query, we can now reference `one_plus_one` and by selecting its column `x` to yield the CTEs final result, `4`.

#figure(
  caption: [General outline of CTEs (left) and example (right).],
  gap: gap,
  grid(
    columns: 2,
    rows: 2,
    gutter: 5pt,
    [
      ```sql
      WITH cte_name(col1, col2, ..., coln) AS (
        <inner query>
      )
      <outer query>
      ```
    ],
    [
      ```sql
      WITH one_plus_one(x) AS (
          SELECT 1+1
      )
      SELECT x * 2
      FROM one_plus_one;
      ```
    ]
  )
) <cte_general>


== WITH RECURSIVE: CTEs referencing themselves <with_recursive>

In order for SQL to become turing complete, some kind of iteration mechanism had to be added to the language's standard. Together with CTEs themselves, SQL:1999 introduced _recursive CTEs_, which expand the general CTE concept by allowing self-reference within the inner query. 

See @cte_recursive for the general layout and an example. A recursive CTE is defined by the keyword `WITH RECURSIVE`, followed by the table name and the list of columns, just as in @cte_general. In contrast to @cte_general however, the inner query is divided into two parts: the base case and the recursive step, both of which are themselves queries, combined by a `UNION ALL` (or just `UNION`) clause. We explain the functionality of recursive CTEs in detail below; in a nutshell, the base case is evaluated once at the beginning, and the recursive step is evaluated repeatedly. The recursive step can access results from the immediately preceding iteration by selecting from `cte_name` recursively. This iteration stops as soon as a fixpoint has been reached, i.e., as soon as the recursive step does not produce any rows. Every row produced during the iteration can then be accessed in the outer query.

In the example in @cte_recursive, we define a recursive query to calculate the first ten powers of two, 
$ x = 2^n, n in {1, ..., 10}. $ <pow2_math> 
We name the recursive CTE `pow2` and the columns `n` and `x`, according to @pow2_math. In the base case, we `SELECT 1, 2`, corresponding to $2^1 = 2$. Then, in the recursive step, we take the results of the previous iteration by selecting from `pow2`, to increase `n` by $1$ and multiply `x` by $2$. This is repeated until the fixpoint, defined by `WHERE n < 10`, is reached: as soon as `n >= 10`, no more rows are produced, ending the iteration. The outer query then returns the results of all iterations, i.e. the first ten powers of two.

#figure(
  caption: [The general outline of recursive CTEs (left) and applying a recursive CTE to calculate the first ten powers of two (right).],
  gap: gap,
  grid(
    columns: 2,
    rows: 1,
    column-gutter: 5pt,
    [
      ```sql
      WITH RECURSIVE cte_name(col1, col2, ...) AS (
        <base case>

        UNION ALL 

        <recursive step>
      )
      <outer query>
      ```
    ],
    [
      ```sql
      WITH RECURSIVE pow2(n, x) AS (
          SELECT 1, 2

          UNION ALL 

          SELECT n+1, x*2
          FROM pow2
          WHERE n < 10
      )
      SELECT n, x 
      FROM pow2;
      ```
    ],
  )
) <cte_recursive>

Internally, DuckDB uses three tables to perform the recursive computation.
- Except for the base case, each iteration can access the *working table*.
- Each iteration stores its result by overwriting the *intermediate table*.
- The results of all iterations are accumulated in the *union table*.

At the end of each iteration, the values in the intermediate table get copied to the working table. Thus, in the next iteration, we can use the results of the previous iteration.

@classic_pseudocode shows the internal evaluation of recursive CTEs in an imperative style. The comments on the right-hand side briefly explain the respective line and reference to @visualize_rec_cte by number, where we visualize each step by following the example introduced before.

TODO: Erkläre pseudocode

#figure(
  caption: [Internal evaluation of recursive CTEs as pseudocode (left) and comments (right) to explain and reference the associated line.],
  grid(
    columns: 2,
    gutter: 5pt,
    [
    ```
    union ← base_case()
    working ← union

    LOOP
      intermediate ← recursive_step(working)
      IF intermediate = ∅
        THEN BREAK
      union ← union ∪ intermediate
      working ← intermediate
    RETURN union
    ```
    ],
    [
      #codly(number-format: none)
      ```
      Base case defines first values for union   (1)
      Copy union to working                      (2)


      Evaluate recursive step, write to interm.  (3)
      Terminate if fixpoint has been reached     (4)

      Append intermediate to union               (4)
      Overwrite working with intermediate        (4)


      ```
    ]
  )
) <classic_pseudocode>

@visualize_rec_cte visualizes the role of each table. In `(1)` and `(2)`, we see how the first iteration is being prepared by evaluating the base case and writing its results to the union table, which then overwrites the working table. When evaluating the recursive step `(3)`, the working table and intermediate table act as input and output, respectively. In between iterations `(4)`, the working table is overwritten by the intermediate table in preparation for the next iteration. Notice how the union table is never being read from, but only appended, during iteration.

#codly-disable()
#figure(
  caption: [Base case (top) and recursive step (bottom) of recursive CTE from @cte_recursive visualized. Steps `(3)` and `(4)` are repeated in a loop (indicated by the looping arrow) until the fixpoint has been reached.],
  grid(
    rows: 2,
    gutter: 5pt,
    graphs.classic_base,
    graphs.classic_step
  )
) <visualize_rec_cte>

== Recursive CTEs come with problems <problems>
#codly-enable()

Let us take some notes on recursive CTEs as presented in the previous chapter. 

First, the results of each iteration are always appended to the union table `(4)`. This allows us to access the entire iteration history in the outer query. It turns out, however, that queries often select only few desired result rows and discard the others. Meanwhile, collecting all intermediate results causes the union table to potentially grow very large, so that storage limitations become an issue.

Secondly, the recursive step `(3)` only ever queries the working table, never the union table. This is an important feature, as continuous access to the union table would drastically impact performance due to its potentially rapid growth @recursive_relations. However, by denying access to the union table, we can only ever access the results of the immediately preceding iteration. To work around this limitation, we are forced to manually carry result rows through the iteration process. Both readability of the code and performance suffer greatly from this behaviour.

Furthermore, in order to guarantee the existence and uniqueness of the least fixpoint, the `recursive_step` needs to be monotonic. Under these circumstances, certain operations are prohibited, limiting the useable syntax.

== USING KEY: Keeping a dictionary we can reference <using-key_chapter>

To solve the problems described in @problems, Hirn and Grust @hirn2023fix proposed a new CTE variant that operates the union table like a keyed dictionary. The implementation in DuckDB followed shortly after by Bamberg, Hirn and Grust @bamberg2025duckdb. From here on, we refer to this new CTE variant as *using-key*, while refering to traditional CTEs as explained in @with_recursive with as *classic*.

@using-key shows the general outline of using-key, together with an example. In comparison to @cte_recursive, the `USING KEY` clause, followed by a key `(k1, k2, ...)`, has been added. We explain the functionality of using-key in detail below; in a nutshell, by defining list of columns to be the key of the query, the schema gets divided into key columns and payload columns. Whenever the CTE produces a row, and the values in the key columns have already been produced in a previous iteration, instead of simply appending the new row to the union table, the old row is being overwritten in the recurring table.

The example in @using-key demonstrates this with the `pow2` query. Additionally to the columns `n` and `x` that we already used in @cte_recursive, we define the column `c`. The `USING KEY (c)` clause then defines `c` to be a key column, and `n` and `x` to be payload columns. In the CTE, we always select `0` for the key column `c` with the effect that old values are constantly being overwritten. The result table `pow2` consists of this one row only.

#codly(number-format: numbering.with("1"))

#figure(
  caption: [The general outline of using-key (left) and applying using-key to calculate the first ten powers of two (right).],
  gap: gap,
  grid(
    columns: 2,
    rows: 1,
    gutter: 5pt,
    [
      ```sql
      WITH RECURSIVE cte_name(k1, ..., km, col1, ..., coln) 
      USING KEY (k1, ..., km) AS (
        <base case>

        UNION ALL 

        <recursive step>
      )
      <outer query>
      ```
    ],
    [
      ```sql
      WITH RECURSIVE pow2(c, n, x) 
      USING KEY (c) AS (
          SELECT 0, 1, 2

          UNION ALL 

          SELECT 0, n+1, x*2
          FROM pow2
          WHERE n < 10
      )
      SELECT n, x 
      FROM pow2;
      ```
    ],
  )
) <using-key>

Internally, the union table is replaced by the so-called *recurring table*. While the union table is expanded in every iteration by appending the iteration's solution, the recurring table acts like a keyed dictionary: let $i = (k_1, ..., k_m, "col"_1, ..., "col"_n)$ be a row produced in an arbitrary iteration. If the recurring table $u$ does not yet contain a row with the exact key values $(k_1, ..., k_m)$, then $i$ is simply appended to $u$ as usual. However, if $u$ _does_ contain a row $r$ with the exact key values $(k_1, ..., k_m)$, then $r$ is replaced by $i$ in $u$.

Hirn and Grust formulate this behaviour with the $"upsert"$ operation,

$
  "upsert"(u, i) equiv cases(
    "key error" &"if" |delta(pi_(k_1,...,k_m) (i))| < |i|,
    (u ⧔_(k_1,...,k_m) i) union.dot i &"otherwise"\,
  )
$ <upsert>

where $u$ and $i$ are tables, $delta$ denotes duplicate elimination and $⧔$ denotes left antijoin. In words, if `i` contains two or more rows with equal key values, `upsert` raises a key error; the payload values for those key values would be ambiguous. Else, we update all rows in `u` whose key values are included in `i`. If a key value in `i` is not yet included in `u`, we simply include the respective row.

@using-key_pseudocode shows the evaluation of recursive CTEs in the using-key variant in an imperative style, together with comments linking each line to the appropriate image in @visualize_using-key.

TODO: Erkläre pseudocode

#figure(
  caption: [Internal evaluation of using-key as pseudocode.],
  grid(
    gutter: 5pt,
    columns: 2,
    [
    ```
    recurring ← upsert(∅, base_case())
    working ← recurring

    LOOP
      intermediate ← recursive_step(working, recurring)
      IF intermediate = ∅
        THEN BREAK
      recurring ← upsert(recurring, intermediate)
      working ← intermediate
    RETURN recurring
    ```
    ],
    [
      #codly(number-format: none, )
      ```
      Base case defines first values for recurr. (1)
      Copy recurring to working                  (2)


      Evaluate recursive step by reading from working and reccuring, write to interm.    (3)
      Terminate if fixpoint has been reached     (4)

      Update or insert rows from intermediate to recurring                                  (4)
      Overwrite working with intermediate        (4)


      ```
    ]
  )
) <using-key_pseudocode>

And then, everything went well ...

#codly-disable()
#figure(
  caption: [Base case (top) and recursive step (bottom) of recursive CTE from @using-key visualized. Steps `(3)` and `(4)` are repeated in a loop (indicated by the looping arrow) until the fixpoint has been reached. (TODO: stimmt das? ja oder?)],
  grid(
    rows: 2,
    gutter: 5pt,
    graphs.using_key-base,
    graphs.using_key-step
  )
) <visualize_using-key>

