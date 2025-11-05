from sys import exit
import argparse
from itertools import chain
import duckdb
import generators.hexstring as hexgen

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
    

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform Drunken-Bishop query.')

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-f', '--fingerprint', type=str, help='hex-string, e.g. 42:f2:bb:02')
    group.add_argument('-r', '--random', type=int, help='use randomly generated hexstring of given length')

    parser.add_argument('-p', '--print_result', action='store_true', help='print the pure result list')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')
    parser.add_argument('-s', '--scale', type=float, help='scale image dimensions')
    
    args = parser.parse_args()


    if not args.fingerprint and not args.random:
        print('Provide either -f FINGERPRINT or -r INTEGER.')
        print('Type -h for help.')
        exit()

    if args.scale:
        scale = args.scale        
    else:
        scale = 1

    HEIGHT = int(9*scale)
    WIDTH = int(17*scale)

    symbols = [' ', '.', 'o', '+', '=', '*', 'B', 'O', 'X', '@', '%', '&', '#', '/', '^']

    try:
        if args.random:
            fingerprint = hexgen.generate(args.random)
            print('Generated {}'.format(fingerprint))
        else:
            fingerprint = args.fingerprint

        fp_list = fingerprint.split(':')
        many_lists = map(to_bit_reversed, fp_list)
        
        bitlist = list(chain.from_iterable(many_lists))
    except:
        print('Invalid Input')
        exit(1)

    if args.classic:
        script = 'queries/bishop_classic.sql'
        print('classic query')
    else:
        script = 'queries/bishop.sql'
        print('USING KEY')

    with open(script) as f:
        query = f.read()

    res = duckdb.sql(query.format(height=HEIGHT, width=WIDTH, bitlist=str(bitlist))).fetchall()
    res.sort(key = lambda t: t[1] * WIDTH + t[0]) # sort by y, then by x

    if args.print_result:
        print(res)

    print_fingerprint(res, symbols, height=HEIGHT, width=WIDTH)