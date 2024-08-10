#!/bin/bash
###############################################
#colour coding format for echo 
green='\033[0;32m'  #colour coding for green 
red='\033[0;31m'    #colour coding for red
yellow='\033[1;33m' #colour coding for yellow
reset='\033[0m'     #reset colour
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
# wait for command to run using wait command
   fastqc_pid=$! 
   wait $fastqc_pid
fi || exit 
echo -e "${green} fastqc run sucessfully..."
#############################################################
# use multiqc to compile results
mkdir multiqc.out && #create a directory named multiqc.out
# navigate into the directory named multiqc.out

  if command -v multiqc $>/dev/null; then # check for multiqc programme 
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
# wait for command to run using wait command
     multiqc_pid=$!
     wait $multiqc_pid
fi || exit
echo -e "${green} multiqc run sucessfully...${reset}"
###############################################################

#use trimmomatic to trim unpaired reads and remove adapter sequences 
 # check for java   
if command -v java $>/dev/null; then
   echo -e "${green} java installed...${reset}"
   else # if not installed ask for installation
   echo -e "${red}Please install java and check if installed already check if it is present in your path..."
fi || exit 
 #make directory for trimmomatic
 echo -e "${green}makeing output directory for trimmomatic...${reset}"
 mkdir trimmomatic.out && 
   #check for trimmomatic
    #taking parameters using if else statement
     #navigate to trimmomatic.out directory and captute its path
if command -v trimmomatic $>/dev/null; then # check for trimmomatic  
   echo -e "${green} Trimmomatic programme is installed...${reset}"
   echo -e "${yellow} Please provide the relevent parameters for the tools...${reset}"
   read -rp "Pleae provide number of threads to run the tool : " thread
   read -rp "Please provide phread score : " phread
   read -rp "Please provide path to adapter file..." PATH_TO_ADAPTER_CONTAM_FILE
   read -rp "Please provide parameter LEADING: " leading
   read -rp "Please provide parameter TRAILING: " trailing
   read -rp "Please provide parameter SLIDINGWINDOW: " slidingwindow 
   read -rp "Please provide parameter MINLEN: " minlength
   echo -e "${green} executing Trimmomatic...${reset}"
trimmomtic PE -threads "$thread" -phred"$phread" "$forward_read" "$reverse_read" output_1P.fq output_1U.fq output_2P.fq output_2U.fq ILLUMINACLIP:"$PATH_TO_ADAPTER_CONTAM_FILE":2:30:10 LEADING:"$leading" TRAILING:"$trailing" SLIDINGWINDOW:"$slidingwindow" MINLEN:"$minlength" || exit 1  #To remove low quality base pairs and adapter sequences
   else # ask path to the trimmomatic programme path
   echo -e "${red} please install trimmomatic and check if already installed check if it is present in your path...${reset}"
   echo -e "${yellow} Please provide the absolute path to the trimmomatic executable here : ${reset}"
   read -rp "Please provide your trimmomatic path here : " trimmomatic 
   echo -e "${yellow} Please provide the relevent parameters for the tools...${reset}"
   read -rp "Pleae provide number of threads to run the tool : " thread
   read -rp "Please provide phread score : " phread
   read -rp "Please provide path to adapter file :" PATH_TO_ADAPTER_CONTAM_FILE
   read -rp "Please provide parameter LEADING: " leading
   read -rp "Please provide parameter TRAILING: " trailing
   read -rp "Please provide parameter SLIDINGWINDOW: " slidingwindow
   read -rp "Please provide parameter MINLEN: " minlength
   echo -e "${green}executing Trimmomatic...${reset}"
  java -jar "$trimmomatic" PE -threads "$thread" -phred"$phread" "$forward_read" "$reverse_read" output_1P.fq output_1U.fq output_2P.fq output_2U.fq ILLUMINACLIP:"$PATH_TO_ADAPTER_CONTAM_FILE":2:30:10 LEADING:"$leading" TRAILING:"$trailing" SLIDINGWINDOW:"$slidingwindow" MINLEN:"$minlength" || exit 1   #To remove low quality base pairs and adapter sequences
fi || exit 
#wait for the command to be compleated
trimmomatic_pid=$!
wait $trimmomatic_pid
#move all output  to trimmomatic.out directory
mv output_1P.fq output_1U.fq output_2P.fq output_2U.fq trimmomatic.out/ &&
#capturing path of trimmomatic.out directory
cd trimmomatic.out && # navigate to trimmomatic directory
trimmomatic_path=$(pwd) && # capturing directory path of trimmed reads 
cd "$current_dir" || exit 1
#########################################################################################################
# Merging of Overlapping Paired-end Reads using FLASH
 #checking if flash is installed 
  #using if else statement to check and run command
   #make directory for flash output
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
#wait for the command to compleated 
flash_pid=$! 
wait $flash_pid
#capture flash path
flash_path=$(pwd) &&  #use this in unicycler command to get extended frags
#change to the old directory
cd "$current_dir" &&
############################################################################################################# 
#De novo Genome Assembly using Unicycler
 #check if unicycler is installed 
  #using if else statement to check and run command
   #make directory for unicycler output
# Make directory for unicycler output
mkdir unicycler.out && cd unicycler.out || exit

# Check if both unicycler and spades are installed
if command -v spades &>/dev/null && command -v unicycler &>/dev/null; then
   echo -e "${green}Both spades and unicycler are installed.${reset}"
   unicycler  -1 "$trimmomatic_path/output_1P.fq" \
              -2 "$trimmomatic_path/output_2P.fq" -s "$flash_path/out.extendedFrags.fastq" \
              -o assembly || exit 1
   fi || exit 
# Check if neither unicycler nor spades are installed
if ! command -v spades &>/dev/null && ! command -v unicycler &>/dev/null; then
   echo -e "${red}Both unicycler and spades are not installed.${reset}"
   echo -e "${yellow}Please provide absolute paths to unicycler and spades.${reset}"
   read -rp "Please provide absolute path to spades: " spades
   read -rp "Please provide absolute path to unicycler: " unicycler
   echo -e "${green}Running unicycler.${reset}"
   "$unicycler" --spades_path "$spades" -1 "$trimmomatic_path/output_1P.fq" \
                -2 "$trimmomatic_path/output_2P.fq" -s "$flash_path/out.extendedFrags.fastq" \
                -o assembly || exit 1
fi || exit 

# Check if unicycler is installed but spades is not installed
if ! command -v spades &>/dev/null && command -v unicycler &>/dev/null; then
   echo -e "${red}Spades is not installed.${reset}"
   echo -e "${yellow}Please provide absolute path to spades.${reset}"
   read -rp "Please provide absolute path to spades: " spades
   echo -e "${green}Running unicycler.${reset}"
   unicycler --spades_path "$spades" -1 "$trimmomatic_path/output_1P.fq" \
             -2 "$trimmomatic_path/output_2P.fq" -s "$flash_path/out.extendedFrags.fastq" \
             -o assembly || exit 1
fi || exit 

# Check if spades is installed but unicycler is not installed
if command -v spades &>/dev/null && ! command -v unicycler &>/dev/null; then
   echo -e "${red}Unicycler is not installed.${reset}"
   echo -e "${yellow}Please provide absolute path to unicycler.${reset}"
   read -rp "Please provide absolute path to unicycler: " unicycler
   echo -e "${green}Running unicycler.${reset}"
   "$unicycler" -1 "$trimmomatic_path/output_1P.fq" \
                -2 "$trimmomatic_path/output_2P.fq" -s "$flash_path/out.extendedFrags.fastq" \
                -o assembly || exit 1
fi || exit 
cd assembly &&
assemblypath=$(pwd)
#wait for unicycler command to complete  
unicycler_pid=$!
wait $unicycler_pid
#navigate to old directory
cd "$current_dir" 
#######################################################################################
#Assessment of Assembly Quality using QUAST
 #make quast output directory
mkdir quast.out &&
cd quast.out &&
 #check if quast is installed 
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
#wait for quast command to complete
quast_pid=$!
wait $quast_pid 
# Print completion message
echo -e "${green} Pipeline completed successfully!${reset}"
