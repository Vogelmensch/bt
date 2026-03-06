COPY (
    WITH nodes(id, h, r) AS (
        SELECT 
            g.node_to, 
            g.h, 
            radius.r,
            row_number() OVER (
                PARTITION BY radius.r
            ) AS rn
        FROM 
            h_dists AS g JOIN 
            generate_series(500, 10000, 500) AS radius(r)
                ON abs(g.h - radius.r) < 10
    )
    SELECT id
    FROM nodes
    WHERE rn <= 5
    ORDER BY r
) TO 'graphs/california_radius_goals.csv';