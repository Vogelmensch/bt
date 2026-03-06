= Measuring

For all algorithms presented in TODO, we measured execution time and memory consumption of both variants, using-key and classic. In this chapter, we explain our methods and present and interpret the results using comparative plots.

To measure execution time, we used DuckDBs internal SQL timer, which measures execution time for statements separated by `;`. The timer can be turned on by calling the dot command `.timer on` @duckdb_timer. For each statement, the timer returns real time, user time and system time, respectively. We always present the sum of user time and system time in our results.

To measure memory consumption, we used the GNU Project's `time` command as shown in @gnu_time_command. The option `-f %M` returns the "Maximum resident set size of the process during its lifetime" @gnu_time. 

#figure(
  caption: [Measuring memory consumption using GNU's `time`. For `[OPTIONS]`, we entered appropriate CLI-options, depending on the query we evaluated.],
  [
    ```bash
    /usr/bin/time -f %M duckdb [OPTIONS]
    ```
  ]
) <gnu_time_command>


All measurements were taken on the same machine, the specifications for which are shown in @specs.

#figure(
  caption: [Machine specifications],
  table(
    columns: 2,
    stroke: none,
    table.header([*Item*], table.vline(stroke: .5pt), [*Value*]),
    table.hline(stroke: .5pt),
    [Operating System], [CachyOS x86_64],
    [CPU], [AMD Ryzen 7 7800X3D (16) @ 5.053GHz],
    [Memory], [32 GB],
    [Kernel], [6.18.13-arch1-1],
    [DuckDB version], [v1.4.4 (Andium) 6ddac802ff]
  )
) <specs>


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
      [mean edge weight],[1273],
      table.hline(stroke: .5pt),
      [stdev of edge weight],[855],
    ),

    image("images/nyc_roads.svg")
  )
) <central_park_facts>

Then, we took the graph of California and Nevada and chose `node_id = 1791103` as the start node, which lies within Las Vegas. For each distance $d in {500, 1000, 1500, ..., 10000}$, we randomly selected five points with h-values close the the respective distance as goal nodes, resulting in 100 goal nodes. @vegas_facts shows an overview over this subgraph.

#figure(
  caption: [Las Vegas graph in numbers (left) and visually represented as a map (right) showing all edges within a 10 km radius around the start node. The red dot represents the starting position for A\*, the magenta dots represent the randomly chosen goal nodes. ],
  grid(
    columns: 2,
    rows: 2,
    column-gutter: 15pt,
    align: horizon,
    table(
      columns: 2,
      stroke: none,
      [number of nodes],table.vline(stroke: .5pt), [15890],
      table.hline(stroke: .5pt),
      [number of edges],[42130], 
      table.hline(stroke: .5pt),
      [mean edge weight],[1347.5],
      table.hline(stroke: .5pt),
      [stdev of edge weight],[1071],
    ),

    image("images/vegas_10_km.svg")
  )
) <vegas_facts>

=== Results

@astar_nyc shows the results for time and memory measurements on the graph of New York City. We can clearly see that the execution time follows a linear distribution for both queries, with the values for using-key increasing more slowly. TODO shows the coefficients for linear fits. The difference would then be TODO.

It is noticeable that measured times separate into two distinct branches. While we do not have a definitive explanation for this behaviour, we suspect the nature of the graph to be the reason for it. TODO: further

@astar_vegas shows the results for the graph of Las Vegas. 

#figure(
  caption: [Execution time (left) and memory usage (right) of A\* on the graph of New York City],
  grid(
    columns: 2,
    image("images/astar_3_km.svg"),
    image("images/astar_nyc_memory.svg")
  )
) <astar_nyc>

#figure(
  caption: [Execution time (left) and memory usage (right) of A\* on the graph of Las Vegas],
  grid(
    columns: 2,
    image("images/astar_vegas.svg"),
    image("images/astar_vegas_memory.svg")
  )

) <astar_vegas>

#figure(
  caption: [Coefficients of polynomial fits for memory measurements of A\*],
  table(
    columns: 6,
    stroke: none,
    table.header([*Graph*], [*Algorithm*], [*Unit*], table.vline(stroke: .5pt), [*$x^2$*], [*$x$*], [*$1$*]),
    table.hline(stroke: .5pt),
    [NYC], [classic], [MB], [$1.78 dot 10^(-5)$], [$0.028$], [$266.8$],
    [NYC], [using-key], [MB], [-], [$0.003$], [$262$],
    [Vegas], [classic], [GB], [$3 dot 10^(-8)$], [$3.243 dot 10^(-5)$], [$0.763$],
    [Vegas], [using-key], [GB], [-], [$2.078 dot 10^(-6)$], [$0.682$]
  )
) <astar_fit>



== LCS

=== Setup

We wrote a random string generator to provide the input for LCS. The generator used all 26 lower-case characters from the english alphabet. For each measurement, we generated two independent strings of equal lengths $l in {10, 20, 30, ..., 200}$, applied LCS in both flavors and measured execution time and memory usage. We repeated the measurements ten times to yield the final results. 

To limit the total runtime of the experiment, we defined a timeout of $5 "minutes"$ for each measurement. This limit has been reached for classic, twice for $l = 180$ and once for $l = 190$.


=== Results

#figure(
  caption: [Mean and standard deviation of LCS measurements for time (left) and memory consumption (right)],
  grid(
    columns: 2,
    image("images/lcs_10_to_200.svg"),
    image("images/lcs_memory_10_to_200.svg")
  )
) <lcs_results>

== Needleman-Wunsch

Brief intro and expectations.

=== Setup

For each measurement, we generated a random string consisting of the characters A, C, G and T, to mimic a DNA sequence. This string was directly used as the first argument. To get the second argument, we copied the first argument character-wise; however, with a probability of $30%$, a copying error would occur, selecting one random character from the available set. Because the same character could be selected with a probability of $25%$, the overall expected difference between the arguments is $75% dot 30% = 22.5%$.

The strings were of lengths $l in {10, 20, 30, ..., 300}$. For each length, ten pairs of strings were generated. We solved the alignment problem of each string pair using our two variants of the needleman-wunsch-algorithm explained in TODO and measured the execution times. We used a timeout of 60 seconds.

=== Results

@needleman_timeouts lists the timeouts we encountered. We did not represent them in the plots in @needleman_results.

For the respective query, both execution time and memory usage appear to follow a "main curve" on which most values are located. Looking at those main curves, both values increase more rapidly for classic than those for using-key. We also observe a handful of values falling above the main curves, especially for larger string lengths, and mostly for classic. 


#figure(
  caption: [Number of timeouts for the measurement of Needleman-Wunsch. A query timed out after time $t > 60 s$.],
  table(
    columns: 3,
    stroke: none,
    table.header([*String Length*], [*Script*], [*Timeouts*]),
    table.hline(stroke: 0.5pt),
    [240], [classic], [1],
    [250], [classic], [1],
    [260], [classic], [1],
    [260], [using-key], [1],
    [290], [classic], [2],
    [300], [classic], [3]
  )
) <needleman_timeouts>

#figure(
  caption: [Measured time (left) and memory consumption (right) for Needleman-Wunsch.],
  grid(
    columns: 2,
    image("images/needleman_march_time.svg"),
    image("images/needleman_march_memory.svg")
  )
) <needleman_results>

== Drunken Bishop

=== Setup

We performed two measurements. First, we randomly generated arrays of hexadecimal numbers according to [CHAPTER THAT EXPLAINS THE ALGORITHM], with array length $l in {20, 40, 60, ..., 500}$. For each length, ten arrays were generated. Because the usual image dimensions of $17 times 9$ are too small for the generated array lengths, we scaled the image by a factor of $3$, giving images of dimension $51 times 27$. 


=== Results

@bishop_scale3 shows the results for the first measurements. We see that classic massively outperforms using-key in both metrics. 

#figure(
  caption: [Execution time (left) and memory usage (right) of drunken bishop.],
  grid(
    columns: 2,
    image("images/bishop_0306_time.svg"),
    image("images/bishop_0306_memory.svg")
  )
) <bishop_scale3>


#bibliography("../references.bib")


