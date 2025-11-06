import duckdb
import argparse
from generators.string import generate

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform lcs query.')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')

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

    if args.classic:
        script = 'queries/lcs_classic.sql'
        print('classic query')
    else:
        script = 'queries/lcs.sql'
        print('USING KEY')

    with open(script) as f:
        query = f.read()

    res = duckdb.sql(query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')).fetchall()[0][0]

    for s in res:
        print(s)