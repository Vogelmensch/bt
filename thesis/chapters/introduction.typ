= Introduction

== A breath of fresh air on recursive SQL

In SQL, Common table expressions (CTEs) enable binding the results of an intermediate query to a table name. The feature was introduced in the SQL:1999 standard to allow for more readable queries. The same standard allowed CTEs to reference themselves recursively, enabling the use of iteration. Recursive CTEs make SQL turing-complete, but their underlying functionality has remained unchanged since their introduction. 

Over time, CTEs in the way they were introduced in 1999 - we call them *classic* CTEs throughout this thesis - turned out to be lacking important features that are taken for granted in most imperative programming languages. Specifically, classic CTEs are missing the abilities to

+ access results from any, not just the immediately preceding, iteration, 
+ limit the result set size,
+ syntactic restrictions ... TODO
+  ...

The absence of these features resulted in queries that are inefficient and unnecessarily complicated. ...

In 2025, the Database Research Group at University of Tübingen suggested and implemented a new variant of recursive CTEs, which, due to its syntax, we call *using-key* throughout this thesis. 

using-key approaches the problems above by replacing the union table used in classic CTEs with a so-called recurring table. In classic CTEs, the *union table* collects all rows generated in every iteration until the query reaches its fixpoint. The union table cannot be accessed during iteration for performance reasons. The union table also holds on to early intermediate results, even if they are not needed anymore. In contrast, the *recurring table* works like a keyed dictionary. Every time a using-key recursive query "creates" a row with a key that is already present in the recurring table, the row holding this key gets replaced by the new row. This simple difference allows the using-key recursive CTE to

+ access results ...
+ limit size ...
+ syntax ...

We examine the theory in depth in @basics ...

== Four algorithms in two variants

We implemented the following four algorithms using both, classic recursive CTEs and using-key. 

In @astar, we find shortest paths in graphs using the *A\* search algorithm*. ...

In @lcs, we look for the *longest common subsequence* between two given strings,

In @needleman-wunsch, we compare DNA strings using the *Needleman-Wunsch algorithm*, 

in @drunken-bishop, we draw SSH fingerprint images using the *drunken bishop algorithm*


...

== USING KEY, prove yourself!

To quantify the performance gains (or losses) of using-key, we ran experiments, measuring runtime and memory usage of each algorithm for both classic and using-key. @measuring explains our methods and presents the results. 

A\*, LCS and Needleman-Wunsch show clear evidence of using-key's significant performance advantage. ...

Drunken Bishop tells a different story. Although using-key does not perform catastrophically worse when using the appropriate input representation, classic outperforms it easily. ...

...