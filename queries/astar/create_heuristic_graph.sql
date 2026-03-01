-- make sure to convert coords into correct unit!
INSTALL spatial;
LOAD spatial;

CREATE OR REPLACE MACRO goal_node() AS {goal_node};

CREATE OR REPLACE MACRO h(x) AS (
    SELECT st_distance_spheroid(
        st_point(c.lat, c.long),
        st_point(goal.lat, goal.long)
    ) :: INTEGER
    FROM 
        coords AS c JOIN
        coords AS goal ON goal.node_id = goal_node()
    WHERE 
        c.node_id = x
);

CREATE OR REPLACE TABLE {graph} AS (
    SELECT 
        node_from,
        node_to,
        weight,
        h(node_to) AS h
    FROM dists
);