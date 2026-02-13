= Measuring

Introduction here

== A\*

We chose the graphs of New York City from the "9th DIMACS Implementation Challenge"@dimacs as basis for the first benchmark. In this graph, the nodes correspond to intersections, while the edges correspond to roads between them. The edge weights come in two flavors: Distance in meters and average travel time in seconds, where the latter takes the type of road into account. A separate table contains coordinates for each node. 

A graph representing a physical map is an obvious choice for testing A\*, because we can use the physical distance between a node and the goal node as the heuristic function. Naturally, we chose the distance graph for our measurements. @nyc_facts shows some facts.

#figure(
  caption: [NYC graph facts],
  grid(
    columns: 2,
    rows: 1,
    column-gutter: 15pt,
    table(
      columns: 2,
      [nodes],[],
      [edges],[],
      [mean edge weight],[],
      [stdev of edge weight],[],
    ),
    image(
      "../images/all_edge_weights.svg"
    )
  )
) <nyc_facts>

As start node, we chose `node_id = 189104`, which lies within central park. From there, we selected all nodes within a $3 "km"$ radius as goal nodes, $1526$ in number.  We ran A\* on these pairings, measuring execution time and memory consumption. @central_park_facts shows an overview over this subgraph to get a rough picture of the region. Keep it mind, though, that we ran A\* on the entire NYC-graph.

#figure(
  caption: [Central Park graph facts],
  grid(
    columns: 2,
    rows: 1,
    column-gutter: 15pt,
    table(
      columns: 2,
      [nodes],[1526],
      [edges],[5016],
      [mean edge weight],[1273.09],
      [stdev of edge weight],[855.33],
    ),
    image(
      "../images/edge_weights.svg"
    )
  )
) <central_park_facts>

TODO: I just found out that the measurements did not include three nodes... the list of nodes has just been updated.

The results are shown in @nyc_3km. For both queries, the values are linearly distributed. It can clearly be seen how the classic CTE has a longer runtime for all number of expanded nodes. 

TODO: Regression, Formel finden, die die Differenz zwischen den Queries abhängig von der Anzahl der Nodes berechnet.

Unexpectedly, the runtimes for both types of queries separate into two distinct lines each. The same phenomenon can be observed in both, `t_user` and `t_sys`, but not in `t_real`. At the moment, I have no idea what this means.

TODO: show all graphs


#figure(
  caption: [Execution time of A\* on the New-York-City graph],
  image("../images/astar_3_km.svg")
) <nyc_3km>

Memory. The memory measurement does not show any relation. Yes, the table clearly grows larger. But the memory does not seem to give a shit.

Now, I generated a random graph with  

```> python generators/graph.py 1000 1500 -w 10 -n keanu```

then, I measured astar from 0 to every other node.

#figure(
  image("../images/astar_random.svg")
)



== LCS

```
> python lcs.py -uctx --file large_measurements/lcs_10_to_100.csv -r $(seq 10 10 100) --repeat 10
```

```
> python lcs.py -uctx --file large_measurements/lcs_110_to_200.csv -r $(seq 110 10 200) --repeat 10 --timeout 30
```

```
python lcs.py -uctx --file large_measurements/lcs_210_to_300.csv -r $(seq 210 10 300) --timeout 720
```

This one threw an `Out of Memory Error` at query 3.

Also, we got the following timeouts for classic: 

```
┌───────────────┬──────────┐
│ String Length │ Timeouts │
│     int64     │  int64   │
├───────────────┼──────────┤
│           150 │        1 │
│           170 │        1 │
│           180 │        4 │
│           190 │        4 │
│           200 │        4 │
└───────────────┴──────────┘
```

and the following timeout for using-key:

```
┌───────────────┬──────────┐
│ String Length │ Timeouts │
│     int64     │  int64   │
├───────────────┼──────────┤
│      190      │    1     │
└───────────────┴──────────┘
```

With this in mind, we can have a look at the plot:

#figure(
  caption: [Mean and standard deviation of LCS time measurement.],
  image("../images/lcs_10_to_200.svg")
)

Update: the memory measurement turned out to be ass. So I started another.

```
> python lcs.py -ucmx --file large_measurements/lcs_10_to_200_memory_big.csv --repeat 100 -r $(seq 10 10 200) --timeout 40
```

Hopefully, I'll get some better results from this one. Maybe I should do a similar one with time as well.

#bibliography("../references.bib")