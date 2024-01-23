# Introduction
This README.md provides detailed information about our Z shell script named 'go.sh'. 
The Z shell script is a shell scripting language designed for interactive use, although it is also a powerful scripting language.

# Script Purpose
This script is designed to help us to find which users are owners for a specific set of azure security groups stored in a csv file.


# Dependencies
This script has the following dependencies:
1. Zsh (Z shell): This is the scripting language that the script uses. You can install it on Ubuntu using "sudo apt install zsh". For other systems, see: https://www.zsh.org/
2. jq
3. awk 

# Parameters
The script accepts the following parameters:
1. -f: define the path and file name that contains the group/s ids 
2. -g: define the group id
3. -h: get help

# Usage
Here's how you can use the 'go.sh' script:

# To get help
./go.sh -h

# To pass just group id
./go.sh -g <<groupID>>

# To pass file name that contains one or more group ids
./go.sh -f list.txt

