#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  languages: (
    sql: (name: "SQL", icon: "🦆", )
  )
)
#codly-enable()

= Measurements <measuring>

For all algorithms presented in this thesis, we measured execution time and memory consumption of both CTE variants, using-key and classic. In this chapter, we explain our methods and present and interpret the results using comparative plots.

To measure execution time, we used DuckDBs internal SQL timer, which measures execution time for statements separated by semicolons. The timer can be turned on by calling the dot command `.timer on` @duckdb_timer. For each statement, the timer returns real time, user time and system time. We always present the sum of user time and system time in our results,

$
  "Execution time" = "user time" + "system time".
$

To measure memory consumption, we used the GNU Project's `time` command,
#no-codly(
  ```bash
/usr/bin/time -f %M duckdb [OPTIONS]
```
)
The option `-f %M` returns the "Maximum resident set size (RSS) of the process during its lifetime" @gnu_time, which is the amount of memory held in RAM @rss.

All measurements were taken on the same machine, the specifications for which are shown in @specs.

#figure(
  caption: [Specifications of the machine the measurements were taken on.],
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


== A\* <measure_astar>

=== Setup

We chose two graphs of US cities from the "9th DIMACS Implementation Challenge"@dimacs as basis for the first benchmark. In those graphs, the nodes correspond to intersections, while the edges correspond to roads between them. The edge weights come in two flavors: Distance in meters and average travel time in seconds, where the latter takes the type of road into account. A separate table contains coordinates for each node. 

A graph representing a physical map is an obvious choice for testing A\* because we can use the physical distance between a node and the goal node as the heuristic function. Naturally, we chose the distance graph for our measurements. 

First, we took the graph of New York City.
As the start node, we chose `node_id = 189104`, which lies within central park. From there, we selected all nodes within a $3 "km"$ radius as goal nodes, $1526$ in number.  We ran A\* on these pairings, measuring execution time and memory consumption. @central_park_facts shows an overview over this subgraph to get a rough picture of the region. 

#figure(
  kind: image,
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

    image("images/nyc_roads.png")
  )
) <central_park_facts>

Then, we took the graph of California and Nevada and chose `node_id = 1791103` as the start node, which lies within Las Vegas. For each distance $d in {500, 1000, 1500, ..., 10000}$, we randomly selected five points with h-values close the the respective distance as goal nodes, resulting in 100 goal nodes. @vegas_facts shows an overview over this subgraph.

#figure(
  kind: image,
  caption: [Las Vegas graph in numbers (left) and visually represented as a map (right) showing all edges within a 10 km radius around the start node. The red dot represents the starting position for A\*, the magenta dots represent the randomly chosen goal nodes.],
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

    image("images/vegas_10_km.png")
  )
) <vegas_facts>

=== Heuristic function for air distance <heuristic>

@map_heuristic shows the macro we used to create heuristic values for the graphs. As mentioned above, the physical distance to the goal node is an intuitive choice for a heuristic that also meets both desired properties of heuristc functions explained in @astar_basics. Because of the earth's curvature, we need to use spherical geometry, which the `spatial` extension provides @spatial. The function `st_point(lat, long)` creates "geometry points" from coordinates `lat` and `long`. `st_distance_spheroid` then calculates the distance between those points using "an ellipsoidal model of the earths surface". We cast the resulting `DOUBLE` to `INTEGER` for performance reasons. 

#figure(
  caption: [Heuristic function we used on map graphs for our measurements.],
  [
    ```sql
    CREATE MACRO h(x) AS (
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
    ```
  ]
) <map_heuristic>

=== Results

We plot the number of expanded nodes on the x-axis.

@astar_nyc shows the results for time and memory measurements on the graph of New York City. We can clearly see that the execution time follows a linear distribution for both queries, with the values for using-key increasing more slowly.
It is noticeable that measured times separate into two distinct branches. While we do not have a definitive explanation for this behaviour, we suspect the nature of the graph to be the reason for it. The graph is dominated by two large empty regions, one of which being central park, the other being the East River. Nodes lying beyond those regions may take longer to be reached because A\* first has to go "around" the regions.

As for memory usage, using-key is linear with a slight incline, while classic neatly follows a quadratic distribution.

@astar_vegas shows the results for the graph of Las Vegas. Again, execution time is linear for both queries, with using-key being slightly faster for all goals. The phenomenon of distinct branches for each query does not occur here. 

Memory usage on Las Vegas also neatly follows a quadratic distribution. @astar_fit shows the coefficients for the fits on the memory meausrements.

#figure(
  caption: [Execution time (left) and memory usage (right) of A\* on the graph of New York City.],
  grid(
    columns: 2,
    image("images/astar_3_km.svg"),
    image("images/astar_nyc_memory.svg")
  )
) <astar_nyc>

#figure(
  caption: [Execution time (left) and memory usage (right) of A\* on the graph of Las Vegas.],
  grid(
    columns: 2,
    image("images/astar_vegas.svg"),
    image("images/astar_vegas_memory.svg")
  )

) <astar_vegas>

#figure(
  caption: [Coefficients of polynomial fits for memory measurements of A\*.],
  table(
    columns: 6,
    stroke: none,
    table.header([*Graph*], [*Script*], [*Unit*], table.vline(stroke: .5pt), [*$x^2$*], [*$x$*], [*$1$*]),
    table.hline(stroke: .5pt),
    [NYC], [classic], [MB], [$1.78 dot 10^(-5)$], [$0.028$], [$266.8$],
    [NYC], [using-key], [MB], [-], [$0.003$], [$262$],
    [Vegas], [classic], [GB], [$3 dot 10^(-8)$], [$-3.243 dot 10^(-5)$], [$0.763$],
    [Vegas], [using-key], [GB], [-], [$2.078 dot 10^(-6)$], [$0.682$]
  )
) <astar_fit>



== LCS <measure_lcs>

=== Setup

We wrote a random string generator to provide input for LCS. The generator used all 26 lower-case characters from the english alphabet. For each measurement, we generated two independent strings of equal lengths $l in {10, 20, 30, ..., 200}$, applied LCS in both CTE variants and measured execution time and memory usage. We repeated the measurement ten times.

To limit the total runtime of the experiment, we defined a timeout of $5 "minutes"$ (real time) for each measurement. This limit has been reached for classic, twice for $l = 180$ and once for $l = 190$.


=== Results

@lcs_results shows the results. For both time and memory, using-key flies well under the radar when compared to classic. Also, the data for classic is much more widely scattered; no clear pattern is emerging, such that fitting the data does not seem appropriate here. To quantify the data, @lcs_stats shows mean $mu$ and standard deviation $sigma$ for all measurements.
These results show using-key's performance to be both, better on average, and less uncertain. 

#figure(
  caption: [Mean $mu$ and standard deviation $sigma$ of LCS measurements, rounded to one decimal.],
  table(
    columns: 5,
    rows: 2,
    stroke: none,
    table.header([*script*], table.vline(stroke: .5pt), [*$mu("time") [s]$*], [*$sigma("time") [s]$*], [*$mu("memory") ["GB"]$*], [*$sigma("memory") ["GB"]$*]),
    table.hline(stroke: .5pt),
    [classic.sql], [$78.6$], [$261.5$], [$1.6$], [$3.3$],
    [using-key.sql], [$4.8$], [$6.7$], [$0.4$], [$0.4$]
  )
) <lcs_stats>

#figure(
  caption: [Execution time (left) and memory consumption (right) of LCS. In contrast to the other plots, we layed using-key above classic here for clarity.],
  grid(
    columns: 2,
    image("images/lcs_10_to_200_time_no_err.svg"),
    image("images/lcs_10_to_200_memory_no_err.svg")
  )
) <lcs_results>

== Needleman-Wunsch <measure_needleman>

=== Setup

For each measurement, we generated a random string consisting of the characters A, C, G and T, to mimic a DNA sequence. This string was directly used as the first argument. To get the second argument, we copied the first argument character-wise; however, with a probability of $30%$, a copying error would occur, selecting one random character from the available set. Because the same character could be selected with a probability of $25%$, the overall expected difference between the arguments is $75% dot 30% = 22.5%$.

The strings were of lengths $l in {10, 20, 30, ..., 300}$. For each length, ten pairs of strings were generated. We solved the alignment problem of each string pair using our two variants of the needleman-wunsch-algorithm, using a timeout of 60 seconds (real).

=== Results

@needleman_timeouts lists the timeouts we encountered. We did not represent them in the result plots in @needleman_results.

For each query, both execution time and memory usage appear to follow a "main curve" on which most values are located. Looking at these main curves, both values increase more rapidly for classic than for using-key. We also observe a handful of values falling above the main curves, especially for longer strings, and mostly for classic. However, no values fall under the main curves, suggesting a lower limit. We applied fits on the minimal values of each string length to model the shape of this lower limit. @needleman_fit shows the coefficients of these fits.
@needleman_stats shows mean $mu$ and standard deviation $sigma$ of the measurements.

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

#figure(
  caption: [Mean $mu$ and standard deviation $sigma$ of Needleman-Wunsch measurements, rounded to one decimal.],
  table(
    columns: 5,
    rows: 2,
    stroke: none,
    table.header([*script*], table.vline(stroke: .5pt), [*$mu("time") [s]$*], [*$sigma("time") [s]$*], [*$mu("memory") ["GB"]$*], [*$sigma("memory") ["GB"]$*]),
    table.hline(stroke: .5pt),
    [classic], [$45.2$], [$79.8$], [$0.7$], [$0.9$],
    [using-key], [$7.0$], [$10.4$], [$0.4$], [$0.5$]
  )
) <needleman_stats>

#figure(
  caption: [Coefficients of fits for minimal values of Needleman-Wunsch measurements.],
  table(
    columns: 6,
    stroke: none,
    table.header([*Measure*], [*Script*], table.vline(stroke: .5pt), [*$x^3$*], [*$x^2$*], [*$x$*], [*$1$*]),
    table.hline(stroke: .5pt),
    [time [s]], [classic], $1.5 dot 10^(-5)$, $-3.6 dot 10^(-3)$, $0.3$, $-5.5$,
    [time [s]], [using-key], [-], [-], $5.7 dot 10^(-2)$, $-3.4$,

    [memory [GB]], [classic], $2.8 dot 10^(-8)$, $-1.0 dot 10^(-6)$, $1.5 dot 10^(-3)$, $0.2$,
    [memory [GB]], [using-key], [-], [-], $9.6 dot 10^(-4)$, $0.2$
  )
) <needleman_fit>



== Drunken Bishop <measure_bishop>

=== Setup

We randomly generated arrays of hexadecimal numbers with array length $l in {200, 400, ..., 5000}$. For each length, ten arrays were generated. Because the usual image dimensions of $17 times 9$ are too small for the generated array lengths, we scaled the image by a factor of $3$, giving images of dimension $51 times 27$. 

Additionally to the two queries specifically explained in @bishop_classic_chapter and @bishop_using-key_chapter, we measured each variant using the bit-pair representation of the respective other to demonstrate the significance of the representation. We set a timeout of $10$ seconds (real).

=== Results

@bishop_scale3 shows the resulting plots as mean and standard deviation for each fingerprint length. With some uncertainty, all measurements follow linear distributions, except for using-key with bitlists, which quickly exceeds the scope of the measurement.
@bishop_slopes shows the slopes of linear fits for the other three queries.
We can see how classic outperforms using-key. Also, while the influence of the bit-pair representation on memory usage of classic seems minor, the impact on runtime is rather apparent.



#figure(
  caption: [Execution time (left) and memory usage (right) of drunken bishop.],
  grid(
    columns: 2,
    image("images/bishop_0315_all_time.svg"),
    image("images/bishop_0315_all_memory.svg")
  )
) <bishop_scale3>

#figure(
  caption: [Slope of linear fit for time  and memory measurements, rounded to two decimals.],
  table(
    columns: 4,
    stroke: none,
    table.header([*Query*], [*Bit-pair representation*], [*$Delta"time" [s/10^3]$*], [*$Delta"memory" ["MB"/10^3]$*]),
    table.hline(stroke: 0.5pt),
    [classic], [list], [$0.68$], [$9.78$],
    [classic], [table], [$2.06$],[$8.85$],
    [using-key],[table],[$3.34$],[$15.45$],
  )
) <bishop_slopes>

