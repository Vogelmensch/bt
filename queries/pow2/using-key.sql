-- calculate 2^n using multiplication and addition only
WITH RECURSIVE pow2(i, n, x) USING KEY (i) AS (
    SELECT 
        series.i,
        0,
        1 :: BIGINT
    FROM generate_series(1, 10) AS series(i)

    UNION 

    SELECT i, n+1, x*i
    FROM pow2
    WHERE n < 10
)
FROM pow2;