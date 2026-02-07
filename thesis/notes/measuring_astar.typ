Okay, the question is: What is the best way to measure the performance? That is, what should I compare the performance against? What is the x-value?

I originally started with the path length. Which is stupid, because a short path can take a long time to find. Then, I went over to total weight. Which was slightly better but still not perfect, because of differences in "density". Then I took the count of expanded nodes, which is also not perfect because the same node can be visited multiple times during execution. So now, I'm at the total count of all visited nodes, counting the same node multiple times if it has been visited multiple times.

This is easy to measure in classic, but using-key overwrites old values, so I cannot simply count the number of entries in the Union Table. Maybe I have to carry a counter. But would this impact performance? It shouldn't, but maybe it does.


== Measurements from 10.01.2026

I generated a graph with `generators/graph.py`. The graph has the following attributes:
- 1,000 nodes
- 3,000 edges; those are distributed randomly over the nodes (see graph generation)
- weights of 1 to 100

Then, I ran `astar.py` over the graph, choosing `start_node = 1` and *every node from 1 to 1000* as goal. With this, I measured time and memory.

I chose this approach because it has reasonable excecution time on my machine while gnerating a large dataset.

Exact commands:
`python generators/graph.py -w 100 -c graphs.db -n thousand -p 1000 3000`
`python astar.py graphs.db thousand 1 1 --goals (for i in (seq 10000); echo$i; end) -uctx -f measure/astar_thousand_time.csv`