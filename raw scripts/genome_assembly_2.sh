#!/bin/bash

# Colour coding format for echo
green='\033[0;32m'   # colour coding for green
red='\033[0;31m'     # colour coding for red
yellow='\033[1;33m'  # colour coding for yellow
reset='\033[0m'      # reset colour formatting

# Navigating to trimmomatic directory for trimmed reads
 # Change directory to trimmomatic_output
   current_dir=$(pwd)
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
     
            #install plentyofbugs command not found using pip
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
 ####################################################else block######################################################################## 
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
          
           #Run Plentyofbugs
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
    echo -e "${green}programm run successfully !.${reset}"
fi
                
#######################################################################################################################################################################  
