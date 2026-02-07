= Introduction

#lorem(80)#footnote([No bugs please, read the Request for Comment...@rfc9225])

```sql
SELECT *
FROM   table₁
WHERE  true;
```

== Some bad text 

Recursive CTEs have been a thing in SQL for the past thirty years or so. In all that time, the standard semantics have stayed the same. This approach is simple and it made SQL turing-complete, but it is far from perfect. A lot of queries which are easy so write in other programming languages have been way too difficult to write in SQL, simply because `WITH RECURSIVE` did not implement the necessary features.

Now, a new feature has been introduced into DuckDB: `USING KEY`. With this new feature, we can do two things that were not possible before.
1. Access the union table (now called differently, I don't remember) during query execution (this is a game changer)
2. Update previous results instead of dumping everything onto the union table. This saves a lot of memory.

What this thesis does is investigate the difference between those two methods. I implemented some common dynamic programming algorithms in both, the old and the new way, and compared runtime and memory usage. This is to show that `USING KEY` is actually amazing and not just some random new feature.
