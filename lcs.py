import duckdb
import argparse
from generators.string import generate
from measure.time import Timer

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform lcs query.')
    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c', '--classic', action='store_true', help='use classic CTE')
    parser.add_argument('-i', '--indices', action='store_true', help='alternatiev version of USING KEY, using indices')
    parser.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')

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

    scripts = []

    if args.using_key:
        scripts.append('queries/lcs/using-key.sql')
    if args.classic:
        scripts.append('queries/lcs/classic.sql')
    if args.indices:
        scripts.append('queries/lcs/indices-using-key.sql')

    for script in scripts:
        script_name = script.split('/')[-1]
        print(script_name) # Print script name
        print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        if args.time:
            timer = Timer()
            timer.start()

        res = duckdb.sql(query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')).fetchall()[0][0]

        if args.time:
            timer.stop()

        for s in res:
            print(s)

        if args.time:
            timer.print_elapsed()
        print()
        print()