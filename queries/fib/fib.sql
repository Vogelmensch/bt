WITH RECURSIVE fib (
    idx,
    n1,
    n2
) AS (
    SELECT 0, 0, 1

    UNION ALL 

    SELECT 
        idx+1,
        n2,
        n1+n2
    FROM fib
    WHERE idx < 20
)
SELECT idx, n1
FROM fib;