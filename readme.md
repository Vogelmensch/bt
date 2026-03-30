# USING KEY testing queries

Queries for testing DuckDB's revolutionary new approach for writing recursive CTEs.

## Prerequisites

Get [DuckDB 1.4.4](https://duckdb.org/) via 

```
curl https://install.duckdb.org | DUCKDB_VERSION=1.4.4 sh
```

There are known issues with `DuckDB 1.5` and later versions; when using those, you're on your own.

Make sure to add the correct version of DuckDB to your `PATH`.

You also need [Python](https://www.python.org/).


## Queries

The queries are located in `queries/`. You can examine the pure SQL right there.
To use our testing-suite, run the respective Python-File in the repo's root-directory: `astar.py`, `lcs.py`, `needleman.py` and `bishop.py`. 

Every query implements the following flags.
```
  -h, --help            show help message and exit
  -u, --using_key       USING KEY
  -c, --classic         use classic CTE
  -t, --time            measure process time for query execution
  -m, --memory          measure memory allocated during query execution
  -x, --suppress_solution
                        suppress print of solution
  -f, --file [FILE]     store measured data into FILE
  --repeat, --repeats REPEAT
                        repeat the entire query
  --timeout TIMEOUT     timeout for each query in seconds
  --script, --scripts [SCRIPT ...]
                        manually provide script to read from
```

Every query uses additional, individual flags. The explanations below only show the *required* inputs. For a full list of arguments, use the option `-h` to display the help document for a query.

## A*
Find the shortest path between two nodes in a graph. It expands Dijkstra's Algorithm by using a heuristic function to estimate the distance to the goal node.

```
python astar.py db graph start goal
```

The `graph` has to be defined in a DuckDB-`.db`-file, provided as `db`. It has to implement the following schema:
```SQL
CREATE TABLE graph (
    node_from INTEGER,
    node_to INTEGER,
    weight INTEGER,
    h DOUBLE 
);
```

Example:
```
> python astar.py graphs/graphs.db simple 0 6
using-key.sql
-------------
Path: 0 -> 1 -> 3 -> 4 -> 5 -> 6 (6 nodes)
Total Weight: 5
7 nodes expanded
7 items in final table
```

## Longest Common Subsequence (LCS)

Find the longest subsequence common to two input strings.

```
python lcs.py [-s STRINGS [STRINGS ...] | -r RANDOM [RANDOM ...]]
```

You have to choose between one of two options:
1. Provide your own input with `-s STRING_1a STRING_1b STRING_2a STRING_2b ...`. You can define an arbitrary amount of string-tuples. The two strings of a tuple get compared to each other.
2. Generate random strings with `-r LENGTH_1 LENGTH_2 ...`, providing the length of the generated strings. For each LENGTH, one string-tuple is being generated.


Examples:
```
> python lcs.py -s 'never gonna give you up' 'never gonna let you down' 
using-key.sql
-------------
'never gonna e you '
600 items in final table
```

```
> python lcs.py -r 10 20
String1: goluhezsyn
String2: yqatlurdgi

using-key.sql
-------------
lu
121 items in final table

String1: fmgynxkvztoeajwtqdrj
String2: jbrenxfiynytokmzhbig

using-key.sql
-------------
fynto
fynkz
441 items in final table
```

## Drunken Bishop

Create and ASCII-image based on a string of hexadecimal numbers.
```
bishop.py [-s FINGERPRINT [FINGERPRINT ...] | -r RANDOM [RANDOM ...]]
```
The argument `fingerprint` is a string of hexadecimal numbers, separated by `:`.

You have to choose between one of two options:
1. Provide your own input with `-s FINGERPRINT_1 FINGERPRINT_2 ...`. You can define an arbitrary amount of fingerprints.
2. Generate random strings with `-r LENGTH_1 LENGTH_2 ...`, providing the length of the generated strings. For each LENGTH, one string-tuple is being generated.

Example:
```
> python bishop.py -s fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7
using-key.sql
-------------
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

```
> python bishop.py -r 30
Generated 4c:56:34:f0:50:35:a7:ba:2d:6e:11:f9:3a:1d:a8:7b:39:a9:91:58:44:91:93:b1:a1:32:30:95:7b:05
using-key.sql
-------------
+-----------------+
|  o.....BO=.o .  |
|   o.  o=* . +   |
|    o...=....    |
|    .o.=  o.     |
|     .  + .+     |
|       o .ooo    |
|      . o.o*..   |
|        .oO..    |
|        o=.o     |
+-----------------+
```

## Needleman-Wunsch

Align two strings. Most commonly used to align DNA sequences.

```
> python needleman.py [-s STRINGS [STRINGS ...] | -r RANDOM [RANDOM ...]] [-p PROBABILITY]
```

You have to choose between one of two options:
1. Provide your own input with `-s SEQUENCE_1a SEQUENCE_1b SEQUENCE_2a SEQUENCE _2b ...`. You can define an arbitrary amount of tuples.
2. Generate random DNA sequences (i.e. strings consisting of the letters G, A, C and T) with `-r LENGTH_1 LENGTH_2 ...`, providing the length of the generated sequences. For each LENGTH, one string-tuple is being generated. When using this option, you also need to provide a value for `-p`. This value defines the probability for each letter of the generated second sequence to differ from the corresponding letter in the first sequence.

Example:
```
> python needleman.py -s GCATGCG GATTACAS
using-key.sql
-------------
GCA-TGCG-
G-ATTACAS

GCAT-GCG-
G-ATTACAS

GCATG-CG-
G-ATTACAS

GCAT-GC-G
G-ATTACAS

GCA-TGC-G
G-ATTACAS

GCATG-C-G
G-ATTACAS
```

```
> python needleman.py -r 10 -p 0.5
String1: AGGCTCCATT
String2: TTACTACAGT

using-key.sql
-------------
AGGCTCCATT
TTACTACAGT

AGGCTCCATT
A--CTACAGT
```

## Knapsack

TODO

# Measurements

A protocol of inputs for the different algorithms and my observations.

## A*

...

## LCS

```bash
python lcs.py -s 'Never gonna give you up' 'Never gonna let you down'
```
- Only slight differences in execution time are observable


```bash
python lcs.py -s 'Houston, we have a problem' 'Oberpfaffenhofen, wir haben ein Problem'
```

- My Laptop (Acer Spin 5) finds the solution in... 
    - USING KEY: ~330 ms
    - Classic query: > 10 min

## Bishop

```bash
python bishop.py -s 4 -r 400
```

- My Laptop (Acer Spin 5) finds the solution in... 
    - USING KEY: 10 s
    - Classic query: 180 ms 🤨


# Sources
Graph from 9th DIMACS Implementation Challenge:
```https://www.diag.uniroma1.it/challenge9/download.shtml```


# Directly use finder in astar with
```bash
cat queries/astar/finder.sql | duckdb usa.db -list | tail -n 1
```