-- calculate 2^n using multiplication and addition only
WITH RECURSIVE pow2(i, n, x) AS (
    SELECT 
        series.i,
        0,
        1 
    FROM generate_series(2, 3) AS series(i)

    UNION ALL 

    SELECT i, n+1, x*i
    FROM pow2
    WHERE n < 10
)
FROM pow2;