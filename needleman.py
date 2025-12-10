import duckdb
import argparse
import generators.dna as dna
from measure.measure import Timer

def perform_query(timer, string1, string2, args):
    scripts = []

    if args.using_key:
        scripts.append('queries/needleman/using-key.sql')
    if args.classic:
        scripts.append('queries/needleman/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/needleman/using-key.sql')

    for script in scripts:
        script_name = script.split('/')[-1]
        print(script_name) # Print script name
        print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        timer.start()

        res = duckdb.sql(query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')).fetchall()[0]

        timer.stop()

        if not args.suppress_solution:
            l1 = res[0]
            l2 = res[1]
            for s1, s2 in zip(l1, l2):
                print(s1)
                print(s2)
                print()

        if args.time:
            timer.print_elapsed()

        if args.file != 'DONT STORE':
            data = [script_name, len(string1), len(string2), len(res[0])]
            timer.write_csv(data)

        print()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform needleman-wunsch query.')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c', '--classic', action='store_true', help='use classic CTE')

    parser.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
    parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='measure time and store into FILE')

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-s', '--strings', type=str, nargs='+', help='String arguments to compare')
    group.add_argument('-r', '--random', type=int, nargs='+', help='use randomly generated string of given lengths')

    parser.add_argument('-p', '--probability', type=float, help='Probability of changing a random letter in random string')

    args = parser.parse_args()
    
    timer = Timer('needleman', args.file, header=['script', 'length_string1', 'length_string2', 'solutions_count', 'time'])

    # Use provided strings
    if args.strings:
        if len(args.strings) % 2 == 1:
                parser.exit(status=1, message='Please provide an even amount of strings for -s.')

        while len(args.strings) > 0:
            print(f'{int(len(args.strings)/2)} remaining')
            string1 = args.strings.pop(0)
            string2 = args.strings.pop(0)

            perform_query(timer, string1, string2, args)

    # Generate random strings with given lengths
    elif args.random:
        while len(args.random) > 0:
            print(f'{len(args.random)} remaining')
            # Generate first string randomly
            string1 = dna.generate(args.random.pop(0))

            if args.probability is None:
                argparse.ArgumentParser.exit(1, 'When generating random strings, you need to provide -p PROBABILITY')
            # Generate second string by inserting diffs into string1
            string2 = dna.insert_diffs(string1, args.probability)
            print('String1: {}\nString2: {}'.format(string1, string2))
            print()

            perform_query(timer, string1, string2, args)

    else:
        print('Provide either -s STRINGS or -r INTEGER')
        print('Type -h for help')