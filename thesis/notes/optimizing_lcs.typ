Consider two alternative version of classic lcs.

=== 1. "normal" version
```sql
WITH current_row(y) AS ( 
    SELECT max(yidx) + 1
    FROM lcs
    WHERE xidx = length(s1())
) 
FROM lcs
WHERE 
    -- when the current row number is larger than the maximal row number, terminate
    (SELECT y FROM current_row) <= (SELECT y FROM max_row) 
```


=== 2. modified version
```sql
WITH current_row(y) AS ( 
    SELECT max(yidx) + 1
    FROM lcs
    WHERE xidx = length(s1())
) 
SELECT 
    lcs.*
FROM 
    lcs JOIN -- manually carry table
    current_row ON lcs.yidx >= current_row.y - 1 JOIN -- choose only relevant rows
    max_row ON current_row.y <= max_row.y -- termination condition
```

The code snippets show the start of the querie's iterative part. With the modified version, my goal was to achieve better performance by selecting only the data that we need to proceed, in contrast to the entire table in the first query. However, upon testing, the second query quickly proved itself to be way inferior. The many `JOIN`-operations appear to be too costly.