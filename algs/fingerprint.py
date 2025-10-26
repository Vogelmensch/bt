from sys import argv, exit
from itertools import chain
import duckdb

def to_bit_reversed(hex_str):
    bit_str = format(int(hex_str, base=16), 'b')
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
                print(symbols[t[2]], end='')
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
    if len(argv) < 2 or len(argv) > 3:
        print('Wrong number of arguments.')
        exit(1)

    if '-c' in argv or '--classic' in argv:
        script = 'bishop_classic.sql'
        print('classic query')
    else:
        script = 'bishop.sql'
        print('USING KEY')

    symbols = [' ', '.', 'o', '+', '=', '*', 'B', 'O', 'X', '@', '%', '&', '#', '/', '^']

    fingerprint = argv[1]
    fp_list = fingerprint.split(':')
    many_lists = map(to_bit_reversed, fp_list)
    
    bitlist = list(chain.from_iterable(many_lists))

    with open(script) as f:
        query = f.read()

    res = duckdb.sql(query.format(str(bitlist))).fetchall()
    res.sort(key = lambda t: t[1] * 10 + t[0]) # sort by y, then by x

    print_fingerprint(res, symbols)