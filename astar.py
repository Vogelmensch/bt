import duckdb
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform A* query.', 
        epilog='The graph needs to have the following schema: node_from: INT | node_to: INT | weight: INT')
    parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
    parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
    parser.add_argument('start', type=int, help='id of the start node')
    parser.add_argument('goal', type=int, help='id of the goal node')
    parser.add_argument('heuristic', type=str, nargs='?', help='optional custom heuristic function. Default: h(x) = 0')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')
    args = parser.parse_args()

    with duckdb.connect(args.db) as con:
        if args.heuristic:
            heuristic = args.heuristic
        else:
            # without a heuristic, A* reduces to dijkstra
            heuristic = 0

        if args.classic:
            script = 'queries/astar_classic.sql'
            print('classic query')
        else:
            script = 'queries/astar.sql'
            print('USING KEY')

        with open(script) as f:
            query = f.read()

        res = con.sql(query.format(graph=args.graph, start_node=args.start, goal_node=args.goal, heuristic=heuristic)).fetchall()

        print()
        print('Path:\t {}'.format(res[0][0]))
        print('Length:\t {}'.format(res[0][1]))