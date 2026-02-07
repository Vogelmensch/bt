If a problem in computer science can be broken down into subproblems, and the optimal solution for the problem can be found by combining optimal solutions of the subproblems, then the problem is said to have optimal substructure. A strategy uses dynamic programming if it uses optimal substructure by recursively solving the subproblems and combining their solutions to yield the overall solution. 

Every dynamic programming problem can be described by a table and a method to recursively fill the table by using existing values. For our purpose, we can divide dynamic programming problems (or their solutions) into two distinct categories:
1. problems which only need to access those entries that have been calculated in the last iteration
2. problems which may need to access entries which have been calculated arbitrarily many iterations ago.

TODO: Classify investigated problems into the two categories and give outlook to results and reason.

With recursive common table expressions (CTEs), the SQL standard provides an intuitive approach for solving problems of category 1. However, while recursive CTEs make SQL turing-complete, problems of category 2 need complex and inefficient implementations. This is due to the fact that recursive CTEs do not allow the programmer to access results which have been calculated more than one iteration ago. 

By adding the `USING KEY` syntax to DuckDB, Bamberg, Hirn and Grust introduced a fundamentally new way of writing recursive queries. With `USING KEY`, the programmer gains the ability to access results which have been caluclated in an arbitrary iteration. 