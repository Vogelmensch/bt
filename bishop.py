import argparse
from itertools import chain
import subprocess
from generators.hexstring import generate
from measure.measure import Timer, Memory
from general_query import GeneralQuery as master


def to_bit_reversed(hex_str):
    hex_num = int(hex_str, base=16)
    assert(hex_num >= 0 and hex_num < 256)
    
    bit_str = format(hex_num, 'b')
    # fill with zeros
    while len(bit_str) < 8:
        bit_str = '0' + bit_str

    assert(len(bit_str) == 8)

    rev = []
    for i in range(7,0,-2):
        bit_pair = bit_str[i-1] + bit_str[i]
        rev.append(bit_pair)
    
    return rev


# fp (fingerprint) is a list of 3-tuples (x, y, sym_id)
# fp is sorted by y first, then by x
def print_fingerprint(fp, symbols, height=9, width=17):
    # Upper Boundaries (Visual only)
    print('+', end='')
    for _ in range(width):
        print('-', end='')
    print('+')
    

    for y in range(height):
        print('|', end='')
        for x in range(width):
            if len(fp) == 0:
                print(symbols[0], end='')
                continue
            t = fp[0] # current list element (type: tuple)
            if t[0] == x and t[1] == y:
                try:
                    print(symbols[t[2]], end='')
                except IndexError:
                    print('M', end='')
                fp.pop(0)
            else:
                print(symbols[0], end='')
        print('|')


    # Lower Boundaries (Visual only)
    print('+', end='')
    for _ in range(width):
        print('-', end='')
    print('+')


def perform_query(args):
    if args.scale:
        scale = args.scale        
    else:
        scale = 1

    HEIGHT = int(9*scale)
    WIDTH = int(17*scale)

    symbols = [' ', '.', 'o', '+', '=', '*', 'B', 'O', 'X', '@', '%', '&', '#', '/', '^']

    try:
        if args.random:
            fingerprint = generate(args.random.pop(0))
            print('Generated {}'.format(fingerprint))
        else:
            fingerprint = args.fingerprint.pop(0)

        fp_list = fingerprint.split(':')
        many_lists = map(to_bit_reversed, fp_list)
        
        bitlist = list(chain.from_iterable(many_lists))
    except:
        argparse.ArgumentParser.exit(1, 'Invalid Input')

    scripts = []

    if args.using_key:
        scripts.append('queries/bishop/using-key.sql')
    if args.classic:
        scripts.append('queries/bishop/classic.sql')

    if len(scripts) == 0:
        scripts.append('queries/bishop/using-key.sql')

    for script in scripts:
        script_name = script.split('/')[-1]
        print(script_name) # Print script name
        print('-' * len(script_name))

        with open(script) as f:
            query = f.read()

        query = query.format(height=HEIGHT, width=WIDTH, bitlist=str(bitlist))

        if args.time:
            cmd = '.timer on'
        else:
            cmd = ''
        if args.memory:
            memory.start()

        res = master.run_subprocess(cmd, query, args, result_format='-list')

        if args.memory:
            memory.stop()

        if res == 'timeout':
            constant_data = [script_name, len(fp_list), scale] 
            if args.time:
                master.store_timeout(args, constant_data, timer)
            if args.memory:
                master.store_timeout(args, constant_data, memory)
            continue

        if not res:
            continue

        # Format result into 'out'
        out = res.stdout.split('\n')
        out = list(map(lambda s: tuple(s.split('|')), out))
        # Cut list depending on whether we measured time
        if args.time:
            # get time measurement
            timestr = out[-2][0]
            # cut all time measurements out
            out = out[4:-2]
        else:
            # cut stuff out
            out = out[1:-1]
        out = map(lambda t: (int(t[0]), int(t[1]), int(t[2])), out)
        out = list(out)

        out.sort(key = lambda t: t[1] * WIDTH + t[0]) # sort by y, then by x

        if args.print_result:
            print(out)

        if not args.suppress_solution:
            print_fingerprint(out, symbols, height=HEIGHT, width=WIDTH)

        if args.time:
            print(timestr)

        if args.memory:
            memory.print()

        if args.file != 'DONT STORE':
            data = [script_name, len(fp_list), scale] 
            if args.time:
                timelist = timestr.split()
                timer.foreign_measurement(timelist[4:9:2])
                timer.write_csv(data)
            if args.memory:
                memory.write_csv(data)
        
        print()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform Drunken-Bishop query.')

    master.add_standard_args(parser)

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-s', '--fingerprint', '--string', type=str, nargs='+', help='hex-string, e.g. 42:f2:bb:02')
    group.add_argument('-r', '--random', type=int, nargs='+', help='use randomly generated hexstring of given length')
    parser.add_argument('-p', '--print_result', action='store_true', help='print the pure result list')
    parser.add_argument('-d', '--scale', '--dim', type=float, help='scale image dimensions')
    
    args = parser.parse_args()

    master.check_combos(args)

    if not args.fingerprint and not args.random:
        parser.exit(1, 'Provide either -s FINGERPRINT or -r INTEGER.')

    header=['script', 'fingerprint_length', 'image_scale']

    if args.time:
        timer = Timer('bishop', args.file, header[:])
    if args.memory:
        memory = Memory('bishop', args.file, header[:])

    if args.repeat and args.fingerprint:
        args.fingerprint *= args.repeat
    if args.repeat and args.random:
        args.random *= args.repeat

    while args.fingerprint and len(args.fingerprint) > 0 or args.random and len(args.random) > 0:
        perform_query(args)