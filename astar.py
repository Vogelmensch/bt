import subprocess 
import argparse
from measure.measure import Timer, Memory

STANDARD_HEURISTIC = '(select sqrt((fr.long - t.long)^2 + (fr.lat - t.lat)^2) from coords as fr join coords as t on fr.node_id = x and t.node_id = goal_node())'

# supply args from argparse
def perform_query(args):
    if args.standard_heuristic:
        heuristic = STANDARD_HEURISTIC
    elif args.heuristic:
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
        if not args.suppress_solution:
            print(script_name) # Print script name
            print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        # Add arguments with formatted python string
        query = query.format(graph=args.graph, start_node=args.start, goal_node=args.goal, heuristic=heuristic)

        # Use duckdb's interal time measurement utility
        if args.time:
            cmd = '.timer on'
        else:
            cmd = ''
        if args.memory:
            memory.start()

        # Execute query as subprocess
        res = subprocess.run(['duckdb', args.db, '-list', '-cmd', cmd], input=query, text=True, capture_output=True)

        if args.memory:
            memory.stop()
        
        if res.stderr != '':
            print('An error occured during query execution:')
            print(res.stderr)
            return
        
        out = res.stdout.replace('\n', '|').split('|')

        if (len(res.stdout) > 0):
            if args.time:
                path = out[5]
                length = out[6]
                timestr = out[7]
            else:
                path = out[2]
                length = out[3]
                timestr = None
        else:
            path, length, timestr = None, None, None

        nodes_count = len(path.split('->'))
            
        if not args.suppress_solution:
            if (len(res.stdout) == 0):
                print('Nothing found.')
            else:
                print(f'Path:\t {path} ({nodes_count} node{'' if nodes_count == 1 else 's'})')
                print(f'Length:\t {length}')

        if args.time and not args.suppress_solution:
            print(timestr)

        if args.memory:
            memory.print()

        # data to store to csv
        if args.file != 'DONT STORE':
            data = [script_name, args.graph, path, nodes_count]
            if args.time:
                timelist = timestr.split()
                timer.foreign_measurement(timelist[4:9:2]) # get time data out of timelist
                timer.write_csv(data)
            if args.memory:
                memory.write_csv(data)

        if not args.suppress_solution:
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

    parser.add_argument('-s', '--standard_heuristic', action='store_true', help='use standard heuristic file')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

    measure = parser.add_mutually_exclusive_group()
    measure.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    measure.add_argument('-m', '--memory', action='store_true', help='measure memory allocated during query execution')

    parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
    parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='measure time and store into FILE')

    parser.add_argument('-e', '--extend', type=str, action='extend', nargs='*', help='extend graph name with provided strings and perform MULTIPLE queries')
    parser.add_argument('-g', '--goals', type=int, nargs='+', help='Override provided goal with a list goals to perform MULTIPLE queries')
    parser.add_argument('-r', '--repeat', '--repeats', type=int, help='Repeat the entire query')

    args = parser.parse_args()

    header = ['script','graph','path','nodes_count']

    if args.time:
        timer = Timer('astar', args.file, header[:])
    if args.memory:
        memory = Memory('astar', args.file, header[:])

    if args.goals:
        goals = args.goals
    else:
        goals = [args.goal]

    if args.extend:
        extensions = args.extend
    else:
        extensions = ['']

    if args.repeat:
        repeats = args.repeat
    else:
        repeats = 1

    # Number of total repeats to show progress 
    total_repeats = repeats * len(goals) * len(extensions)
    current_repeat = 1

    for _ in range(repeats):
        # loop over graphs
        graph = args.graph
        for extension in extensions:
            args.graph = graph + extension
            # loop over goals
            for goal in goals:
                args.goal = goal
                if args.suppress_solution:
                    print(f'Performing query {current_repeat}/{total_repeats}', end='\r')
                current_repeat += 1
                perform_query(args)