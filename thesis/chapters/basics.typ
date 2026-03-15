#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  languages: (
    sql: (name: "SQL", icon: emoji.duck)
  )
)

#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")

#import "rec_ctes_img.typ" as graphs

#let colgut = 15pt
#let rowgut = 10pt
#let gap = 15pt

= How to loop in SQL



== CTEs: Binding intermediate results

As queries get more complex, the good query author wants to keep their code well organized. Using too many subqueries often result in hard-to-read code. What if SQL had a way to define intermediate queries beforehand and bind their result tables to names, similar to variables in imperative programming languages? 

SQLs way of doing this is called the *Common Table Expression* (CTE). The general outline is shown in @cte_general, together with the example of calculating $(1+1) dot 2$. A CTE is defined via the `WITH` clause, followed by the cte name, followed by an arbitrarily large list of column names. The inner query is being evaluated before the outer query, and its result is being stored into a table named `cte_name`. This table has the columns specified in the CTE definition; their data types are derived from the inner query. The outer query can then reference this table.

#figure(
  caption: [General outline of CTEs (left) and example (right)],
  gap: gap,
  grid(
    columns: 2,
    rows: 2,
    column-gutter: colgut,
    row-gutter: rowgut,
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


== `WITH RECURSIVE`: Referencing CTEs recursively <with_recursive>

In order for SQL to become turing complete, some kind of iteration mechanism had to be added to the language's standard. Together with CTEs, SQL:1999 introduced _recursive CTEs_, which expand the general CTE by allowing self-reference within the inner query. 

See @cte_recursive for the general layout and an example. As we are dealing with a recursive query now, we need to provide an initial case and a recursive step. The latter needs a break condition in order to avoid infinite recursion; in this example, the break condition is `WHERE n < 10`.

#figure(
  caption: [The general outline of recursive CTEs (left) and applying a recursive CTE to calculate the first ten powers of two (right).],
  gap: gap,
  grid(
    columns: 2,
    rows: 1,
    column-gutter: 30pt,
    row-gutter: rowgut,
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
- At the end of each iteration, the values in the intermediate table get copied to the *working table*. Thus, in the next iteration, we can use the results of the previous iteration.
- The results of all iterations are accumulated in the *union table*.

@classic_pseudocode shows the internal evaluation of recursive CTEs in an imperative style. ... TODO

#figure(
  caption: [Internal evaluation of recursive CTEs as pseudocode.],
  [
    #codly(
      annotation-format: (i) => [#i.],
      annotations: (
        (start: 1, end: 1, content: [bla]),
        (start: 2, end: 2, content: [blub]),
        (start: 5, end: 5, content: [bleep]),
        (start: 6, end: 9, content: [blerp])
      )
    )
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
  ]
) <classic_pseudocode>

Following the example introduced in @cte_recursive, we visualize the process of iterative computation using recursive CTEs. ... shows the tables the recursive query uses as input and output: it has access to the working table and stores its results by writing to the intermediate table and appending the union table. ... shows how the working table gets overwritten in between iterations by the values stored in the intermediate table. This way, the query can always access the results from the previous iteration.

#codly-disable()
#figure(
  caption: [Base case of the recursive CTE from @cte_recursive visualized],
  graphs.classic_base
)

#figure(
  caption: [Recursive step of the recursive CTE from @cte_recursive visualized],
  graphs.classic_step
)

== The problem with recursive CTEs <problems>

#codly-enable()

Have a look at the previous example again. While this query confidently calculates $2^10$ for us, it also calculates and stores all intermediate results in the union table. In fact, the outer query in @cte_recursive returns all intermediate results. In order to return the $10"th"$ power of $2$ only, we need to explicitly select it in the outer query,

```sql
SELECT argmax(n, x), max(x)
FROM pow2;
```

While the additional work for the query author is manageable in this example, it grows while queries get more complex, as we will see in later chapters. 



But it is not just the query author who has to put in unnecessary work. Even if we select only those values that have been calculated in the last iteration, until this point, all intermediate values have been stored in the union table. Again, with increasing complexity and amount of data, all this unnecessarily stored data can easily overwhelm our system @passing2017sql.

Another question that arises is which values our CTE should have access to. We saw in @with_recursive that the CTE has access to the working table, which holds the results from the previous iteration. But what if we want to access results that have been calculated in an earlier iteration? While those values have been stored in the union table, we cannot access them during runtime; performance would suffer significantly due to duplicate computations @recursive_relations.

To work around the limitations of this short-term memory, query authors tend to store and pass on intermediate results manually [source]. This contributes to the issues of overcomplex queries and inefficient computation.


== `USING KEY`: Keeping a dictionary we can reference

To solve the problems described in @problems, Hirn and Grust @hirn2023fix proposed a new CTE variant that operates the union table like a keyed dictionary. The implementation in DuckDB followed shortly after by Bamberg, Hirn and Grust @bamberg2025duckdb. From here on, we refer to this new CTE variant as *using-key*, while refering to traditional CTEs as explained in @with_recursive with as *classic*.

@using-key shows the general outline of using-key, together with an example. In comparison to @cte_recursive, the `USING KEY` clause, followed by a key `(k1, k2, ...)`, has been added. A key is a list of columns. The schema can then be viewed as divided into key columns and payload columns. Whenever the CTE produces a row, and the values in the key columns have already been produced in a previous iteration, instead of simply appending the new row to the union table, the old row is being overwritten in the recurring table.

The example on the right of @using-key demonstrates this with the `pow2` query. Additionally to the columns `n` and `x` that we already used in @cte_recursive, we define the column `c`. The `USING KEY (c)` clause then defines `c` to be a key column, and `n` and `x` to be payload columns. In the CTE, we always select `0` for the key column `c` with the effect that old values are constantly being overwritten. The result table `pow2` consists of this one row only.



#figure(
  caption: [The general outline of using-key (left) and applying using-key to calculate the first ten powers of two (right).],
  gap: gap,
  grid(
    columns: 2,
    rows: 1,
    column-gutter: 30pt,
    row-gutter: rowgut,
    [
      ```sql
      WITH RECURSIVE 
        cte_name(k1, ..., km, col1, ..., coln) 
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
      WITH RECURSIVE 
        pow2(c, n, x) 
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

The essential internal evaluation strategy behind using-key is shown in @using-key_pseudocode. The most important element within it is the `upsert` operation,

$
  "upsert"(u, i) equiv cases(
    "key error" &"if" |delta(pi_(k_1,...,k_m) (i))| < |i|,
    (u ⧔_(k_1,...,k_m) i) union.dot i &"otherwise"\,
  )
$ <upsert>

where $u$ and $i$ are tables, $delta$ denotes duplicate elimination and $⧔$ denotes left antijoin. In words, if `i` contains two or more rows with equal key values, `upsert` raises a key error; the payload values for those key values would be ambiguous. Else, we update all rows in `u` whose key values are included in `i`. If a key value in `i` is not yet included in `u`, we simply include the respective row.

@using-key_pseudocode shows the evaluation of recursive CTEs in the using-key variant in an imperative style. ... TODO

#figure(
  caption: [Internal evaluation of using-key as pseudocode.],
  [
    #codly(
      annotation-format: (i) => [#i.],
      annotations: (
        (start: 1, end: 1, content: [bla]),
        (start: 2, end: 2, content: [blub]),
        (start: 5, end: 5, content: [bleep]),
        (start: 6, end: 9, content: [blerp])
      )
    )
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
    ]
) <using-key_pseudocode>

And then, everything went well ...

Here is a visualization

#codly-disable()
#figure(
  caption: [base],
  graphs.using_key-base
)

And then ...

#figure(
  caption: [],
  graphs.using_key-step
)


#bibliography("../references.bib")