-- Inserting location into DB:
-- 1. Simply copy coordinates from google maps (right-click on map)
-- insert into locations (lat, long, name) values
-- (paste here, 'name'), 
-- ...

-- Getting node IDs:
WITH loc_ids (name, node_id, long_diff, lat_diff, diff) AS (
    SELECT 
        l.name,
        c.node_id,
        abs(l.long - c.long) AS long_diff,
        abs(l.lat - c.lat) AS lat_diff,
        sqrt(long_diff^2 + lat_diff^2) AS diff
    FROM 
        locations AS l,
        coords AS c
)
SELECT 
    name,
    argmin(node_id, diff),
    min(diff)
FROM loc_ids
GROUP BY name
ORDER BY name;

-- ┌───────────────────────┬───────────────────────┬────────────────────┐
-- │         name          │ argmin(node_id, diff) │     min(diff)      │
-- │        varchar        │         int64         │       double       │
-- ├───────────────────────┼───────────────────────┼────────────────────┤
-- │ broadway              │                187536 │  365.2395106153379 │
-- │ central park          │                189104 │  869.6446629343124 │
-- │ domino park           │                140582 │ 168.34293986798562 │
-- │ empire state building │                186340 │ 485.37120071571644 │
-- │ jfk_airport           │                211574 │ 282.35359994516335 │
-- │ museum of ice cream   │                186670 │ 145.24686538865234 │
-- │ staten island zoo     │                223660 │  2403.317345309396 │
-- │ statue of liberty     │                 56304 │ 16467.861698573794 │
-- │ wall street           │                190099 │  428.6821476957096 │
-- │ yankee stadium        │                135135 │   417.602254210697 │
-- ├───────────────────────┴───────────────────────┴────────────────────┤
-- │ 10 rows                                                  3 columns │
-- └────────────────────────────────────────────────────────────────────┘