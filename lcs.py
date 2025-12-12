import duckdb
import argparse
from generators.rstring import generate
from measure.measure import Timer, Memory

def perform_query(timer, memory, string1, string2, args):
    scripts = []

    if args.using_key:
        scripts.append('queries/lcs/using-key.sql')
    if args.classic:
        scripts.append('queries/lcs/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/lcs/using-key.sql')

    # Run all queries with the same inputs
    for script in scripts:
        script_name = script.split('/')[-1]
        print(script_name) # Print script name
        print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        timer.start()
        memory.start()

        res = duckdb.sql(query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')).fetchall()[0][0]

        timer.stop()
        memory.stop()

        if not args.suppress_solution:
            for s in res:
                print(s)

        if args.time:
            timer.print_elapsed()

        if args.memory:
            memory.print()

        if args.file != 'DONT STORE':
            data = [script_name, len(string1), len(string2), len(res)]
            if args.time:
                timer.write_csv(data)
            if args.memory:
                memory.write_csv(data)

        if args.file == 'DONT STORE':
            print()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform lcs query.', 
        epilog='To perform multiple measurements, provide multiple tuples for either -s or -r.')

    parser.add_argument('-u', '--using_key', action='store_true', help='USING KEY')
    parser.add_argument('-c', '--classic', action='store_true', help='use classic CTE')

    measure = parser.add_mutually_exclusive_group()
    measure.add_argument('-t', '--time', action='store_true', help='measure process time for query execution')
    measure.add_argument('-m', '--memory', action='store_true', help='measure memory allocated during query execution')

    parser.add_argument('-x', '--suppress_solution', action='store_true', help='suppress print of solution')
    parser.add_argument('-f', '--file', type=str, nargs='?', const='NOT PROVIDED', default='DONT STORE', help='measure time and store into FILE')

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-s', '--strings', type=str, nargs='+', help='String arguments to compare')
    group.add_argument('-r', '--random', type=int, nargs='+', help='use randomly generated strings of given lengths')

    parser.add_argument('--repeat', '--repeats', type=int, help='repeat the entire query')

    args = parser.parse_args()

    header=['script', 'length_string1', 'length_string2', 'solutions_count']

    timer = Timer('lcs', args.file, header)
    memory = Memory('lcs', args.file, header)

    # Repeat by expanding input by given length
    if args.repeat and args.strings:
        args.strings *= args.repeat
    if args.repeat and args.random:
        args.random *= args.repeat

    # Use provided strings
    if args.strings:
        if len(args.strings) % 2 == 1:
                parser.exit(status=1, message='Please provide an even amount of strings for -s.')

        while len(args.strings) > 0:
            print(f'{int(len(args.strings)/2)} remaining')
            string1 = args.strings.pop(0)
            string2 = args.strings.pop(0)

            perform_query(timer, memory, string1, string2, args)

            print()
    
    # Generate random strings with given lengths
    elif args.random:
        while len(args.random) > 0:
            print(f'{len(args.random)} remaining')
            str_length = args.random.pop(0)
            string1 = generate(str_length)
            string2 = generate(str_length)
            if not args.suppress_solution:
                print('String1: {}\nString2: {}'.format(string1, string2))
                print()
            
            perform_query(timer, memory, string1, string2, args)

            print()

    else:
        print('Provide either -s STRINGS or -r INTEGER')
        print('Type -h for help')