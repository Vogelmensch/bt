CREATE OR REPLACE MACRO h(x) AS (
    SELECT 
        (c.lat - goal.lat)^2 + (c.long - goal.long)^2
    FROM 
        coords AS c JOIN
        coords AS goal ON goal.node_id = goal_node()
    WHERE 
        c.node_id = x
);