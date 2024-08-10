# De-novo-reference-based-guided-genome-assembly-An-integrative-pipeline.

This pipeline is used for de-novo reference-guided assembly, which operates in three phases.

Pre-processing and Contig Generation: The process begins with raw reads in FASTQ format. We first assess the quality of these reads, removing any low-quality sequences and Illumina adapters. The remaining short reads are assembled into contigs.

Selection of best reference: The best reference genome is identified, and the percentage alignment calculation is performed.

Reference-based scaffolding:  Reference-based scaffolding is conducted.
