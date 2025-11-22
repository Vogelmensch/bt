import duckdb
import argparse
from generators.string import generate
from measure.time import Timer

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform needleman-wunsch query.')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-b', '--lcs_like_w_backtracking', action='store_true', help='One variant of lcs like with backtracking')
    parser.add_argument('-c', '--classic', action='store_true', help='use classic CTE')


    parser.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    parser.add_argument('-T', '--time_suppress_solution', action='store_true', help='measure time and suppress print of solution')

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-s', '--strings', type=str, nargs=2, help='String arguments to compare')
    group.add_argument('-r', '--random', type=int, nargs=2, help='use randomly generated strings of given lengths')

    args = parser.parse_args()

    if args.strings:
        string1 = args.strings[0]
        string2 = args.strings[1]
    elif args.random:
        string1 = generate(args.random[0])
        string2 = generate(args.random[1])
        print('String1: {}\nString2: {}'.format(string1, string2))
        print()

    scripts = []

    if args.using_key:
        scripts.append('queries/needleman-wunsch/using-key.sql')
    if args.lcs_like_w_backtracking:
        scripts.append('queries/needleman-wunsch/lcs-like-w-backtracking.sql')
    if args.classic:
        raise NotImplementedError('Classic Query not implemented yet.')
        # scripts.append('queries/needleman-wunsch/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/needleman-wunsch/using-key.sql')

    for script in scripts:
        script_name = script.split('/')[-1]
        print(script_name) # Print script name
        print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        if args.time or args.time_suppress_solution:
            timer = Timer()
            timer.start()

        res = duckdb.sql(query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')).fetchall()[0]

        if args.time or args.time_suppress_solution:
            timer.stop()

        if not args.time_suppress_solution:
            l1 = res[0]
            l2 = res[1]
            for s1, s2 in zip(l1, l2):
                print(s1)
                print(s2)
                print()

        if args.time or args.time_suppress_solution:
            timer.print_elapsed()
        print()
        print()