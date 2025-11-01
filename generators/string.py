import random
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate random string of lowercase ASCII-letters.')
    parser.add_argument('length', type=int, help='length of string.')
    args = parser.parse_args()

    string = ""

    for _ in range(args.length):
        string += chr(random.randint(97, 122))

    print(string)

