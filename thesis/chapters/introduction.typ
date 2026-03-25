= Introduction

The goal of this thesis is to test using-key, the new recursive CTE variant implemented in DuckDB since version 1.3, in real applications to highlight differences in syntax and test and compare its performance to classic recursive CTEs. The following sections provide an overview over the chapters of this thesis.

== A breath of fresh air on recursive SQL

In SQL, Common table expressions (CTEs) enable binding the results of an intermediate query to a table name. The feature was introduced in the SQL:1999 standard to allow for more readable queries. The same standard allowed CTEs to reference themselves recursively, enabling the use of iteration. Recursive CTEs make SQL turing-complete, but their underlying functionality has remained unchanged since their introduction. 

Over time, CTEs in the way they were introduced in 1999 - we call them *classic* CTEs throughout this thesis - turned out to be lacking important features that are taken for granted in most imperative programming languages. Specifically, classic CTEs are missing the abilities to

+ access results from any, not just the immediately preceding, iteration, 
+ udpate previous results instead of appending new results to limit the result set size, and
+ use syntax elements such as, among others, negations in the inner query.

The absence of these features resulted in queries that are inefficient and unnecessarily complicated. ...

In 2025, the Database Research Group at University of Tübingen suggested and implemented a new variant of recursive CTEs, which, due to its syntax, we call *using-key* throughout this thesis. 

using-key approaches the problems listed above by replacing the union table used in classic CTEs with a so-called recurring table. In classic, the *union table* collects all rows generated in every iteration until the query reaches its fixpoint. The union table cannot be accessed during iteration for performance reasons. The union table also holds on to early intermediate results, even if they are not needed anymore. In contrast, the *recurring table* works like a keyed dictionary. Every time using-key produces a row with a key that is already present in the recurring table, the row holding this key gets replaced by the new row. This simple difference allows using-key to fulfill the abilities listed above.

In @basics, we examine the core ideas behind using-key and its implementation in detail, all the while comparing it to classic. 

== Four algorithms in two variants

We implemented the following four algorithms using both CTE variants. 

In @astar, we find shortest paths through graphs using the *A\* search algorithm*. Because A\* constantly queries previously calculated shortest paths for non-goal nodes, using-key proves to be benefitial.

In @lcs, we look for the *longest common subsequence* between two given strings. Our approach for solving LCS traverses a dynamic programming table, using results from previous iterations. Again, using-key proves to be benefitial for this.

In @needleman-wunsch, we compare DNA strings using the *Needleman-Wunsch algorithm*, which works similarly to LCS and benefits from similar advantages.

In @drunken-bishop, we draw SSH fingerprint images using the *Drunken Bishop algorithm*. In contrast to the other three algorithms, accessing previous results other than the immediately preceding one is not required here. using-key shows to be more complicated here.


== USING KEY: fast and light?

To quantify the performance gains (or losses) of using-key, we ran experiments, measuring runtime and memory usage of each algorithm for both classic and using-key. @measuring explains our methods and presents the results. 

For @measure_astar, we repeatedly applied A\* to two road network graphs of US cities. In relation to the number of expanded nodes, runtime for both CTE variants are linear, with using-key having a lower slope. For memory usage, using-key is linear with small slope, while classic follows a quadratic distribution.

For @measure_lcs, we applied LCS to randomly generated strings. In relation to string length, using-key is linear in both runtime and memory usage, while classic does not appear to follow a clear pattern. using-key is superior to classic in terms of mean and standard deviation.

For @measure_needleman, we applied Needleman-Wunsch to randomly generated DNA strings. In relation to string length, for runtime and memory usage, both using-key and classic follow a main curve that also appears to be a lower limit, i.e., some measurements fall far above these curves. using-key's main curve is linear, while classic's main curve is cubic for both measurements.

For @measure_bishop, we applied Drunken Bishop to randomly generated strings of hexadecimal numbers. In relation to string length, both CTE variants are linear in runtime and memory usage, with classic outperforming using-key.