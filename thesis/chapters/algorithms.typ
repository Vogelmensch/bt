= Algorithms

Since May 2025, recursive CTE variant "using-key" as presented in @using-key_chapter is more than just dry theory. Bamberg, Hirn and Grust @bamberg2025duckdb implemented using-key and integrated it into DuckDB; it has been a part of the DBMS since version 1.3 @duckdb_1.3.

In this chapter, we use using-key by implementing four famous algorithms: A\* (@astar), LCS (@lcs), Needleman-Wunsch (@needleman-wunsch) and Drunken Bishop (@drunken-bishop). We explain the motivations and general ideas behind each algorithm, and then implement them in both CTE variants to compare the queries. 
We show how A\*, LCS and Needleman-Wunsch are more intuitive to implement in using-key and how classic even consists of using-key and some overhead for these algorithms. We explain this by the need to access results from earlier iterations; in classic, we always have to manually carry these results, complicating implementation. As for Drunken Bishop, we find things to be the other way around: here, classic is much more concise than using-key. We explain this by the fact that we only ever need the results from the immediately preceding iteration.

#include("astar.typ")
#include("lcs.typ")
#include("needleman.typ")
#include("bishop.typ")