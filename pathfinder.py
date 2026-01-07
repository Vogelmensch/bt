import argparse
import duckdb

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Find some path in graph'
    )
    parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
    parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
    parser.add_argument('start_node', type=int, help='Node to start expanding from')
    parser.add_argument('node_count', type=int, help='Number of nodes to expand')

    args = parser.parse_args()

    with duckdb.connect(args.db) as con:
        script = 'queries/astar/finder.sql'
        with open(script) as f:
            query = f.read()
        query = query.format(max_length=args.node_count, start_node=args.start_node, graph=args.graph)

        res = con.sql(query).fetchall()

        print(res[0][0])