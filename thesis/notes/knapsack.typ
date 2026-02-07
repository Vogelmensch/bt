Okay so, I just did the first real measurements of knapsack.

Of course, the final table is huge in the classic version. No surprise there. But concerning runtime, using-key seems to perform slightly WORSE than the classic version. And that is although using-key does not even read from the recurring table in this query (it does multiple times in all the other queries, where it outperforms classic all the time). Maybe this has to do with the fact that we are able to use the data from the previous iteration? 

TODO: Test with limited RAM. I don't know how to do this yet.
ANSWER: Yes, you do. You can simply limit the available RAM and DuckDB will exit with an "out-of-memory-error". `WITH RECURSIVE` does not use Swap-Space or any of that. So you cannot get, like, speed-improvements from using RAM instead of disk or something like that. The only thing you can get is queries that cannot be solved with limited RAM.