#!/bin/bash

# Define a function to show the help menu
show_help() {
  echo "Usage: $(basename "$0") [-h] [-n name_filter]"
  echo "List available Azure subscriptions and set the active subscription."
  echo ""
  echo "Options:"
  echo "  -h, --help         Show this help message and exit."
  echo "  -n name_filter     Filter subscriptions by name (case-insensitive)."
  echo ""
}


# Parse command-line arguments
while getopts ":hn:" opt; do
  case $opt in
    h)
      show_help
      exit 0
      ;;
    n)
      name_filter=$(echo "$OPTARG")
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done







# List available subscriptions matching the name filter
if [ -z "$name_filter" ]; then
  az account list --output table --query '[].{Name:name, ID:id, State:state}'
else
  subscription=$(az account list --output json | \
      jq -r --arg name_filter "$name_filter" '.[] | select(.name | test("(?i)" + $name_filter)) | [.name, .id, .state] | @tsv' | \
      sort -k1 | \
      fzf --delimiter $'\t' --with-nth 1,2 --preview 'echo {} | cut -f2 | xargs az account show -s')
fi

# Exit if no subscription is selected
if [ -z "$subscription" ]; then
  exit 0
fi

# Set the chosen subscription as the active subscription
az account set --subscription "$(echo "$subscription" | cut -f2)"

echo ""
echo ""

# Confirm the active subscription

az account show -o json | jq -r '(["SUB-NAME","SUB-STATUS","SUB-ID"] | (., map(length*"-"))),(. | [.name, .state, .id]) | join(";")' | column -t -s ";"
