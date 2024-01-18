import argparse

def interpret_chunk_metadata(chunk):
    chunk = chunk.replace("@@", "").split()
    old, new = chunk[0], chunk[1]
    if new[0] == "-":
        new = new[1:]

    old_start_line, old_span = map(int, old.split(","))
    new_start_line, new_span = map(int, new.split(","))

    print(f"Old file chunk starts at line {abs(old_start_line)} and spans {old_span} lines.")
    print(f"New file chunk starts at line {new_start_line} and spans {new_span} lines.")

    if old_span < new_span:
        print("Lines were added in the new file.")
    elif old_span > new_span:
        print("Lines were removed in the new file.")
    else:
        print("No lines were added or removed, only modifications were made.")

def main():
    parser = argparse.ArgumentParser(description="Interpret git diff chunk metadata.")
    parser.add_argument('-c', '--chunk', help='Chunk metadata e.g. "@@ -3,4 +3,5 @@"')

    args = parser.parse_args()

    if args.chunk:
        interpret_chunk_metadata(args.chunk)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()

