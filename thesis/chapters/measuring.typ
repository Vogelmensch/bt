= Measuring

Introduction here

== A\*

=== Setup

We chose the graphs of the USA from the "9th DIMACS Implementation Challenge"@dimacs as basis for the first benchmark. In those graphs, the nodes correspond to intersections, while the edges correspond to roads between them. The edge weights come in two flavors: Distance in meters and average travel time in seconds, where the latter takes the type of road into account. A separate table contains coordinates for each node. 

A graph representing a physical map is an obvious choice for testing A\*, because we can use the physical distance between a node and the goal node as the heuristic function. Naturally, we chose the distance graph for our measurements. 

First, we took the graph of New York City.
As the start node, we chose `node_id = 189104`, which lies within central park. From there, we selected all nodes within a $3 "km"$ radius as goal nodes, $1526$ in number.  We ran A\* on these pairings, measuring execution time and memory consumption. @central_park_facts shows an overview over this subgraph to get a rough picture of the region. 

#figure(
  caption: [New York City graph in numbers (left) and visually represented as a map (right). The red dot represents the starting position for A\*. The black lines represent all edges that are connected to nodes within a 3 km radius of the starting position, all of which have been chosen as goal nodes. One can easily identify the white rectangular area as Central Park.],
  grid(
    columns: 2,
    rows: 2,
    column-gutter: 15pt,
    align: horizon,
    table(
      columns: 2,
      stroke: none,
      [number of nodes],table.vline(stroke: .5pt), [1430],
      table.hline(stroke: .5pt),
      [number of edges],[5016], 
      table.hline(stroke: .5pt),
      [mean edge weight],[1273.09],
      table.hline(stroke: .5pt),
      [stdev of edge weight],[855.33],
    ),

    image("images/nyc_roads.svg")
  )
) <central_park_facts>

Then, we took the graph of California and Nevada and chose `node_id = 1791103` as the start node, which lies within Las Vegas. As goals, we selected 582 random nodes within a radius of 3 km from the start node. @vegas_facts shows an overview of this subgraph.

#figure(
  caption: [Las Vegas graph in numbers (left) and visually represented as a map (right), analogously to @central_park_facts. One can identify the area south-west to the starting point as downtown Las Vegas.],
  grid(
    columns: 2,
    rows: 2,
    column-gutter: 15pt,
    align: horizon,
    table(
      columns: 2,
      stroke: none,
      [number of nodes],table.vline(stroke: .5pt), [1638],
      table.hline(stroke: .5pt),
      [number of edges],[4988], 
      table.hline(stroke: .5pt),
      [mean edge weight],[1299.16],
      table.hline(stroke: .5pt),
      [stdev of edge weight],[873.34],
    ),

    image("images/vegas_map.svg")
  )
) <vegas_facts>

=== Results

The results are shown in @astar_times. For both queries, the values are linearly distributed. It can clearly be seen how the classic CTE has a longer runtime for all number of expanded nodes. 

Unexpectedly, the runtimes for both types of queries separate into two distinct lines each. The same phenomenon can be observed in both, `t_user` and `t_sys`, but not in `t_real`. At the moment, I have no idea what this means.

#figure(
  caption: [Execution time of A\* on the graph of New York City (left) and on the graph of Las Vegas (right)],
  grid(
    columns: 2,
    image("images/astar_3_km.svg"),
    image("images/astar_vegas.svg")

  )

) <astar_times>


== LCS

=== Setup

We wrote a random string generator to provide the input for LCS. The generator used all 26 lower-case characters from the english alphabet. For each measurement, we generated two independent strings of equal lengths $l in {10, 20, 30, ..., 200}$, applied LCS in both flavors and measured execution time. We repeated the measurements ten times to yield the final results. The entire procedure was repeated analogously for measuring memory consumption.

To limit the total runtime of the experiment, we defined a timeout of $30 "seconds"$ for each measurement. @lcs_times shows the number of timeouts for each query type and the strings lengths at which they occured.


#figure(
  caption: [Number of timeouts per string length for each query type (left) and time measurement as means an standard deviations of LCS (right)],
  grid(
    columns: 2,
    align: horizon,
    table(
      columns: 3,
      stroke: none,
      table.header([Strings lengths], [classic], [using-key]),
      table.hline(stroke: .5pt),
      [150], table.vline(stroke: .5pt), [1], table.vline(stroke: .5pt), [-],
      [170], [1], [-],
      [180], [4], [-],
      [190], [4], [1],
      [200], [4], [-],
    ),
    image("images/lcs_10_to_200.svg")
  )
) <lcs_times>

== Needleman-Wunsch

Brief intro and expectations.

=== Setup

For each measurement, we generated a random string consisting of the characters A, C, G and T, to mimic a DNA sequence. This string was directly used as the first argument. To get the second argument, we copied the first argument character-wise; however, with a probability of $30%$, a copying error would occur, selecting one random character from the available set. Because the same character could be selected with a probability of $25%$, the overall expected difference between the arguments is $75% dot 30% = 22.5%$.

The strings were of lengths $l in {10, 20, 30, ..., 300}$. For each length, ten pairs of strings were generated. We solved the alignment problem of each string pair using our two variants of the needleman-wunsch-algorithm explained in TODO and measured the execution times. 

=== Results

We removed two heavy outliers from the plot to make it more visually appealing. The outliers are listed in. 

#figure(
  caption: [The two outliers (left) and the rest of the time measurement of Needleman-Wunsch as mean and standard deviation (right)],
  grid(
    columns: 2,
    align: horizon,
    table(
        rows: 2,
        columns: 2,
        stroke: none,
        table.header([strings length], [time [s]]),
        table.hline(stroke: .5pt),
        [150], table.vline(stroke: .5pt), [191.01],
        [250], [271.78]
    ),
    image("images/needleman_err_cleaned.svg")
  )
)

== Drunken Bishop

=== Setup

We randomly generated arrays of hexadecimal numbers according to [CHAPTER THAT EXPLAINS THE ALGORITHM], with array length $l in {20, 40, 60, ..., 500}$. For each length, ten arrays were generated. Because the usual image dimensions of $17 times 9$ are too small for the generated array lengths, we scaled the image by a factor of $3$, giving images of dimension $51 times 27$. 

=== Results

#figure(
  caption: [Mean and standard deviation of time measurements for drunken-bishop. The left plot shows a comparison between the two used queries, while the right plot shows classic only, to visualize its shape.],
  grid(
    columns: 2,
    image("images/bishop_0227.svg"),
    image("images/bishop_classic_0227.svg")
  )
) <bishop_plot>


We can clearly see the increase in execution time in @bishop_plot for using-key, while classic appears to be staying constant at this scale. However we can see a linear increase in execution time when displaying the values for classic only.

#bibliography("../references.bib")


