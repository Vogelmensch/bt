import random
import argparse

def generate(n):
    string = ""

    for _ in range(n):
        string += chr(random.randint(97, 122))

    return string

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate random string of lowercase ASCII-letters.')
    parser.add_argument('length', type=int, help='length of string.')
    args = parser.parse_args()

    print(generate(args.length))

