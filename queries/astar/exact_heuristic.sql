CREATE OR REPLACE MACRO h(x) AS (
    SELECT st_distance_spheroid(
    st_point(c.lat / 10^6, c.long / 10^6),
    st_point(goal.lat / 10^6, goal.long / 10^6)
    )
    FROM 
        coords AS c JOIN
        coords AS goal ON goal.node_id = goal_node()
    WHERE 
        c.node_id = x
);