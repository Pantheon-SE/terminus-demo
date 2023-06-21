#!/bin/bash -e

# Example usage
# ./terminus-git-auditor.sh <upstream_id>

# Notes
# - This script is intended to be run on Pantheon upstreams.
# - This script assumes you have Terminus installed and configured.
# - This script assumes you are authenticated with Terminus.

# Color codes
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
black_bg=`tput setab 0`
red_bg=`tput setab 1`
green_bg=`tput setab 2`
yellow_bg=`tput setab 3`
blue_bg=`tput setab 4`
magenta_bg=`tput setab 5`
cyan_bg=`tput setab 6`
white_bg=`tput setab 7`
reset=`tput sgr0`

# tput setab [1-7] # Set the background color using ANSI escape
# tput setaf [1-7] # Set the foreground color using ANSI escape
# Num  Color
# 0    black
# 1    red
# 2    green
# 3    yellow
# 4    blue
# 5    magenta
# 6    cyan
# 7    white

# Take upstream id as argument.
UPSTREAM_ID=$1

# Environment to check against
SITE_ENV="dev"

# Upstream info
UPSTREAM=$(terminus upstream:info ${1} --format json)

# Extract upstream info
UPSTREAM_NAME=$(echo ${UPSTREAM} | jq -r .machine_name)
UPSTREAM_GIT=$(echo ${UPSTREAM} | jq -r .repository_url)
UPSTREAM_ORG=$(echo ${UPSTREAM} | jq -r .organization)

# Set audit file name / path.
AUDIT_FILE=$(echo "/tmp/$UPSTREAM_NAME-git-audit.csv")

# Debug
echo "${green_bg}${black}--- Upstream Information ---${reset}
${green}Name:${reset}           ${UPSTREAM_NAME}
${green}Organization:${reset}   ${UPSTREAM_ORG}
${green}Git:${reset}            ${UPSTREAM_GIT}"

# Clone upstream
echo ""
echo "${green}Cloning the upstream...${reset}"
git clone -b master --single-branch ${UPSTREAM_GIT} ${UPSTREAM_NAME}
cd ${UPSTREAM_NAME}

# Define the signal handler function
cleanup() {
  echo "Performing cleanup before script exit..."
  cd ../
  rm -rf ${UPSTREAM_NAME}
}

# Set the trap to execute the cleanup function
trap cleanup EXIT

# Get upstream site list
echo ""
echo "${green}Getting upstream site list...${reset}"
SITES=$(terminus org:site:list "${UPSTREAM_ORG}" --format=json --upstream "${UPSTREAM_ID}" --filter="frozen!=1")

# Loop through site ID, get git info, add remote.
jq -n "$SITES" | jq '. | to_entries | .[].key' | while read i; do
    # Extract site info
    SITE_ID=$(echo ${i} | tr -d '"')
    SITE=$(jq -n "$SITES" | jq -r .${i})
    SITE_NAME=$(echo ${SITE} | jq -r .name)
    SITE_GIT="ssh://codeserver.dev.${SITE_ID}@codeserver.dev.${SITE_ID}.drush.in:2222/~/repository.git"
    SITE_HOST="codeserver.dev.${SITE_ID}.drush.in"

    # Ensure site is in Git mode
    terminus connection:set "${SITE_ID}.${SITE_ENV}" git --yes

    # Add git remote
    echo "Add git remote for ${yellow}${SITE_NAME}${reset}..."
    git remote add ${SITE_NAME} ${SITE_GIT}
done

# Wait for processes to complete.
wait

# Fetches all remotes
echo ""
echo "${green}Fetching all remotes...${reset}"
GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git fetch --all --quiet

# Set git renameLimit to avoid later errors in diff generation
echo ""
echo "${red_bg}${white}Setting git diff.renameLimit to avoid diff errors...${reset}"
git config diff.renamelimit 25000

# Set up CSV for reporting
echo ""
echo "${green}Setting up the CSV for reporting...${reset}"
if test -f "$AUDIT_FILE"; then
    echo "$AUDIT_FILE exists. ${red}Resetting file...${reset}"
    rm $AUDIT_FILE
fi

touch $AUDIT_FILE
echo "id,name,upstream,upstream_status,diff_status" >> $AUDIT_FILE

# Loop through site ID, get git info, check diff.
jq -n "$SITES" | jq '. | to_entries | .[].key' | while read i; do

    # Extract site info
    SITE_ID=$(echo ${i} | tr -d '"')
    SITE=$(jq -n "$SITES" | jq -r .${i})
    SITE_NAME=$(echo ${SITE} | jq -r .name)

    # Ensure live environment is initialized
    LIVE_CHECK=$(terminus env:info "${SITE_NAME}.${SITE_ENV}" --format=json)
    if [[ "$(echo ${LIVE_CHECK} | jq -r .initialized)" == "false" ]]; then
        echo "${yellow}${SITE_NAME}.live is not initialized. Skipping...${reset}"
        continue
    fi

    # Get upstream status
    echo "Getting upstream status for ${yellow}${SITE_NAME}${reset}..."
    UPSTREAM_STATUS=$(terminus upstream:updates:status ${SITE_ID}.${SITE_ENV})

    # Use dev for debugging.
    # UPSTREAM_STATUS=$(terminus upstream:updates:status ${SITE_ID}.dev)

    # Get diff of each remote
    echo "Getting diff for ${yellow}${SITE_NAME}${reset}..."
    OUTPUT=$(git diff origin/master ${SITE_NAME}/master --shortstat)
    DIFF_LEN=${#OUTPUT}
    
    # Check if diff exists.
    DIFF_STATUS='NO_DIFF'
    if [ $DIFF_LEN -gt 0 ]; then
        DIFF_STATUS='DIFF'
    fi

    if [[ $DIFF_STATUS == "DIFF" ]]; then
        echo "${red}Diff found for ${yellow}${SITE_NAME}...${reset}"
    fi
    
    echo "${SITE_ID},${SITE_NAME},${UPSTREAM_NAME},${UPSTREAM_STATUS},${DIFF_STATUS}" >> $AUDIT_FILE
done

# Wait for processes to complete.
wait

# Print audit status and path to results.
echo "${green}Audit complete, results here:${reset} ${AUDIT_FILE}"
