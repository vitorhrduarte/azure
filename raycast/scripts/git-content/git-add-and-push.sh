#!/bin/bash

#
# IMPORTANT
#
# Need to adapt line 15. 
# The value for: # @raycast.currentDirectoryPath need to reflect the working directory where
# to run the script
#
# Example: ~/repos/scripts
#


# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Git - Add, Commit and Push
# @raycast.mode inline

# Optional parameters:
# @raycast.icon ./images/git.png
# @raycast.packageName Git
# @raycast.currentDirectoryPath ~/repos/scripts
# @raycast.refreshTime 4h


# Documentation:
# @raycast.description Obsidian Git operations - Add, Commit and Push
# @raycast.author 5aturnu5
# @raycast.authorURL https://raycast.com/5aturnu5


STATUS=$(git status --short)

if [ -z "$STATUS" ]; then
  echo "No changes to save"
  exit 1
else
  # Fisrt need to track untracked files
  git add .
  #echo "Track Files" 
  
  # Get the current date in the format YYYY-MM-DD HH:MM:SS
  CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")

  # Commit changes
  git commit --message "vault backup $CURRENT_DATE"
  #echo "Commit Changes"

  # Push to remote
  git push
  echo "Push Changes at $CURRENT_DATE"
fi
