= Conclusions 

We explored the core ideas that lead to the development of using-key, the new recursive CTE variant included in DuckDB since version 1.3. We explained its syntax, its background functionality and the advantages it promises, all the while comparing it to the usual Implementation of recursive CTEs used in the past 25 years.

First and foremost, we developed four relevant algorithms using both approaches, explaining each of them in detail for both variants, and showing key differences in the resulting queries. Each algorithm has then been tested to answer the central question of where using-key shines, and where it is more of an obstacle than a solution.

For three of the four algorithms - A\*, LCS and Needleman-Wunsch - using-key proved to be a great benefit. The link between these algorithms is that they heavily rely on results from arbitrarily many iterations ago. One algorithm - Drunken Bishop - proved to suffer from using-key: the overhead of repeated access to the recurring table seems to outweigh the benefit of reduced storage needs. Because Drunken Bishop does only ever need to access the result of the immediately preceding iteration, a manual carry of old values, as it happens in the classic variants of the other three algorithms, is not needed.

The benefits of using-key for A\*, LCS and Needleman-Wunsch, an the advantage of classic for Drunken Bishop, always came in two parts. First, the superior variant was easier to implement, often to be contained within the inferior variant. Secondly, we saw performance improvements in terms of runtime and memory usage. These improvements were linear in some measures, quadratic or even cubic in others. For LCS and Needleman-Wunsch, using-key improved the uncertainty of the results by a factor of up to 39.

== Future work

using-key proved to be a useful tool when comparing three of the four algorithms in the way we implemented them. We cannot guarantee, however, that our Implementations are the most efficient for either variant. All of the algorithms can most certainly be implemented in a more efficient way. It could be interesting to explore the trade-offs between efficiency and ease of implementation in classic, and compare the results to using-key.

Also, while an exploration of even more algorithms in the style of this thesis would certainly be interesting and helpful for query authors, a generalizing theory predicting the usefulness of using-key in comparison to classic from the algorithm's implementation ideas, or maybe even from the problem definition alone, could be a goal to strive towards. 