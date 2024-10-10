import argparse

def split_contigs(input_file, output_file='output_split.fasta', max_length=5000):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        contig = ''
        header = ''
        has_long_contig = False  # Flag to check if any contig is longer than max_length

        for line in infile:
            line = line.strip()
            if line.startswith('>'):  # Header line
                if contig:  # If there's an existing contig, process it
                    has_long_contig = True  # We have at least one contig
                    write_split_contigs(outfile, header, contig, max_length)

                header = line  # Update header
                contig = ''  # Reset contig for the new header
            else:
                contig += line  # Append to contig

        # Process the last contig after the loop
        if contig:
            has_long_contig = True  # Last contig check
            write_split_contigs(outfile, header, contig, max_length)

    # If no contig was longer than max_length, copy original contigs to the output
    if not has_long_contig:
        with open(output_file, 'w') as outfile:
            with open(input_file, 'r') as infile:
                for line in infile:
                    outfile.write(line)

def write_split_contigs(outfile, header, contig, max_length):
    # Split the contig if necessary
    for i in range(0, len(contig), max_length):
        split_contig = contig[i:i + max_length]
        split_header = f"{header} part_{i // max_length + 1} length_{len(split_contig)}"
        
        outfile.write(f"{split_header}\n{split_contig}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Split contigs from a FASTA file.')
    parser.add_argument('input_file', type=str, help='Input FASTA file containing contigs.')
    parser.add_argument('-o', '--output_file', type=str, default='output_split.fasta',
                        help='Output FASTA file for split contigs (default: output_split.fasta).')

    args = parser.parse_args()
    split_contigs(args.input_file, args.output_file)
