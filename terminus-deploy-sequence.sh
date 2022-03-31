#!/bin/bash -e
# shellcheck disable=SC1091

# Usage
# ./terminus-deploy-sequence.sh <site-name or uuid>

# Color codes
black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
white=`tput setaf 7`
black_bg=`tput setab 0`
red_bg=`tput setab 1`
green_bg=`tput setab 2`
yellow_bg=`tput setab 3`
blue_bg=`tput setab 4`
reset=`tput sgr0`

SITE=$1
DEV=$(echo "${SITE}.dev")
TEST=$(echo "${SITE}.test")
LIVE=$(echo "${SITE}.live")
START=$SECONDS

declare -rx STEPS=(
  'Check upstream updates'
  'Setting site connection: git'
  'Applying code updates to dev'
  'Run drush updb'
  'Clear dev cache'
  'Deploying to test'
  'Deploying to live'
)
declare -rx CMDS=(
  "terminus site:upstream:clear-cache $SITE -q"
  "terminus connection:set $DEV git -q"
  "terminus upstream:updates:apply $DEV --accept-upstream -q"
  "terminus drush $DEV -q -- updb -y"
  "terminus env:clear-cache $DEV -q"
  "terminus env:deploy $TEST --cc --updatedb -n -q"
  "terminus env:deploy $LIVE --cc --updatedb -n -q"
)

# Extract site info
SITE_INFO=$(terminus site:info ${SITE} --format json)
SITE_NAME=$(echo ${SITE_INFO} | jq -r .label)
SITE_ORG=$(echo ${SITE_INFO} | jq -r .organization)
SITE_UPSTREAM=$(echo ${SITE_INFO} | jq -r .upstream)

# Extract upstream info
IFS=: read -r -a UPSTREAM_ID <<< "$SITE_UPSTREAM"
UPSTREAM=$(terminus upstream:info ${UPSTREAM_ID[0]} --format json)
UPSTREAM_NAME=$(echo ${UPSTREAM} | jq -r .label)

# Extract org info
ORGS=$(terminus orgs --format json)
ORG_NAME=$(echo ${ORGS} | jq -r --arg key ${SITE_ORG} '.[$key].label')

# Debug
echo -e "${green_bg}${black}-------- Site Information --------${reset}
${green}Name:${reset}           ${SITE_NAME}
${green}Upstream:${reset}       ${UPSTREAM_NAME}
${green}Organization:${reset}   ${ORG_NAME}
"

# echo -e "Checking code status...\n"
# STATUS=$(terminus upstream:update:status "${1}.dev")
# echo -e "Code status: ${STATUS}\n"

source progress.sh && start

# Report time to results.
DURATION=$(( SECONDS - START ))
TIME_DIFF=$(bc <<< "scale=2; $DURATION / 60")
MIN=$(printf "%.2f" $TIME_DIFF)
echo -e "\nFinished ${green}${SITE}${reset} in ${yellow}${MIN}${reset} minutes"
