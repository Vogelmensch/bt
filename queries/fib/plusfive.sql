WITH RECURSIVE fib (
    idx,
    n1,
    n2
) USING KEY (idx) AS (
    SELECT 0, 0, 1

    UNION 

    SELECT 
        fib.idx+1,
        fib.n2,
        CASE 
            WHEN fib.idx <= 5
            THEN fib.n1 + fib.n2
            ELSE fib.n1 + fib.n2 + r.n2
        END
    FROM 
        fib LEFT OUTER JOIN 
        recurring.fib AS r ON r.idx = 5
    WHERE fib.idx < 20
)
SELECT idx, n1
FROM fib;