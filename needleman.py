import subprocess
import argparse
import generators.dna as dna
from measure.measure import Timer, Memory
from general_query import GeneralQuery as master

def perform_query(string1, string2, args):
    scripts = []

    if args.using_key:
        scripts.append('queries/needleman/using-key.sql')
    if args.classic:
        scripts.append('queries/needleman/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/needleman/using-key.sql')

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
            out = out[-3]
        else:
            out = out[1]

        out = out.split('|')
        l1 = out[0][1:-1].split(', ')
        l2 = out[1][1:-1].split(', ')

        if not args.suppress_solution:
            for s1, s2 in zip(l1, l2):
                print(s1)
                print(s2)
                print()

        if args.time and not args.suppress_solution:
            print(timestr)

        if args.memory:
            memory.print()

        if args.file != 'DONT STORE':
            data = [script_name, len(string1), len(string2), len(l1)]
            if args.time:
                timelist = timestr.split()
                timer.foreign_measurement(timelist[4:9:2])
                timer.write_csv(data)
            if args.memory:
                memory.write_csv(data)

        if not args.suppress_solution:
            print()
            print()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform needleman-wunsch query.')

    master.add_standard_args(parser)

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-s', '--strings', type=str, nargs='+', help='String arguments to compare')
    group.add_argument('-r', '--random', type=int, nargs='+', help='use randomly generated string of given lengths')

    parser.add_argument('-p', '--probability', type=float, help='Probability of changing a random letter in random string')

    args = parser.parse_args()
    master.check_combos(args)

    header=['script', 'length_string1', 'length_string2', 'solutions_count']
    
    if args.time:
        timer = Timer('needleman', args.file, header[:])
    if args.memory:
        memory = Memory('needleman', args.file, header[:])

    if args.repeat:
        repeats = args.repeat
    else:
        repeats = 1

    # Use provided strings
    if args.strings:
        if len(args.strings) % 2 == 1:
                parser.exit(status=1, message='Please provide an even amount of strings for -s.')

        current_repeat = 1
        total_repeats = int(len(args.strings)/2) * repeats
        while len(args.strings) > 0:
            string1 = args.strings.pop(0)
            string2 = args.strings.pop(0)

            for _ in range(repeats):
                if args.suppress_solution:
                    print(f'\rPerforming query {current_repeat}/{total_repeats}', end='')
                    current_repeat += 1
                perform_query(string1, string2, args)

    # Generate random strings with given lengths
    elif args.random:
        current_repeat = 1
        total_repeats = len(args.random) * repeats
        while len(args.random) > 0:
            random_string_length = args.random.pop(0)
            for _ in range(repeats):
                # Generate first string randomly
                string1 = dna.generate(random_string_length)

                if args.probability is None:
                    argparse.ArgumentParser.exit(1, 'When generating random strings, you need to provide -p PROBABILITY')
                # Generate second string by inserting diffs into string1
                string2 = dna.insert_diffs(string1, args.probability)
                if args.suppress_solution:
                    print(f'\rPerforming query {current_repeat}/{total_repeats}', end='')
                    current_repeat += 1
                else:
                    print('String1: {}\nString2: {}'.format(string1, string2))
                    print()

                perform_query(string1, string2, args)

    else:
        print('Provide either -s STRINGS or -r INTEGER')
        print('Type -h for help')