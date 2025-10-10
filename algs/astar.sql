CREATE OR REPLACE MACRO start_node() AS 0;
CREATE OR REPLACE MACRO goal_node() AS 4242;

CREATE OR REPLACE MACRO width() AS 10;
CREATE OR REPLACE MACRO h(x) AS sqrt(((x % width()) - (goal_node() % width()))^2 + ((x / width()) - (goal_node() / width()))^2);

WITH RECURSIVE
dijkstra (
    node_id,
    dist,
    f,
    prev,
    visited
) USING KEY (node_id) AS (
    -- initial case
    SELECT 
        start_node(), 
        0,
        h(start_node()),
        NULL, 
        false
    
    -- Recurring Table (recurring.dijkstra):
    --      Holds all the nodes that have been seen (but not necessarily visited)

    UNION

    (
    -- set "visited" for smallest-dist-node(s) to TRUE
    SELECT 
        node_id, 
        dist, 
        f,
        prev, 
        true
    FROM recurring.dijkstra
    WHERE 
        NOT visited AND
        f = (SELECT min(f) FROM recurring.dijkstra WHERE NOT visited)

    UNION

    -- update neighbors of smallest node(s)
    SELECT
        -- id of neighbor
        nbs.node_to,
        -- new distance
        sml.dist + nbs.weight,
        -- f-value: distance + heuristic of node
        sml.dist + nbs.weight + h(nbs.node_to),
        -- new prev
        sml.node_id,
        -- still unvisited
        false
    FROM
        recurring.dijkstra AS sml JOIN -- smallest
        graph              AS nbs ON sml.node_id = nbs.node_from LEFT OUTER JOIN -- neighbors
        recurring.dijkstra AS old ON nbs.node_to = old.node_id -- old dist and prev
    WHERE 
        -- not visited yet -> part of the front
        NOT sml.visited AND
        -- sml is the smallest node in the front
        sml.f = (SELECT min(f) FROM recurring.dijkstra WHERE NOT visited) AND 
        -- modify only neighbors with smaller distances
        sml.dist + nbs.weight < coalesce(old.dist, CAST('inf' AS FLOAT)) AND 
        -- stop when path to goal node has been found
        sml.node_id != goal_node()
    )
),
path_as_string (
    new_node,
    path_string,
) AS (
    SELECT 
        goal_node(), 
        (SELECT '' || goal_node()),

    UNION ALL

    SELECT 
        d.prev,
        d.prev || ' -> ' || p.path_string,

    FROM path_as_string AS p JOIN dijkstra AS d ON p.new_node = d.node_id
)

SELECT 
    path_string AS 'Path',
    (SELECT dist FROM dijkstra WHERE node_id = goal_node()) AS 'Distance'
FROM 
    path_as_string
WHERE new_node = start_node();
