= How to loop in SQL

The SQL standard enables the query author to ...

== CTEs: Binding intermediate results

As queries get more complex, the exemplary query author wants to keep their code well organized. Using too many subqueries often result in hard-to-read code. What if SQL had a way to define intermediate queries beforehand and bind their result tables to names, similar to variables in imperative programming languages? 

SQLs way of doing this is called the *Common Table Expression* (CTE). The general outline is shown in @cte_general. The inner query is being evaluated before the outer query, and its result is being stored into `intermediate_table`. The outer query can then reference this table.

TODO: Example, maybe next to the outline in the same figure.

#figure(
  caption: [General outline of a CTE],
  [
    ```sql
    WITH intermediate_table(col1, col2, ...) AS (
      <inner query>
    )
    <outer query>
    ```
  ]
) <cte_general>


== `WITH RECURSIVE`: Making SQL turing-complete




== Why `WITH RECURSIVE` kinda sucks


== `USING KEY`: making loops great again