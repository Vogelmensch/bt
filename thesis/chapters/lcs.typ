= Longest Common Subsequence

Let us take a file $f_1$ and create a copy $f_2$. Let us now get a friend and ask them to secretly manipulate $f_2$ however they want. We then want to find the changes they made. How should we do this?

We could write a query that compares both files letter-by-letter. This would not go well though; our friend had to add only one letter to the beginning of the file, and almost all comparisons would immediately fail. 

It turns out that, in order to find the differences, we need to find the similarities first. If we know which parts of the files are equal, then we know which parts differ. In other words: We need to find the _longest common subsequence_.

A subsequence of a string $s$ is a string $s_"sub"$ that can be derived from $s$ by deleting some or no characters without changing the order of the remaining characters [from #link("https://en.wikipedia.org/wiki/Subsequence")[Wikipedia]]. A subsequence common to two strings $s_1$ and $s_2$ is a subsequence that both strings have. For example, if 
$ s_1 = "\"Never gonna give you up\", and" $
and 
$ s_2 = "\"Never gonna let you down\"," $
some subsequences common to both $s_1$ and $s_2$ would be "Never", "Never gonna", "gonna you", but also "N  p", "eea" "r na u", etc. Now, what we are looking for is the _longest_ common subsequence, which, in this case, is "Never gonna e you " (notice the whitespace at the end).

