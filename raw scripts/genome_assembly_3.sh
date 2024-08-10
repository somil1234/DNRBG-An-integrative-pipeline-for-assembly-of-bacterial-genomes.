#!/bin/bash 
# Colour coding format for echo
green='\033[0;32m'      # colour coding for green
red='\033[0;31m'        # colour coding for red
yellow='\033[1;33m'     # colour coding for yellow
reset='\033[0m'         # reset colour formatting
##############################################
#check if all the command exist
#check for flash if not found store its path in a variable  
if command -v flash &>/dev/null; then
   echo -e "${green} flash is installed..."
else
   #ask for flash path
   echo -e "${yellow} Please provide absolute path to flash..."
   read -rp "please provide your flash path here : " flash
fi || exit 

#check for seqtk if not found store its path in a variable 
if command -v seqtk &>/dev/null; then
   echo -e "${green} seqtk is installed..."
else
   # ask for path
   echo -e "${yellow} Please provide absolute path to seqtk..."
   read -rp "please provide your seqtk path here : " seqtk
fi || exit

#check for AlignGraph if not found store its path in a variable
if command -v AlignGraph &>/dev/null; then
   echo -e "${green} AlignGraph is installed..."
else
   # ask for AlignGraph path
   echo -e "${yellow} Please provide absolute path to AlignGraph..."
   read -rp "Please provide your absolute path for AlignGraph here : " AlignGraph
fi || exit

#check for spades
if command -v spades &>/dev/null; then
   echo -e "${green} spades is installed..."
else
   # ask for spades path 
   echo -e "${yellow} Please provide absolute path to spades..."
   read -rp "Please provide your absolute path here: " spadespath
fi || exit

#check for unicycler if not    
if command -v unicycler &>/dev/null; then
   echo -e "${green} unicycler is installed..."
else
   # ask for unicycler path 
   echo -e "${yellow} Please provide absolute path to unicycler..."
   read -rp "Please provide your absolute path here: " unicycler
fi || exit 

####################################################################################
# Store the original directory
original_dir=$(pwd)

#make directory for denovo assembly
mkdir denovo_assembly &&

# Denovo Assembly
cd trimmomatic.out || exit
paired_read=$(pwd)
cd "$original_dir" || exit

######################################################################################
# move to de novo assembly directory and capture path
cd denovo_assembly &&
denovo_assembly=$(pwd) &&
cd "$original_dir" || exit

######################################################################################
if command -v flash &>/dev/null; then
   # ask for input parameters
   echo -e "${yellow} Please provide max-overlap input..."
   read -rp "Please provide your max-overlap input (example 150) here : " max_overlap
   echo -e "${green} running flash..."
   flash --max-overlap "$max_overlap" "$paired_read/output_1P.fq" "$paired_read/output_2P.fq" > output -d "$PWD" 
else
   #ask for flash path
   echo -e "${yellow} Please provide absolute path to flash..."
   read -rp "please provide your flash path here : " flash
   read -rp "Please provide your max-overlap input (example 150) here : " max_overlap
   echo -e "${green} running flash..."
   "$flash"  --max-overlap "$max_overlap" "$paired_read/output_1P.fq" "$paired_read/output_2P.fq" > output -d "$PWD" 
fi || exit 

#wait for flash process to complete
flash_pid=$!
wait $flash_pid

#run unicycler command 
if command -v unicycler &>/dev/null && command -v spades &>/dev/null; then
   unicycler -1 "$scaffoldingpath/out.notCombined_1.fastq" -2 "$denovo_assembly/out.notCombined_2.fastq" -s "$denovo_assembly/out.extendedFrags.fastq" -o unicycler.out 
else
   echo -e "${yellow} Please provide absolute path to unicycler..."
   read -rp "Please provide your unicycler path here : " unicycler
   echo -e "${yellow} Please provide your absolute spades path here..."
   read -rp "Please provide your spades path here : " spadespath
   echo -e "${green} executing unicycler..."
  "$unicycler" --spades_path "$spadespath" -1 "$denovo_assembly/out.notCombined_1.fastq" -2 "$denovo_assembly/out.notCombined_2.fastq" -s "$scaffoldingpath/out.extendedFrags.fastq" -o unicycler.out 
fi || exit
cd unicycler.out || exit
assemblypath=$(pwd)
# Return to the original directory
cd "$original_dir" || exit
##################################################################################
# Reference Based Assembly
cd plentyofbugs || exit
reference_genome=$(cat best_reference | awk '{print $1}')
cd "$original_dir" || exit

cd plentyofbugs.out/assembly/ || exit
contigpath=$(pwd)
cd "$original_dir" || exit

cd trimmomatic.out &&
trimmed_read=$(pwd)
cd "$original_dir" || exit

# make directory for reference based assembly
mkdir reference_based_assembly &&
cd reference_based_assembly || exit

if command -v seqtk &>/dev/null && command -v AlignGraph &>/dev/null; then
   echo -e "${green} Running seqtk to convert fastq files to fasta files"
   seqtk seq -A "$trimmed_read/output_1P.fq" > output_1P.fa &&
   seqtk seq -A "$trimmed_read/output_2P.fq" > output_2P.fa &&
   seqtk_pid=$!
   wait $seqtk_pid
   echo -e "${yellow} Please provide required input parameters for AlignGraph"
   read -rp "Please provide your input for parameter --distanceLow : "  distancelow
   read -rp "please provide your input for parameter --distancehigh : " distancehigh
   echo -e "${green} Running AlignGraph"
   AlignGraph --read1 output_1P.fa --read2 output_1P.fa --contig "$contigpath/contigs.fasta" --genome "$reference_genome" --distanceLow 100 --distanceHigh 1000 --extendedContig sample_extendedcontig.fasta --remainingContig sample_remainingcontig.fasta
else
   echo "executing seqtk..."
   "$seqtk" seq -A "$trimmed_read/output_1P.fq" > output_1P.fa &&
   "$seqtk" seq -A "$trimmed_read/output_2P.fq" > output_2P.fa &&
   seqtk_pid=$!
   wait $seqtk_pid
   echo -e "${yellow} Please provide required input parameter for AlignGraph..."
   read -rp "Please provide your input for parameter --distanceLow : "  distancelow
   read -rp "please provide your input for parameter --distancehigh : " distancehigh
   echo -e "${green} Running AlignGraph"
   "$AlignGraph" --read1 output_1P.fa --read2 output_1P.fa --contig "$contigpath/contigs.fasta" --genome "$reference_genome" --distanceLow 100 --distanceHigh 1000 --extendedContig sample_extendedcontig.fasta --remainingContig sample_remainingcontig.fasta
fi
echo -e "${green} script run sucessfully...."
