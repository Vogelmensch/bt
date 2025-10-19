import sys 

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


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Wrong number of arguments.')
        sys.exit(1)

    fingerprint = sys.argv[1]
    fp_list = fingerprint.split(':')
    res = map(to_bit_reversed, fp_list)
    print(list(res))