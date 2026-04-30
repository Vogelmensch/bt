#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/touying:0.7.1": *

== Introduction

#grid(
    columns: 2,
    gutter: .5cm,
    [classic], [using-key],
    [```sql
    WITH RECURSIVE pow2(n, x) AS (
        ...
    )
    ```],
    [```sql
    WITH RECURSIVE pow2(i, n, x) USING KEY (i) AS (
        ...
    )
    ```],
    pause,
    [
    How do the two variants compare in practice?
    - Implementation: What do the queries look like?
    - Performance: Runtime and memory usage
    ],
    [
        Implemented four algorithms:
        - A\* search
        - LCS
        - Needleman-Wunsch
        - Drunken Bishop
    ]
)


