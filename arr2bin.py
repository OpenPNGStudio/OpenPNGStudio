#!/usr/bin/python3

import sys

def main():
    if len(sys.argv) != 2:
        print("Usage: python arr2bin.py output_file")
        return
        
    out_file = sys.argv[1]
    
    # This is just a debugging tool, not used for production...
    # don't give me arguments that eval is evil, I know!
    arr = eval(input("([0, 1, ...]) >> "))

    with open(out_file, "wb") as f:
        f.write(bytearray(arr))

if __name__ == "__main__":
    main()
