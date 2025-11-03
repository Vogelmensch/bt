import duckdb
import argparse
from itertools import chain

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

# Run the test on the query with inputs s1, s2 and compare the result to the expected output.
def run_test(query, hexstring, scale, expected):
    height = int(9*scale)
    width = int(17*scale)

    fp_list = hexstring.split(':')
    many_lists = map(to_bit_reversed, fp_list)    
    bitlist = list(chain.from_iterable(many_lists))

    res = duckdb.sql(query.format(height=height, width=width, bitlist=str(bitlist))).fetchall()
    res.sort(key = lambda t: t[1] * width + t[0]) # sort by y, then by x

    if res == expected:
        print('✅ Success')
    else:
        print('❌ Failure  for input \'{hex}\':'.format(hex=hexstring))
        print('Expected \'{e}\' but got \'{r}\''.format(e=expected, r=res))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Test lcs query.')
    parser.add_argument('-c','--classic', action='store_true', help='use classic CTE')
    args = parser.parse_args()

    if args.classic:
        script = 'queries/bishop_classic.sql'
        print('classic query')
    else:
        script = 'queries/bishop.sql'
        print('USING KEY')

    with open(script) as f:
        query = f.read()


    
    # --- DEFINE TESTS HERE ---
    run_test(query, '00', 1, [(4, 0, 1), (5, 1, 1), (6, 2, 1), (7, 3, 1), (8, 4, 1)])