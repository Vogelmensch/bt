- The dists graph is measured in meters
- The times graph ???

On the website, it says "arc lengths" ??? 

Alright, so I got all nodes that are $<= 1 "km"$ from Grand Central station, in the h value of course. That's 304 nodes. 
First, I had to perform

``` python astar.py nyc.db dists 189439 189439 --heu ```

in order to calculate the h-values for all nodes in relation to grand central. Then, inside duckdb, I performed

``` copy (select node_from from h_dists where h < 1000 group by node_from) to 'one_km_from_station.csv'; ```

to get all nodes within $1 "km"$ of grand central. This, I simply put into `astar.py`. No timeout necessary. 