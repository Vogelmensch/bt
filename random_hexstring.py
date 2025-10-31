import sys
import random

if len(sys.argv) != 2:
    print("Wrong number of arguments")
    sys.exit(1)

hexlen = int(sys.argv[1])

hex_str = ""

for _ in range(hexlen):
    next_hex = str(hex(random.randint(0, 16**2-1)))
    # remove 0x
    next_hex = next_hex[2:]
    if len(next_hex) == 1:
        next_hex = "0" + next_hex
    hex_str += next_hex + ":"

print(hex_str[0:-1])

