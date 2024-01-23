# Introduction
This README.md provides detailed information about our Z shell script named 'view_roles_details_for_group_or_user.sh'. 
The Z shell script is a shell scripting language designed for interactive use, although it is also a powerful scripting language.

# Script Purpose
This script is designed to get from AAD teh roles that a user or group ID has attached to by Azure Subscription 
It outputs the results to the STD but also for a file in the corrent execution directory named output.csv

# Dependencies
This script has the following dependencies:
1. Zsh (Z shell): This is the scripting language that the script uses. You can install it on Ubuntu using "sudo apt install zsh". For other systems, see: https://www.zsh.org/
2. jq 

Since this script depends on another script written in python, python 3 and thw following modules need to be installed:
1. Pandas
2. Json


# Parameters
The script accepts the following parameters:
1. i: group or user ID 


# Usage
Here's how you can use the 'view_roles_details_for_group_or_user.sh' script:


./view_roles_details_for_group_or_user.sh -i <group_id>
or
./view_roles_details_for_group_or_user.sh -i <user_id>
