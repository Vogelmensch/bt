This chapter deals with the algorithms we used to test `USING KEY`. We explain every algorithm step-by-step, and view each step from three different angles: 
1. the imperative implementation which is the most intuitive approach for most people,
2. the traditional SQL approach using recursive CTEs with union tables, and
3. the new SQL approach using recursive CTEs with keyed dictionaries. 


#figure(
  caption: [
    The basic layout of a recursive common table expression. (a) shows the classic recursive CTE using union tables, while (b) shows DuckDBs implementation of dictionary-based CTEs. The individual steps are indicated in SQL comments.
  ],
  grid(
    columns: 2, rows: 2,
    gutter: 10pt,
    [
      ```SQL
      WITH RECURSIVE query_name (
        -- <column names>
      ) AS (
        -- <base case>
        UNION ALL 
        -- <recursive step>
      )
      -- <outer query>
      ```
    ],
    [
      ```SQL
      WITH RECURSIVE query_name (
        -- <column names>
      ) USING KEY (
        -- <key definitions>
        ) AS (
        -- <base case>
        UNION 
        -- <recursive step>
      )
      -- <outer query>
      ```
    ],
    [(a)],[(b)]
  )
) <rec_ctes_layout_comparison>

All recursive CTEs follow the same general layout. @rec_ctes_layout_comparison shows the general layout for both types of recursive CTEs. We will now go through the individual steps of query definition for both types. As a running example, we will define two queries that calculate the fibonacci numbers
$
  "fib"(n) = cases(
    0 "if" n = 0,
    1 "if" n = 1,
    f(n - 1) + f(n - 2) "else" 
  ). 
$

First, as CTEs naturally use tables to store intermediate and final results in, we need to define this tables column names. For example, when writing a query that should calculate the fibonacci numbers, we need two variables to calculate the next number in every step. Additionally, we may also want to store the numbers index. The column names in this example are shown below.

```SQL
idx, n1, n2
```

The next step, the key definitions, is only relevant for dict-based recursive CTEs. As dictionaries are key-value pairs, we need to define which column(s) of our table should be the key(s) for our dictionary. In the example of fibonacci numbers, it is intuitive to use the numbers index as as key.


```SQL
idx
```

Every recursion needs a base case. It provides values of our previously defined columns for the first iteration. For the fibonacci numbers, the base case ($"idx" = 0$) are the first two numbers to add, which are $n_1 = 0$ and $n_2 = 1$.

```SQL
SELECT 
    0 AS idx, 
    0 AS n1,
    1 AS n2
```

#box(
  stroke: 1pt + red,
  inset: 5pt,
  [*IDEA*: Write the beginning of the query together. I think everything can be better understood this way. But for the introduction here, we can also keep the individual explanations.]
)

Now comes the heart of the query, the recursive step. This is where recursive CTEs stand out from non-recursive ones, as we can access the result of the last iteration by selecting from the CTE itself. In our example, we calculate the next fibonacci number by adding the results of the previous iteration.

```SQL
SELECT 
    idx+1 AS idx,
    n2 AS n1,
    n1+n2 AS n2
FROM fib
WHERE idx < 20
```

Notice the `WHERE` clause in the last line, which defines the termination condition.

This step is the same in both kinds of recursive CTEs. However, we want to point out a _key_ feature of dict-based recursive CTEs at this opportunity.

While classic recursive CTEs can only access the previous iteration, with dict-based recursive CTEs, we can access arbitrary iterations by accessing the dictionary at an arbitrary key. For example, we could define a CTE that adds the 5th fibonacci number to every nth fibonacci number, where $n > 5$. As a mathematical function $f$, this can be written as 

$ 
  f(n) = cases(
    "fib"(n) "if" n <= 5,
    "fib"(n) + "fib"(5) "else"
  ),
$

while in SQL, we can write this as 

```SQL
SELECT 
        fib.idx+1,
        fib.n2,
        CASE 
            WHEN fib.idx <= 5
            THEN fib.n1 + fib.n2
            ELSE fib.n1 + fib.n2 + r.n2
        END
    FROM 
        fib LEFT OUTER JOIN 
        recurring.fib AS r ON r.idx = 5
    WHERE fib.idx < 20
```

This powerful feature proved extremely useful in some of the queries we implemented for this research.

TODO: Table maybe

#figure(
  caption: [Fibonacci number queries],
  grid(
    columns: 2,
    gutter: 10pt,
    [
    ```SQL
    WITH RECURSIVE fib (
        idx,
        n1,
        n2
    ) AS (
        SELECT 0, 0, 1

        UNION ALL 

        SELECT 
            idx+1,
            n2,
            n1+n2
        FROM fib
        WHERE idx < 20
    )
    SELECT idx, n1
    FROM fib;
    ```
    ],
    [
      ```SQL
      WITH RECURSIVE fib (
          idx,
          n1,
          n2
      ) USING KEY (idx) AS (
          SELECT 0, 0, 1

          UNION 

          SELECT 
              fib.idx+1,
              fib.n2,
              CASE 
                  WHEN fib.idx <= 5
                  THEN fib.n1 + fib.n2
                  ELSE fib.n1 + fib.n2 + r.n2
              END
          FROM 
              fib LEFT OUTER JOIN 
              recurring.fib AS r ON r.idx = 5
          WHERE fib.idx < 20
      )
      SELECT idx, n1
      FROM fib;
      ```
    ]
  )
)