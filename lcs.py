import duckdb
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform lcs query.')
    parser.add_argument('string1', type=str, help='first string to compare')
    parser.add_argument('string2', type=str, help='second string to compare')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')
    args = parser.parse_args()

    if args.classic:
        script = 'queries/lcs_classic.sql'
        print('classic query')
    else:
        script = 'queries/lcs.sql'
        print('USING KEY')

    

    with open(script) as f:
        query = f.read()

    res = duckdb.sql(query.format(string1='\'' + args.string1 + '\'', string2='\'' + args.string2 + '\'')).fetchall()[0][0]

    for s in res:
        print(s)