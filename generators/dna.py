import random
import argparse

# Generate random sequence
def generate(n):
    dna = ['A', 'C', 'G', 'T']

    string = ""

    for _ in range(n):
        string += random.choice(dna)

    return string

# Change random letters in the sequence seq
# Each letter has a probability of prob of being changed
def insert_diffs(seq, prob):
    dna = ['A', 'C', 'G', 'T']

    new_string = ""

    for i in range(len(seq)):
        if random.random() < prob:
            new_string += random.choice(dna)
        else:
            new_string += seq[i]

    return new_string


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate random DNA sequence of given length.')
    parser.add_argument('length', type=int, help='length of sequence.')
    parser.add_argument('-p', '--probability', type=float, help='Create diff with given prob')
    args = parser.parse_args()

    seq = generate(args.length)
    print(seq)

    if args.probability:
        assert(args.probability >= 0 and args.probability <= 1)
        diff = insert_diffs(seq, args.probability)
        print(diff)
