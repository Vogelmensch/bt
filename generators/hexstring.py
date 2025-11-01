import random
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate random hexstring.')
    parser.add_argument('length', type=int, help='length of hexstring in bytes')
    args = parser.parse_args()

    hex_str = ""

    for _ in range(args.length):
        next_hex = str(hex(random.randint(0, 16**2-1)))
        # remove 0x
        next_hex = next_hex[2:]
        if len(next_hex) == 1:
            next_hex = "0" + next_hex
        hex_str += next_hex + ":"

    print(hex_str[0:-1])

