# Introduction
This README.md provides detailed information about our Z shell script named 'go.sh'.
The Z shell script is a shell scripting language designed for interactive use, although it is also a powerful scripting language.

# Script Purpose
This script is designed to:

#1 if you dont know the user/group id then you need to fisrt search by its name or at least some part of the name
#2 if you know the user/group id then just use it. It will speed up a lot this script execution time.
#3 it will store the output in a csv file named as 'get_user_group_details.csv'


# Dependencies
This script has the following dependencies:
1. Zsh (Z shell): This is the scripting language that the script uses. You can install it on Ubuntu using "sudo apt install zsh". For other systems, see: https://www.zsh.org/

# Parameters
The script accepts the following parameters:
1. -s: 
    |-> if "-y" is not there then just type some part of the user/group name
    |-> if "-y" is there then jsut type/paste the user/group ID
 
2. -h: To get help

3. -y: is present means that you already know the desired principal id (user/group)


# Usage
Here's how you can use the 'go.sh' script:

./go.sh -s store-dev

./go.sh -h same as ./go.sh

./go -s <PRINCIPAL_ID> -y
