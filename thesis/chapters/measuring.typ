= Measuring

Introduction here

== A\*

=== Setup

We chose the graphs of the USA from the "9th DIMACS Implementation Challenge"@dimacs as basis for the first benchmark. In those graphs, the nodes correspond to intersections, while the edges correspond to roads between them. The edge weights come in two flavors: Distance in meters and average travel time in seconds, where the latter takes the type of road into account. A separate table contains coordinates for each node. 

A graph representing a physical map is an obvious choice for testing A\*, because we can use the physical distance between a node and the goal node as the heuristic function. Naturally, we chose the distance graph for our measurements. 

First, we took the graph of New York City.
As the start node, we chose `node_id = 189104`, which lies within central park. From there, we selected all nodes within a $3 "km"$ radius as goal nodes, $1526$ in number.  We ran A\* on these pairings, measuring execution time and memory consumption. @central_park_facts shows an overview over this subgraph to get a rough picture of the region. 

#figure(
  caption: [Central Park graph facts],
  grid(
    columns: 2,
    rows: 2,
    column-gutter: 15pt,
    align: horizon,
    table(
      columns: 2,
      stroke: none,
      [nodes],table.vline(stroke: .5pt), [1526],
      table.hline(stroke: .5pt),
      [edges],[5016], 
      table.hline(stroke: .5pt),
      [mean edge weight],[1273.09],
      table.hline(stroke: .5pt),
      [stdev of edge weight],[855.33],
    ),

    image("images/nyc_roads.svg")
  )
) <central_park_facts>

Then, we took the graph of california and chose `node_id = 1056681` as the start node, which lies within Las Vegas. For the goals, we selected all 946 nodes located within a 20 km radius; because Las Vegas is smaller and surrounded by desert, the node-density is significantly lower compared to New York City. 

#figure(
  caption: [Vegas graph facts],
  grid(
    columns: 2,
    rows: 2,
    column-gutter: 15pt,
    align: horizon,
    table(
      columns: 2,
      stroke: none,
      [nodes],table.vline(stroke: .5pt), [946],
      table.hline(stroke: .5pt),
      [edges],[1264], 
      table.hline(stroke: .5pt),
      [mean edge weight],[2478.64],
      table.hline(stroke: .5pt),
      [stdev of edge weight],[3471.55],
    ),

    image("images/vegas_map.svg")
  )
) <vegas_facts>



=== Results

The results are shown in @nyc_3km. For both queries, the values are linearly distributed. It can clearly be seen how the classic CTE has a longer runtime for all number of expanded nodes. 

TODO: Regression, Formel finden, die die Differenz zwischen den Queries abhängig von der Anzahl der Nodes berechnet.

Unexpectedly, the runtimes for both types of queries separate into two distinct lines each. The same phenomenon can be observed in both, `t_user` and `t_sys`, but not in `t_real`. At the moment, I have no idea what this means.

TODO: show all graphs


#figure(
  caption: [Execution time of A\* on the New-York-City graph],
  image("images/astar_3_km.svg")
) <nyc_3km>

Memory. The memory measurement does not show any relation. Yes, the table clearly grows larger. But the memory does not seem to give a shit.

Now, I generated a random graph with  

```> python generators/graph.py 1000 1500 -w 10 -n keanu```

then, I measured astar from 0 to every other node.

#figure(
  image("images/astar_random.svg")
)



== LCS

=== Setup

We wrote a random string generator to provide the input for LCS. The generator used all 26 lower-case characters from the english alphabet. For each measurement, we generated two independent strings of equal lengths $l in {10, 20, 30, ..., 200}$, applied LCS in both flavors and measured execution time. We repeated the measurements ten times to yield the final results. The entire procedure was repeated analogously for measuring memory consumption.

#figure(
  caption: [Number of timeouts for LCS],
  table(
    columns: 3,
    stroke: none,
    table.header([Strings lengths], [Timeout for `classic`], [Timeouts for `using-key`]),
    table.hline(stroke: .5pt),
    [150], table.vline(stroke: .5pt), [1], table.vline(stroke: .5pt), [-],
    [170], [1], [-],
    [180], [4], [-],
    [190], [4], [1],
    [200], [4], [-],
  ),
)

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

With this in mind, we can have a look at the plot:

#figure(
  caption: [Mean and standard deviation of LCS time measurement.],
  image("images/lcs_10_to_200.svg")
)

Update: the memory measurement turned out to be ass. So I started another.

```
> python lcs.py -ucmx --file large_measurements/lcs_10_to_200_memory_big.csv --repeat 100 -r $(seq 10 10 200) --timeout 40
```

Hopefully, I'll get some better results from this one. Maybe I should do a similar one with time as well.


== Drunken Bishop

=== Setup

We randomly generated hexstrings of different lengths. The image dimensions were scaled by a factor of $3$, because at lower dimensions, the entire image frame would simply be filled with larger input strings. 

```
python bishop.py -r $(seq 20 20 500) -uc --scale 3 -tx -f large_measurements/bishop_0227_1716.csv --timeout 30 --repeat 10
```
=== Results

#figure(
  caption: [Execution time of drunken-bishop. The left plot shows a comparison between the two used queries, while the right plot shows classic only to visualize its shape.],
  grid(
    columns: 2,
    image("images/bishop_0227.svg"),
    image("images/bishop_classic_0227.svg")
  )
) <bishop_plot>


We can clearly see the increase in execution time in @bishop_plot for using-key, while classic appears to be staying constant at this scale. However we can see a linear increase in execution time when displaying the values for classic only.


== Needleman-Wunsch

Brief intro and expectations.

=== Setup

For each measurement, we generated a random string consisting of the characters A, C, G and T, to mimic a DNA sequence. This string was directly used as the first argument. To get the second argument, we copied the first argument character-wise; however, with a probability of $30%$, a copying error would occur, selecting one random character from the available set. Because the same character could be selected with a probability of $25%$, the overall expected difference between the arguments is $75% dot 30% = 22.5%$.

The string lengths ranged from $0$ to $300$. We solved the alignment problem using our two variants of the needleman-wunsch-algorithm explained in TODO and measured the execution times. 


```
python needleman.py -r $(seq 0 10 300) -p 0.3 -uctx --file large_measurements/needleman_0228_full.csv --repeat 10 --timeout 30
```
This measurement was done in two parts, but who cares.


=== Results

We removed two heavy outliers for classic. 

Fit:

Ayo this fits kinda small ngl, maybe reduce them 

$
"classic" &approx 0.0003137 x^2 - 0.0232 x + 0.6449\

"using-key" &approx 1.284 dot 10^(-5) x^3 - 0.002 x^2 + 0.158 x - 2.167
$

#figure(
  caption: [Outliers for classic variation of needleman],
  table(
        rows: 2,
        columns: 2,
        stroke: none,
        table.header([strings length], [time [s]]),
        table.hline(stroke: .5pt),
        [150], table.vline(stroke: .5pt), [191.01],
        [250], [271.78]
      )
)

#figure(
  caption: [Times for needleman],
  grid(
    columns: 2,
    image("images/needleman_scatter_cleaned.svg"),
    image("images/needleman_fit.svg")
  )
)

#figure(
  caption: [Times for needleman],
  image("images/needleman_err_cleaned.svg")
)



#bibliography("../references.bib")


