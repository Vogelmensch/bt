import duckdb
import argparse
from generators.rstring import generate
from measure.time import Timer

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform lcs query.')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c', '--classic', action='store_true', help='use classic CTE')

    parser.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    parser.add_argument('-T', '--time_suppress_solution', action='store_true', help='measure time and suppress print of solution')
    parser.add_argument('-f', '--file', type=str, help='measure time and store result in FILE')

    parser.add_argument('-n', '--repeat', type=int, help='repeat REPEAT times')
    
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-s', '--strings', type=str, nargs=2, help='String arguments to compare')
    group.add_argument('-r', '--random', type=int, nargs=2, help='use randomly generated strings of given lengths')

    args = parser.parse_args()

    # Use provided strings
    # If -r is being used, strings get assigned below
    if args.strings:
        string1 = args.strings[0]
        string2 = args.strings[1]

    scripts = []

    if args.using_key:
        scripts.append('queries/lcs/using-key.sql')
    if args.classic:
        scripts.append('queries/lcs/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/lcs/using-key.sql')

    if args.file:
        timer = Timer()
        timer.connect(args.file, first_arg='length')
    elif args.time or args.time_suppress_solution:
        timer = Timer()
    else:
        timer = None

    if args.repeat:
        repeats = args.repeat
    else:
        repeats = 1

    for i in range(repeats):
        print(f'Running queries {i+1}/{repeats}')

        # Generate random strings
        if args.random:
            string1 = generate(args.random[0])
            string2 = generate(args.random[1])
            if not args.time_suppress_solution and not args.file:
                print('String1: {}\nString2: {}'.format(string1, string2))
                print()

        # Run all queries with the same inputs
        for script in scripts:
            script_name = script.split('/')[-1]
            
            if not args.file:
                print(script_name) # Print script name
                print('-' * len(script_name))

            with open(script) as f:
                query = f.read()

            if timer:
                timer.start()

            res = duckdb.sql(query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')).fetchall()[0][0]

            if timer:
                timer.stop()

            if not args.time_suppress_solution and not args.file:
                for s in res:
                    print(s)

            if args.time or args.time_suppress_solution:
                timer.print_elapsed()

            if args.file:
                timer.store_time(script_name, len(string1))

            if not args.file:
                print()
                print()