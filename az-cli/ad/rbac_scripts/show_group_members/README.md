# Introduction
This README.md provides detailed information about our Z shell script named 'go.sh'. 
The Z shell script is a shell scripting language designed for interactive use, although it is also a powerful scripting language.

# Script Purpose
This script is designed to show all group members from the group ID that we input and store it in csv file. 

# Dependencies
This script has the following dependencies:
1. Zsh (Z shell): This is the scripting language that the script uses. You can install it on Ubuntu using "sudo apt install zsh". For other systems, see: https://www.zsh.org/
2. fzf
3. awk
4. tr 
5. column

# Parameters
The script accepts the following parameters:
1. -s: 
    |> If we do NOT know the group ID, we type the search string for the group name
    |> If we know the group ID then we type -s <group id> 

2. -y: if we pass this in the script is because we already know the group ID

# Usage
Here's how you can use the 'go.sh' script:

## Get help
./go.sh
./go.sh -h


## We do not know group ID
./go.sh -s store

## We do know the group ID
./go.sh -s <group id> -y
