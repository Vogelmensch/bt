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
    if len(argv) != 2:
        print('Wrong number of arguments.')
        exit(1)

    symbols = [' ', '.', 'o', '+', '=', '*', 'B', 'O', 'X', '@', '%', '&', '#', '/', '^']

    fingerprint = argv[1]
    fp_list = fingerprint.split(':')
    many_lists = map(to_bit_reversed, fp_list)
    
    bitlist = list(chain.from_iterable(many_lists))

    res = duckdb.sql("""
        CREATE OR REPLACE MACRO width() AS 17;
        CREATE OR REPLACE MACRO height() AS 9;

        CREATE OR REPLACE MACRO bitlist() AS {};

        WITH RECURSIVE bishop (
            x, 
            y, 
            sym_id, -- id for symbol in picture
            bitlist -- list of binary pairs, e.g. (10, 11, 01, 00, 10, ...)
        ) USING KEY (x, y) AS (
            SELECT 
                (width()/2) :: INTEGER,
                (height()/2) :: INTEGER,
                2,
                bitlist(),
                
            UNION

            (
            WITH new(x,y,bitlist) AS (
                SELECT
                    CASE 
                        WHEN bitlist[1][2] == '0' 
                        THEN greatest(0, x-1)      -- don't move past borders
                        ELSE least(width()-1, x+1)
                    END AS x,
                    CASE 
                        WHEN bitlist[1][1] == '0' 
                        THEN greatest(0, y-1)
                        ELSE least(height()-1, y+1)
                    END AS y,
                    array_pop_front(bitlist)
                FROM bishop
            )
            SELECT 
                new.x,
                new.y,
                -- if field has not been visited before, result is NULL
                coalesce(field_to.sym_id + 1, 1),
                new.bitlist
            FROM 
                new 
                LEFT OUTER JOIN recurring.bishop AS field_to
                ON field_to.x = new.x AND field_to.y = new.y
            WHERE length(new.bitlist) > 0
        )
        )
        SELECT x, y, sym_id
        FROM bishop;
    """.format(str(bitlist))).fetchall()
    res.sort(key = lambda t: t[1] * 10 + t[0]) # sort by y, then by x

    print_fingerprint(res, symbols)