#set heading(numbering: "1.1")

#import "rec_ctes_img.typ": it2, im2

#let colgut = 15pt
#let rowgut = 10pt
#let gap = 15pt

= How to loop in SQL

The SQL standard enables the query author to ...

== CTEs: Binding intermediate results

As queries get more complex, the exemplary query author wants to keep their code well organized. Using too many subqueries often result in hard-to-read code. What if SQL had a way to define intermediate queries beforehand and bind their result tables to names, similar to variables in imperative programming languages? 

SQLs way of doing this is called the *Common Table Expression* (CTE). The general outline is shown in @cte_general. A CTE is defined via the `WITH` clause, followed by the cte name, followed by an arbitrarily large list of columns. The inner query is being evaluated before the outer query, and its result is being stored into a table named `cte_name`. This table has the columns specified in the CTE definition; their data types are derived from the inner query. The outer query can then reference this table.

#figure(
  caption: [CTE outline and example.],
  gap: gap,
  grid(
    columns: 2,
    rows: 2,
    column-gutter: colgut,
    row-gutter: rowgut,
    [
      ```sql
      WITH cte_name(col1, col2, ...) AS (
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
    ],
    [General outline of a CTE],
    [Example: Calculating $(1+1) dot 2$ using a CTE]
  )
) <cte_general>


== `WITH RECURSIVE`: Making SQL turing-complete <with_recursive>

In order for SQL to become turing complete, some kind of iteration mechanism had to be added to the language's standard. Together with CTEs, SQL:1999 introduced _recursive CTEs_, which expand the general CTE by allowing self-reference within the inner query. 

See @cte_recursive for the general layout and an example. As we are dealing with a recursive query now, we need to provide an initial case and a recursive step. The latter needs a break condition in order to avoid infinite recursion; in this example, the break condition is `WHERE n < 10`.

#figure(
  caption: [Recursive CTE outline and example.],
  gap: gap,
  grid(
    columns: 2,
    rows: 2,
    column-gutter: colgut,
    row-gutter: rowgut,
    [
      ```sql
      WITH RECURSIVE cte_name(col1, col2, ...) AS (
        <initial case>

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
    [General outline of a recursive CTE],
    [Example: Calculating $2^10$ using a recursive CTE.]
  )
) <cte_recursive>

Internally, DuckDB uses three tables to perform the recursive computation.
- Except for the base case, each iteration can access the *working table*.
- Each iteration stores its result by overwriting the *intermediate table*.
- At the end of each iteration, the values in the intermediate table get copied to the *working table*. Thus, in the next iteration, we can use the results of the previous iteration.
- The results of all iterations are accumulated in the *union table*.

Following the example introduced in @cte_recursive, we visualize the process of iterative computation using recursive CTEs. @example_it shows the tables the recursive query uses as input and output: it has access to the working table and stores its results by writing to the intermediate table and appending the union table. @example_im shows how the working table gets overwritten in between iterations by the values stored in the intermediate table. This way, the query can always access the results from the previous iteration.

#figure(
  placement: top,
  caption: [The CTE calculates the 2nd iteration using data from the working table and writing to the intermediate- and union table respectively.],
  it2
) <example_it>

#figure(
  placement: top,
  caption: [The working table gets overwritten by the intermediate table between the 2nd and 3rd iterations.],
  im2
) <example_im>


== The problem with recursive CTEs

Have a look at the example in @cte_recursive again. While this query confidently calculates $2^10$ for us, it also calculates *and stores* all intermediate results. In fact, the outer query does return all intermediate results for us. In order to select the $10"th"$ power of $2$ only, we need to explicitly select it in the outer query,

```sql
SELECT argmax(n, x), max(x)
FROM pow2;
```

[TODO: punkt?]

While the additional work is manageable in this example, it grows while queries get more complex, as we will see in later chapters. 

But it is not just the query author who has to put in unnecessary work. Even if we select only those values that have been calculated in the last iteration, until this point, *all intermediate values* have been stored in the so-called _Union Table_. Again, with increasing complexity and amount of data, all this unnecessarily stored data can easily overwhelm our system.

Finally, the question arises which values our CTE should have access to. We saw in @with_recursive, that the CTE has access to the working table, which holds the results from the previous iteration. But what if we want to access results which have been calculated in an _even earler_ iteration? While those values have been stored in the union table, we cannot access them during runtime, as we do not have access to the union table. 

TODO: warum eigentlich nicht?


== `USING KEY`: making loops great again