import duckdb
import argparse
from measure.measure import Timer

# supply args from argparse
def perform_query(args, timer):
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

            if args.time:
                timer.start()

            res = con.sql(query.format(graph=args.graph, start_node=args.start, goal_node=args.goal, heuristic=heuristic)).fetchall()

            if args.time:
                timer.stop()

            if (len(res) > 0):
                path, length = res[0]
            else:
                path, length = None, None
                
            if not args.suppress_solution:
                if (len(res) == 0):
                    print('Nothing found.')
                else:
                    print('Path:\t {}'.format(path))
                    print('Length:\t {}'.format(length))

            if args.time:
                timer.print_elapsed()

                # data to store to csv
                if args.file != 'DONT STORE':
                    data = [script_name, args.graph, path, length]
                    timer.write_csv(data)

            print()
            print()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform A* query.', 
        epilog='''
        The graph needs to have the following schema: node_from: INT | node_to: INT | weight: INT

        To perform multiple queries and store them all into one csv-file, provide -e / --extend. 
        The provided strings extend the graph name.
        ''')
    parser.add_argument('db', type=str, help='path to .db-file holding the graph(s)')
    parser.add_argument('graph', type=str, help='name of the graph to perform the query on')
    parser.add_argument('start', type=int, help='id of the start node')
    parser.add_argument('goal', type=int, help='id of the goal node')
    parser.add_argument('heuristic', type=str, nargs='?', help='optional custom heuristic function. Default: h(x) = 0')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

    parser.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
    parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='measure time and store into FILE')

    parser.add_argument('-e', '--extend', type=str, action='extend', nargs='*', help='extend graph name with provided strings and perform MULTIPLE queries')

    args = parser.parse_args()

    if args.file != 'DONT STORE' and not args.time:
        print('REMEMBER TO PROVIDE -t TO MEASURE TIME')
        print()


    timer = Timer('astar', args.file, header=['script','graph','path','length', 'time'])

    if args.extend:
        graph = args.graph
        for idx, extension in enumerate(args.extend):
            print(f'{idx+1}/{len(args.extend)}')
            args.graph = graph + extension
            perform_query(args, timer)
    else:
        perform_query(args, timer)