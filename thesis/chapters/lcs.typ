#import "../definitions.typ" as def

= Longest Common Subsequence

A subsequence of a string $s$ is a string $s_"sub"$ that can be derived from $s$ by deleting some or no characters without changing the order of the remaining characters [from #link("https://en.wikipedia.org/wiki/Subsequence")[Wikipedia]]. A subsequence common to two strings $s_1$ and $s_2$ is a subsequence that both strings have. For example, if 
$ s_1 = "\"Never gonna give you up\"," $
and 
$ s_2 = "\"Never gonna let you down\"," $
some subsequences common to both $s_1$ and $s_2$ would be "Never", "Never gonna", "gonna you", but also "N  p", "eea" "r na u", etc. Now, what we are looking for is the _longest_ common subsequence, which, in this case, is "Never gonna e you " (notice the whitespace at the end).

Note that the longest common subsequence is not equal to the longest common _substring_. The difference is that all neighbored characters in the longest common substring of two strings need to be neighbored in the two input strings as well. In the above example, the longest common substring would be "Never gonna ".


== Filling the dynamic programming table

We solve LCS by implementing the "traditional technique" first proposed by Wagner and Fischer, using both `USING KEY` and `WITH RECURSIVE` @string_to_string @survey_of_lcs. This approach breaks the problem down by finding the longest common subsequence for all combinations of prefixes of the input strings. 

#def.redbox([TODO: If there is time, we will try to find an algorithm that works better in `WITH RECURSIVE`, and compare that to the results from this chapter.])



Let us illustrate this by following a simple example. Let
$ s_1 = "\"ACB\"", $
and 
$ s_2 = "\"ADBE\"", $
where the LCS is obviously 
$ "lcs"(s_1, s_2) = "\"AB\"". $

...

blabla just continue with SQL, you can always finish this part here later.


#bibliography("../references.bib")