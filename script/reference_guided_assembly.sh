#!/bin/bash
###############################################
#colour coding format for echo
green='\033[0;32m'  #colour coding for green
red='\033[0;31m'    #colour coding for red
yellow='\033[1;33m' #colour coding for yellow
reset='\033[0m'     #reset colour
##############################################
# Help
##############################################
Help()
{
# Colors for formatting
green='\033[0;32m'
yellow='\033[1;33m'
reset='\033[0m'
# Display Help
echo -e "${green}     This is an integrative genome assembly pipeline.${reset}"
echo -e "${yellow}    Usage:${reset}"
echo -e "${yellow}    ./genome_assembly.sh read_1 read_2${reset}"
echo -e "${yellow}    where:${reset}"
echo -e "${yellow}    read_1 - Path to the first input read file (fastq format)${reset}"
echo -e "${yellow}    read_2 - Path to the second input read file (fastq format)${reset}"
echo -e "${green}     Please ensure that the input files are in fastq format.${reset}"
}
###############################################
#########pre procressing step one ##############
#get working directory
current_dir=$(pwd)
#input files that is raw reads in fastq format
forward_read=$1
reverse_read=$2
#check if the arguments are given
if [ "$#" -eq 2 ]; then # check for two arguments
echo -e "${green}Input provided....${reset}"
else
echo -e "${red}Proper input is not provided please provide raw reads...${reset}"
Help # Call the help function to display usage
exit 1
fi
######################################################
#Read Quality Assessment using FastQC
if command -v fastqc &>/dev/null; then # check for the fastqc programme
echo -e "${green}fastqc programme in installed...${reset}" # if found run fastqc here
mkdir fastqc.out && # make fastqc output folder
export LC_ALL=C &&
echo -e "${green}executing fastqc...${reset}" &&
fastqc -o fastqc.out -f fastq "$forward_read" "$reverse_read" || exit 1 # running fastqc .....
else
# if not found ask for path and run fastqc here
echo -e "${red}fastqc programme is not found please check this programme is eighter installed or present in your path...${reset}"
echo -e "${yellow}please provide absolute path to the executable....${reset}"
read -rp "Pleae provide absolue path to fastqc executable here : " fastqc
echo -e "${green}Making fastqc output folder...${reset}"
export LC_ALL=C &&
mkdir fastqc.out && # make fastqc output folder
echo -e "${green}executing fastqc...${reset}"
"$fastqc" -o fastqc.out -f fastq "$forward_read" "$reverse_read" || exit 1
wait for command to run using wait command
fastqc_pid=$!
wait $fastqc_pid
fi || exit
echo -e "${green} fastqc run sucessfully..."
#############################################################
# use multiqc to compile results
mkdir multiqc.out && #create a directory named multiqc.out
# navigate into the directory named multiqc.out
if command -v multiqc &>/dev/null; then # check for multiqc programme
echo -e "${green} multiqc programme is installed...${reset}" # if found run multiqc here
echo -e "${green} executing multiqc...${reset}"
multiqc  "$current_dir/fastqc.out" -o "$current_dir/multiqc.out" || exit 1
else # if not found ask for path and run multiqc here
echo -e "${red} multiqc programme is not found please check this programme is eighter installed or present in your path...${reset}"
echo -e "${yellow} please provide absolute path to the multiqc executable....${reset}"
read -rp "Pleae provide absolute path to multiqc executable here :" multiqc
echo -e "${green} executing multiqc...${reset}"
"$multiqc" -o "$current_dir/fastqc.out" ../multiqc.out || exit 1
cd "$current_dir" &&
# Wait for command to run using wait command
multiqc_pid=$!
wait "$multiqc_pid"
fi || exit
echo -e "${green} multiqc run sucessfully...${reset}"
###############################################################
# Use trimmomatic to trim unpaired reads and remove adapter sequences
# Check for java
if command -v java &>/dev/null; then
echo -e "${green} java installed...${reset}"
else # if not installed ask for installation
echo -e "${red}Please install java and check if installed already check if it is present in your path..."
fi || exit
# Make directory for trimmomatic
echo -e "${green}makeing output directory for trimmomatic...${reset}"
mkdir trimmomatic.out &&
# Check for trimmomatic
# Taking parameters using if else statement
# Navigate to trimmomatic.out directory and captute its path
if command -v trimmomatic &>/dev/null; then # check for trimmomatic
echo -e "${green} Trimmomatic programme is installed...${reset}"
echo -e "${yellow} Please provide the relevent parameters for the tools...${reset}"
read -rp "Please provide number of threads to run the tool : " thread
read -rp "Please provide phread score : " phread
read -rp "Please provide path to adapter file:" PATH_TO_ADAPTER_CONTAM_FILE
read -rp "Please provide parameter LEADING: " leading
read -rp "Please provide parameter TRAILING: " trailing
read -rp "Please provide parameter SLIDINGWINDOW: " slidingwindow
read -rp "Please provide parameter MINLEN: " minlength
echo -e "${green} executing Trimmomatic...${reset}"
trimmomatic PE -threads "$thread" -phred"$phread" "$forward_read" "$reverse_read" output_1P.fq output_1U.fq output_2P.fq output_2U.fq ILLUMINACLIP:"$PATH_TO_ADAPTER_CONTAM_FILE":2:30:10 LEADING:"$leading" TRAILING:"$trailing" SLIDINGWINDOW:"$slidingwindow" MINLEN:"$minlength" || exit 1  #To remove low quality base pairs and adapter sequences
else # ask path to the trimmomatic programme path
echo -e "${red} please install trimmomatic and check if already installed check if it is present in your path...${reset}"
echo -e "${yellow} Please provide the absolute path to the trimmomatic executable here : ${reset}"
read -rp "Please provide your trimmomatic path here : " trimmomatic
echo -e "${yellow} Please provide the relevent parameters for the tools...${reset}"
read -rp "Please provide number of threads to run the tool : " thread
read -rp "Please provide phread score : " phread
read -rp "Please provide path to adapter file :" PATH_TO_ADAPTER_CONTAM_FILE
read -rp "Please provide parameter LEADING: " leading
read -rp "Please provide parameter TRAILING: " trailing
read -rp "Please provide parameter SLIDINGWINDOW: " slidingwindow
read -rp "Please provide parameter MINLEN: " minlength
echo -e "${green}executing Trimmomatic...${reset}"
java -jar "$trimmomatic" PE -threads "$thread" -phred"$phread" "$forward_read" "$reverse_read" output_1P.fq output_1U.fq output_2P.fq output_2U.fq ILLUMINACLIP:"$PATH_TO_ADAPTER_CONTAM_FILE":2:30:10 LEADING:"$leading" TRAILING:"$trailing" SLIDINGWINDOW:"$slidingwindow" MINLEN:"$minlength" || exit 1   #To remove low quality base pairs and adapter sequences
fi || exit
# Wait for the command to be compleated
trimmomatic_pid=$!
wait $trimmomatic_pid
# Move all output  to trimmomatic.out directory
mv output_1P.fq output_1U.fq output_2P.fq output_2U.fq trimmomatic.out/ &&
# Capturing path of trimmomatic.out directory
cd trimmomatic.out && # navigate to trimmomatic directory
trimmomatic_path=$(pwd) && # capturing directory path of trimmed reads
cd "$current_dir" || exit 1
#########################################################################################################
# Merging of Overlapping Paired-end Reads using FLASH
# Checking if flash is installed
# Using if else statement to check and run command
# Make directory for flash output
mkdir flash.out && #make flash directory
cd flash.out &&    #navigate to flash directory
if command -v flash &>/dev/null; then
echo -e "${green}flash is installed...${reset}"
echo -e "${green}executing flash...${reset}"
read -rp "Please provide input for parameter maximum overlap: " max_overlap
flash --max-overlap "$max_overlap" "$trimmomatic_path/output_1P.fq" "$trimmomatic_path/output_2P.fq" > output -d "$PWD" || exit 1 #flash will generate notCombined and extended fastq files
else # ask for the absolute path to the flash command
echo -e "${red} flash is not installed if you think it is installed please check if it is in your path...${reset}"
echo -e "${yellow}Please provide absolute path to the flash command...${reset}"
read -rp "Please provide absolute path to the flash command here : " flash
read -rp "Please provide input for parameter maximum overlap: " max_overlap
echo -e "${green}executing flash...${reset}"
"$flash" --max-overlap "$max_overlap" "$trimmomatic_path/output_1P.fq" "$trimmomatic_path/output_2P.fq" > output -d "$PWD" || exit 1 #flash will generate notCombined and extended fastq file
fi || exit
# Wait for the command to compleated
flash_pid=$!
wait $flash_pid
# Capture flash path
flash_path=$(pwd) &&  #use this in unicycler command to get extended frags
# Change to the old directory
cd "$current_dir" &&
#############################################################################################################
# De novo Genome Assembly using Unicycler
# Check if unicycler is installed
# Using if else statement to check and run command
# Make directory for unicycler output
# Make directory for unicycler output
mkdir unicycler.out && cd unicycler.out || exit
# Check if both unicycler and spades are installed
if command -v spades &>/dev/null && command -v unicycler &>/dev/null; then
echo -e "${green}Both spades and unicycler are installed.${reset}"
               unicycler  -1 "$trimmomatic_path/output_1P.fq" \
                          -2 "$trimmomatic_path/output_2P.fq" -s "$flash_path/out.extendedFrags.fastq" \
                          -o assembly  || exit 1
                                     fi || exit
# Check if neither unicycler nor spades are installed
if ! command -v spades &>/dev/null && ! command -v unicycler &>/dev/null; then
echo -e "${red}Both unicycler and spades are not installed.${reset}"
echo -e "${yellow}Please provide absolute paths to unicycler and spades.${reset}"
read -rp "Please provide absolute path to unicycler: " unicycler
echo -e "${green}Running unicycler.${reset}"
        "$unicycler" -1 "$trimmomatic_path/output_1P.fq" \
                    -2 "$trimmomatic_path/output_2P.fq" -s "$flash_path/out.extendedFrags.fastq" \
                    -o assembly || exit 1
fi || exit
cd assembly &&
assemblypath=$(pwd)
# Wait for unicycler command to complete
unicycler_pid=$!
wait $unicycler_pid
# Navigate to old directory
cd "$current_dir" || exit
#######################################################################################
# Assessment of Assembly Quality using QUAST
# Make quast output directory
mkdir quast.out &&
cd quast.out &&
# Check if quast is installed
if command -v quast &>/dev/null; then
echo -e "${green}quast is installed...${reset}"
echo -e "${green}Running quast...${reset}"
quast -o quast_output "$assemblypath/assembly.fasta" || exit 1
else # take absolute path to quast
echo -e "${yellow}Please provide absolute path to quast.py and make sure python is installed...${reset}"
read -rp "Please provide absolute path to quast here : " quast
echo -e "${green}Running quast...${reset}"
python "$quast" -o quast_output "$assemblypath/assembly.fasta" || exit 1
fi || exit
# Wait for quast command to complete
quast_pid=$!
wait $quast_pid
# Print completion message
echo -e "${green} Phase 1 complete!${reset}"
##################################################################################################
# Phase 2
##################################################################################################
cd "$current_dir" || exit
cd trimmomatic.out || exit # navigate to trimmomatic.out directory
trimmomatic_output_path=$(pwd) # capturing path
cd "$current_dir" || exit
# ask for path to reference genome
echo -e "${yellow} Please provide path to reference genome...${reset}"
read -rp "Please provide your path here : " reference_genome
#check for required programme
# List of required programs
required_programs=("mash" "skesa" "spades" "seqtk" "unicycler" "plentyofbugs")
# Check if each required program is installed
missing_programs=()
for program in "${required_programs[@]}"; do
if ! command -v "$program" &> /dev/null; then
missing_programs+=("$program")
fi
done
# If there are missing programs, install them
if [ ${#missing_programs[@]} -gt 0 ]; then
echo -e "${red}The following programs are missing: ${missing_programs[*]}${reset}"
echo -e "${missing_programs[@]}"
echo -e "${yellow}Please install the following programmes.${reset}"
echo -e "${missing_programs[@]}"
######################################################################
elif [ ${#missing_programs[@]} == 0 ]; then
######################################################################
echo -e "${yellow}Please provide name of assembler skesa or spades.${reset}"
read -rp "Please provide your assembler name here: " assembler
echo -e "${green}Running plenty of bugs.${reset}"
plentyofbugs --assembler "$assembler" \
             -f "${trimmomatic_output_path}/output_1P.fq" \
             -r "${trimmomatic_output_path}/output_2P.fq" \
             -g "$reference_genome" \
             -o plentyofbugs.out
######################################################################
elif  ! command -v plentyofbugs &>/dev/null && ! command -v spades && ! command -v skesa && command -v seqtk && command -v unicycler && command -v seqtk && command -v mash; then
######################################################################
# ask for absolute path to unicycler and skesa or spades
echo -e "${yellow}Please provide absolute path to plentyofbbugs.${reset}"
read -rp "${yellow}Please provide absolute path to plentyofbugs here : " plentyofbugs
echo -e "${yellow}Please provide absolute path to assembler skesa or spades.${reset}"
read -rp "Please provide your assembler path here : " assembler
"$plentyofbugs" --assembler "$assembler" \
                -f "${trimmomatic_output_path}/output_1P.fq" \
                -r "${trimmomatic_output_path}/output_2P.fq" \
                -g "$reference_genome" \
                -o plentyofbugs.out
fi || exit
#######make function###########################
function activate_conda() {
# If statement to check if the environment exists
if conda env list | grep -q "install_env"; then
echo -e "${green} Enviornment 'install_env' already exists. Skipping environment creation...${reset}"
# Initiate conda environment
echo -e "${yellow} Initiating conda environment...${reset}" &&
source activate install_env &&
# Install plentyofbugs command not found using pip
if ! command -v plentyofbugs; then
echo -e "${red}plentyofbugs not found.${reset}"
echo -e "${green}trying installing plentyofbugs using pip.${reset}"
pip install plentyofbugs
fi
# List of required programs
required_programs=("mash" "skesa" "spades" "seqtk" "unicycler" "plentyofbugs")
# Check if each required program is installed
missing_programs=()
for program in "${required_programs[@]}"; do
if ! command -v "$program" &> /dev/null; then
missing_programs+=("$program")
fi
done
# If there are missing programs, install them
if [ ${#missing_programs[@]} -gt 0 ]; then
echo -e "${yellow}The following programs are missing and will be installed: ${missing_programs[*]}${reset}"
echo "${missing_programs[@]}"
# Install missing programs
for program in "${missing_programs[@]}"; do
echo -e "${yellow}Installing $program...${reset}"
conda install --yes "bioconda::$program"
done
fi
# run plenty of bugs
echo -e "${green}Running plentyofbugs.${reset}"
echo -e "${yellow}Please provide name of assembler skesa or spades.${reset}"
read -rp "Please provide your assembler name here: " assembler
echo -e "${green}Running plenty of bugs.${reset}"
plentyofbugs --assembler "$assembler" \
             -f "${trimmomatic_output_path}/output_1P.fq" \
             -r "${trimmomatic_output_path}/output_2P.fq" \
             -g "$reference_genome" \
             -o plentyofbugs.out
#conda deactivate
conda deactivate
else
# Ask if the following command will be installed or not
echo -p "${yellow} Would you like to install the following in conda environment? Please provide an answer with yes or no below !.${reset}"
read -rp "Please provide your answer here : " answer
# Use if else statement to evaluate the command line input
if [ "$answer" == yes ]; then
# Create the conda environment
echo -e "${yellow} Creating conda environment...${reset}"
conda create --name install_env &&
# Initiate conda environment
echo -e "${yellow} Initiating conda environment...${reset}"
source activate install_env &&
# Install plentyofbugs command not found using pip
if ! command -v plentyofbugs; then
echo -e "${red}plentyofbugs not found.${reset}"
echo -e "${green}trying installing plentyofbugs using pip.${reset}"
pip install plentyofbugs
fi
# List of required programs
required_programs=("mash" "skesa" "spades" "seqtk" "unicycler" "plentyofbugs")
# Check if each required program is installed
missing_programs=()
for program in "${required_programs[@]}"; do
if ! command -v "$program" &> /dev/null; then
missing_programs+=("$program")
fi
done
# If there are missing programs, install them
if [ ${#missing_programs[@]} -gt 0 ]; then
echo -e "${yellow}The following programs are missing and will be installed: ${missing_programs[*]}${reset}"
echo -e "${yellow}The following programs are missing and will be installed:${reset}"
echo "${missing_programs[@]}"
# Install missing programs
for program in "${missing_programs[@]}"; do
echo -e "${yellow}Installing $program..."
conda install --yes "bioconda::$program"
done
echo -e "${green}Installation of required programs complete."
# Run Plentyofbugs
plentyofbugs --assembler "$assembler" \
             -f "${trimmomatic_output_path}/output_1P.fq" \
             -r "${trimmomatic_output_path}/output_2P.fq" \
             -g "$reference_genome" \
            -o plentyofbugs.out &&  #Selection of best genome based upon Mash Value
conda deactivate
else
echo -e "${green}All required programs are already installed. Skipping installation."
fi
echo -e "${green} Installation complete...${reset}"
# Run command plenty of bugs
echo -e "${yellow} Please select assembler skesa or spades...${reset}"
read -rp "Please provide your assembler skesa/spades here : " assembler
plentyofbugs --assembler "$assembler" \
             -f "${trimmomatic_output_path}/output_1P.fq" \
             -r "${trimmomatic_output_path}/output_2P.fq" \
             -g "$reference_genome" \
             -o plentyofbugs.out &&  #Selection of best genome based upon Mash Value
conda deactivate
else
echo -e "${red} ERROR: Please check all the tools are properly installed to run the program."
fi
fi
 }
# Check if all required commands are missing
if ! command -v plentyofbugs &>/dev/null && \
   ! command -v spades &>/dev/null && \
   ! command -v skesa &>/dev/null && \
   ! command -v seqtk &>/dev/null && \
   ! command -v unicycler &>/dev/null && \
   ! command -v mash &>/dev/null; then
     echo -e "${red}There are some programs missing and will be installed and run in a separate conda environment.${reset}"
     echo -e "${yellow}Would you like to install them in a separate conda environment? If the problem persists, you can manually install them in the 'install_env' environment and then rerun the assembler.${reset}"
     read -rp "${yellow}Please provide your answer here (yes/no): " yesno
if [ "$yesno" == "yes" ]; then
activate_conda
else
echo -e "${red}Please install the programs manually!"
fi
else
echo -e "${green}status ...................ok!.${reset}"
fi
############################################################################################
########################Percentage alignment calculation using Bowtie2
# Change to current directory
cd "$current_dir" || exit
# Taking path to reference genome
cd plentyofbugs.out &&
reference_path=$(cat best_reference | awk '{print $1}') &&
# Change path to current directory
cd "$current_dir" || exit
# Make bowtie2 directory
mkdir bowtie2.out || exit
# Change directory to bowtie2
cd bowtie2.out  || exit
# Do percentage alignment calculations
if command -v bowtie2  &>/dev/null; then
echo "${green}Bowtie2 is installed${reset}"
echo "${green}Executing Bowtie2${reset}"
echo "${green}Indexing reference genome${reset}"
# Indexing reference genomes
bowtie2-build -f "$reference_path"  reference_index &&
bowtie2build_pid=$!
wait $bowtie2build_pid
# Change to current directory
cd "$current_dir" || exit
# Change path to trimmomatic.out
cd trimmomatic.out &&
trimmomatic_output_path=$(pwd) &&
# Change to current directory
cd "$current_dir" || exit
# Change path to bowtie2.out
cd bowtie2.out || exit
bowtie2 -x  reference_index -1 "$trimmomatic_output_path/output_1P.fq" -2 "$trimmomatic_output_path/output_2P.fq" -S out.sam &&
bowtie2_pid=$!
wait $bowtie2_pid
else
echo "${red}Error: Bowtie2 is not installed. Please install Bowtie2 and try again.${reset}"
exit 1
# Change to current directory
cd "$current_dir" 
fi || exit 
#########################################################################
# Check if all the command exist
# Check for flash if not found store its path in a variable
if command -v flash &>/dev/null; then
echo -e "${green}flash is installed...${reset}"
else
#ask for flash path
echo -e "${yellow} Please provide absolute path to flash...${reset}"
read -rp "please provide your flash path here : " flash
fi || exit
#check for seqtk if not found store its path in a variable
if command -v seqtk &>/dev/null; then
echo -e "${green} seqtk is installed...${reset}"
else
# ask for path
echo "${red} Please install seqtk...${reset}"
fi || exit
#check for AlignGraph if not found store its path in a variable
if command -v AlignGraph &>/dev/null; then
echo -e "${green} AlignGraph is installed...${reset}"
else
# ask to AlignGraph 
echo -e "${red} Please install AlignGraph...${reset}"
fi || exit
# Check for spades
if command -v spades &>/dev/null; then
echo -e "${green} spades is installed...${reset}"
else
# ask for spades path
echo -e "${yellow} Please provide absolute path to spades...${reset}"
read -rp "Please provide your absolute path here: " spadespath
fi || exit
# Check for unicycler if not
if command -v unicycler &>/dev/null; then
echo -e "${green} unicycler is installed...${reset}"
else
# ask for unicycler path
echo -e "${yellow} Please provide absolute path to unicycler...${reset}"
read -rp "Please provide your absolute path here: " unicycler
fi || exit
####################################################################################
# Store the original directory
cd "$current_dir" || exit 
#make directory for denovo assembly
mkdir denovo_assembly || exit
# Store the original directory
cd "$current_dir" || exit 
# Denovo Assembly
cd trimmomatic.out || exit
paired_read=$(pwd) || exit
cd "$current_dir"  || exit
######################################################################################
# move to de novo assembly directory and capture path
cd denovo_assembly &&
denovo_assembly_path=$(pwd) &&
######################################################################################
if command -v flash &>/dev/null; then
# ask for input parameters
echo -e "${yellow} Please provide max-overlap input...${reset}"
read -rp "Please provide your max-overlap input (example 150) here : " max_overlap
echo -e "${green} running flash...${reset}"
flash --max-overlap "$max_overlap" "$paired_read/output_1P.fq" "$paired_read/output_2P.fq" > output -d "$PWD"
else
ask for flash path
echo -e "${yellow} Please provide absolute path to flash...${reset}"
read -rp "please provide your flash path here : " flash
read -rp "Please provide your max-overlap input (example 150) here : " max_overlap
echo -e "${green} running flash...${reset}"
"$flash"  --max-overlap "$max_overlap" "$paired_read/output_1P.fq" "$paired_read/output_2P.fq" > output -d "$PWD"
fi || exit
#wait for flash process to complete
flash_pid=$!
wait $flash_pid
# Run unicycler command
if command -v unicycler &>/dev/null && command -v spades &>/dev/null; then
unicycler -1 "$denovo_assembly_path/out.notCombined_1.fastq" -2 "$denovo_assembly_path/out.notCombined_2.fastq" -s "$denovo_assembly_path/out.extendedFrags.fastq" -o unicycler.out 
else
echo -e "${yellow} Please provide absolute path to unicycler...${reset}"
read -rp "Please provide your unicycler path here : " unicycler
echo -e "${yellow} Please provide your absolute spades path here...${reset}"
read -rp "Please provide your spades path here : " spadespath
echo -e "${green} executing unicycler...${reset}"
"$unicycler" --spades_path "$spadespath" -1 "$denovo_assembly_path/out.notCombined_1.fastq" -2 "$denovo_assembly_path/out.notCombined_2.fastq" -s "$denovo_assembly_path/out.extendedFrags.fastq" -o unicycler.out 
fi || exit
cd unicycler.out || exit
assemblypath=$(pwd)
# Return to the original directory
cd "$current_dir" || exit
##################################################################################
# Reference Based Assembly
cd plentyofbugs.out || exit
reference_genome=$(cat best_reference | awk '{print $1}')
cd "$current_dir" || exit
cd "$current_dir"/plentyofbugs.out/assembly/ || exit
contigpath=$(pwd)
cd "$current_dir" || exit
cd trimmomatic.out &&
trimmed_read=$(pwd)
cd "$current_dir" || exit
# make directory for reference based assembly
mkdir reference_based_assembly &&
cd reference_based_assembly || exit
if command -v seqtk &>/dev/null && command -v AlignGraph &>/dev/null; then
echo -e "${green}Running seqtk to convert fastq files to fasta files${reset}"
seqtk seq -A "$trimmed_read/output_1P.fq" > output_1P.fa &&
seqtk seq -A "$trimmed_read/output_2P.fq" > output_2P.fa &&
seqtk_pid=$!
wait $seqtk_pid
#######################################################
read -rp "please provide pad_reads_1.py path": pad
read -rp "please provide your raw read length input for parameter: " Pad_read
python "$pad"/pad_reads_1.py  output_1P.fa padded_out1.fa "$Pad_read"
python "$pad"/pad_reads_1.py  output_2P.fa padded_out2.fa "$Pad_read"
#######################################################
echo -e "${yellow} Please provide required input parameters for AlignGraph${reset}"
read -rp "Please provide your input for parameter --distanceLow : "  distancelow
read -rp "please provide your input for parameter --distancehigh : " distancehigh
echo -e "${green} Running AlignGraph${reset}"
AlignGraph --read1 output_1P.fa --read2 output_2P.fa --contig "$contigpath/contigs.fasta" --genome "$reference_genome" --distanceLow "$distancelow" --distanceHigh "$distancehigh" --extendedContig sample_extendedcontig.fasta --remainingContig sample_remainingcontig.fasta
else
echo "${red}please install AlignGraph or seqtk if already installed please make sure they are in you current path${reset}"
fi
cd "$current_dir" || exit
###################################################
# Chande path to reference based assembly
cd reference_base_assembly || exit
reference_based_assembly_path=$(pwd) || exit
cd "$current_dir" || exit
# Use BUSCO for checking completeness
# Make BUSCO directory
mkdir busco || exit
cd busco || exit
# look for busco if installed
reference_base_assembly_path=$(pwd) || exit
cd "$current_dir" || exit
# Use BUSCO for checking completeness
# Make BUSCO directory
mkdir busco || exit
cd busco || exit
# look for busco if installed
if command -v busco &>/dev/null; then
echo "${green}BUSCO is installed.${reset}"
read -rp "Specify the name of the BUSCO lineage to be used: " busco_linage
busco -i "$reference_base_assembly_path"/extendedContigs.fa -m genome  -l "$busco_linage"
busco_pid=$!
wait $busco_pid
else
echo "${red}Please install busco."
fi
cd "$current_dir" || exit
#####################################################################
