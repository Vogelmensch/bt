# USING KEY testing queries

Queries for testing DuckDB's revolutionary new approach for writing recursive CTEs.

## Usage

### Installation
1. Clone the repository
2. Install the DuckDB Python package via `pip install duckdb`
3. In the root directory, use the provided `.py`-files to run the queries

Every query implements the following flags:
```
  -h, --help     show help message and exit
  -c, --classic  use classic CTE (without USING KEY)
```
The following queries and implemented:

### A*
Find the shortest path between two nodes in a graph. It expands Dijkstra's Algorithm by using a heuristic function to estimate the distance to the goal node.

```
python astar.py [-h] [-c] db graph start goal [heuristic]
```


The graph has to be defined in a `.db`-file. It has to implement the following schema:
```SQL
CREATE TABLE graph (
    node_from INTEGER,
    node_to INTEGER,
    weight INTEGER
);
```

To define a custom heuristic function, pass the according SQL-code as an argument for `[heuristic]`. It standards to `h(x) = 0`, implementing Dijkstra's Algorithm. 

Example:
```
> python astar.py example.db simple 0 6
USING KEY

Path:    0 -> 1 -> 3 -> 5 -> 6
Length:  5
```

### Longest Common Subsequence

Find the longest substring common to both `string1` and `string2`.

```
lcs.py [-h] [-c] string1 string2
```


Example:
```
> python lcs.py 'Never gonna give you up' 'Never gonna let you down'
USING KEY
Never gonna e you 

```

### Drunken Bishop

Create and ASCII-image based on a string of hexadecimal numbers.
```
bishop.py [-h] [-p] [-c] [-s SCALE] fingerprint
```
The argument `fingerprint` is a string of hexadecimal numbers, separated by `:`.

Example:
```
> python bishop.py fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7
USING KEY
+-----------------+
|       .=o.  .   |
|     . *+*. o    |
|      =.*..o     |
|       o + ..    |
|        + o.     |
|         o  .    |
|          .  . . |
|              o .|
|               o.|
+-----------------+
```

## Unit testing

Unit tests are defined in `/tests`. Run the `.py`-files to test the queries directly. Additional tests can be defined at the bottom of the `.py`-files, marked with an according comment.

Example:
```
python tests/astar.py
```


## Measurements

A protocol of inputs for the different algorithms and my observations.

### A*

Works out of the box, but no performance difference is observable:
```bash
python astar.py example.db simple 0 6
```

Requires an additional ![graph](https://repository.surfsara.nl/datasets/cwi/lsqb), but performance difference is observable. 

The graph `person_knows_person` has 
- 162,059 nodes
- 7,273,036 edges
- a mean branching factor of ~45.

```bash
python astar.py graphs.db person_knows_person 14 2199023256081
```

- My Laptop (Acer Spin 5) finds the solution in... 
    - USING KEY: 1m 18s
    - Classic query: 40s 🤨


Observe memory use of the following query.

```bash
python astar.py graphs.db person_knows_person 14 37383395527996
```

### LCS

```bash
python lcs.py 'Houston, we have a problem' 'Oberpfaffenhofen, wir haben ein Problem'
```

- My Laptop (Acer Spin 5) finds the solution in... 
    - USING KEY: ~330 ms
    - Classic query: > 10 min

### Bishop

```bash
python bishop.py -s 4 -r 400
```

- My Laptop (Acer Spin 5) finds the solution in... 
    - USING KEY: 10 s
    - Classic query: 180 ms 🤨