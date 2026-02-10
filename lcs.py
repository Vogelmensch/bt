import subprocess
import argparse
from generators.rstring import generate
from measure.measure import Timer, Memory
from general_query import GeneralQuery as master

def perform_query(string1, string2, args):
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
        if not args.suppress_solution:
            print(script_name) # Print script name
            print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        query = query.format(string1='\'' + string1 + '\'', string2='\'' + string2 + '\'')

        if args.time:
            cmd = '.timer on'
        else:
            cmd = ''
        if args.memory:
            memory.start()

        res = master.run_subprocess(cmd, query, args)

        if args.memory:
            memory.stop()

        if res == 'timeout':
            constant_data = [script_name, len(string1), len(string2)]
            if args.time:
                master.store_timeout(args, constant_data, timer)
            if args.memory:
                master.store_timeout(args, constant_data, memory)
            continue

        if not res:
            continue

        out = res.stdout.split('\n')
        if args.time:
            timestr = out[-2]
            out = out[4]
        else:
            out = out[1]

        out, timestr = master.get_out_dict(args, res)

        solutions, table_size = out['solutions'], out['table_size']
        solutions = solutions.split(', ')

        if not args.suppress_solution:
            for s in solutions:
                print(s)
            print(f'{table_size} items in final table')

        if args.time and not args.suppress_solution:
            print(timestr)

        if args.memory and not args.suppress_solution:
            memory.print()

        if args.file != 'DONT STORE':
            data = [script_name, len(string1), len(string2), len(solutions), table_size]
            if args.time:
                timelist = timestr.split()
                timer.foreign_measurement(timelist[4:9:2])
                timer.write_csv(data)
            if args.memory:
                memory.write_csv(data)

        if args.file == 'DONT STORE' and not args.suppress_solution:
            print()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Perform lcs query.', 
        epilog='To perform multiple measurements, provide multiple tuples for either -s or -r.')

    master.add_standard_args(parser)

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-s', '--strings', type=str, nargs='+', help='String arguments to compare')
    group.add_argument('-r', '--random', type=int, nargs='+', help='use randomly generated strings of given lengths')

    args = parser.parse_args()
    master.check_combos(args)

    header=['script', 'length_string1', 'length_string2', 'solutions_count', 'table_size']

    if args.time:
        timer = Timer('lcs', args.file, header[:])
    if args.memory:
        memory = Memory('lcs', args.file, header[:])

    # Repeat by expanding input by given length
    if args.repeat and args.strings:
        args.strings *= args.repeat
    if args.repeat and args.random:
        args.random *= args.repeat

    # Use provided strings
    if args.strings:
        if len(args.strings) % 2 == 1:
                parser.exit(status=1, message='Please provide an even amount of strings for -s.')

        total_repeats = len(args.strings)
        current_repeat = 1
        while len(args.strings) > 0:
            string1 = args.strings.pop(0)
            string2 = args.strings.pop(0)
            if args.suppress_solution:
                    print(f'\rPerforming query {current_repeat}/{total_repeats}', end='')
                    current_repeat += 1
            perform_query(string1, string2, args)

            print()
    
    # Generate random strings with given lengths
    elif args.random:
        total_repeats = len(args.random)
        current_repeat = 1
        while len(args.random) > 0:
            str_length = args.random.pop(0)
            string1 = generate(str_length)
            string2 = generate(str_length)
            if not args.suppress_solution:
                print('String1: {}\nString2: {}'.format(string1, string2))
                print()
            else:
                print(f'\rPerforming query {current_repeat}/{total_repeats}', end='')
                current_repeat += 1
            perform_query(string1, string2, args)

    else:
        print('Provide either -s STRINGS or -r INTEGER')
        print('Type -h for help')