import duckdb
import argparse
from measure.time import Timer

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform A* query.', 
        epilog='The graph needs to have the following schema: node_from: INT | node_to: INT | weight: INT')
    parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
    parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
    parser.add_argument('start', type=int, help='id of the start node')
    parser.add_argument('goal', type=int, help='id of the goal node')
    parser.add_argument('heuristic', type=str, nargs='?', help='optional custom heuristic function. Default: h(x) = 0')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

    parser.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    parser.add_argument('-T', '--time_suppress_solution', action='store_true', help='measure time and suppress print of solution')

    args = parser.parse_args()

    with duckdb.connect(args.db) as con:
        if args.heuristic:
            heuristic = args.heuristic
        else:
            # without a heuristic, A* reduces to dijkstra
            heuristic = 0

        scripts = []

        if args.using_key:
            scripts.append('queries/astar/using-key.sql')
        if args.classic:
            scripts.append('queries/astar/classic.sql')

        if len(scripts) == 0:
            scripts.append('queries/astar/using-key.sql')

        for script in scripts:
            script_name = script.split('/')[-1]
            print(script_name) # Print script name
            print('-' * len(script_name))

            with open(script) as f:
                query = f.read()

            if args.time or args.time_suppress_solution:
                timer = Timer()
                timer.start()

            res = con.sql(query.format(graph=args.graph, start_node=args.start, goal_node=args.goal, heuristic=heuristic)).fetchall()

            if args.time:
                timer.stop()
                
            if not args.time_suppress_solution:
                if (len(res) == 0):
                    print('Nothing found.')
                else:
                    print('Path:\t {}'.format(res[0][0]))
                    print('Length:\t {}'.format(res[0][1]))

            if args.time or args.time_suppress_solution:
                timer.print_elapsed()
            print()
            print()