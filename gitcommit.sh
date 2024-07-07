#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE_VL='\033[38;2;255;200;0m'  # Very Light Orange
ORANGE_L='\033[38;2;255;165;0m'   # Light Orange
ORANGE_ML='\033[38;2;255;140;0m'  # Medium Light Orange
ORANGE_MD='\033[38;2;255;115;0m'  # Medium Dark Orange
ORANGE_D='\033[38;2;255;90;0m'    # Dark Orange
ORANGE_VD='\033[38;2;255;69;0m'   # Very Dark Orange
NC='\033[0m' # No Color

printf "\n\n${BLUE}Welcome to the automated Aleks Multi Platform Git Commit With ToDoList Script${NC}\n"
printf "${BLUE}(Also known as AMPGCWTS, a memorable acronym)${NC}\n\n"

# Check if a commit message was provided as an argument
if [ $# -gt 0 ]; then
  git_comment="$*"
else
  git_comment=""
fi

# Prompt for a commit message, pre-filling with the argument if one was provided
read -e -p "$(printf "${ORANGE_VL}Write Git Comment unless you like what is in brackets\n [${git_comment}]:\n ${NC}")" input
git_comment=${input:-$git_comment}

printf "${ORANGE_ML}Starting Git Commit ...${NC}\n"
git add .
printf "${ORANGE_MD}Added Files, committing ...${NC}\n"
if git commit -m "$git_comment"; then
printf "${ORANGE_D}Git Pushing ...${NC}\n"

  if git push; then
    printf "${GREEN}Git Commit Done!${NC}\n"
  else
    printf "${RED}Git push failed. Exiting.${NC}\n"
    exit 1
  fi
else
  printf "${RED}Git commit failed. Exiting.${NC}\n"
  exit 1
fi
