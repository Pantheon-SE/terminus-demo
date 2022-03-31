#!/bin/bash -e

# Usage
# ./terminus-deploy-sftp.sh <site-name or uuid>

# If PANTHEON_SITE is empty, bail.
# PANTHEON_SITE could be provided by a CI as an environmental variable.
# If not, check if one was provided as an inline argument.
if [[ ! -z "$1" ]]; then
    PANTHEON_SITE=$1
fi
if [[ ! -z "$PANTHEON_SITE" ]]; then
    { echo "No Pantheon site name or ID provided."; exit 1; }
fi

# Env info
DEV=$(echo "${PANTHEON_SITE}.dev")
TEST=$(echo "${PANTHEON_SITE}.test")
LIVE=$(echo "${PANTHEON_SITE}.live")

# Site info
SITE_INFO=$(terminus site:info ${SITE} --format json)
SITE_ID=$(echo ${SITE_INFO} | jq -r .id)

# SFTP info
PANTHEON_USER=$(echo "dev.${SITE_ID}")
PANTHEON_HOST=$(echo "appserver.dev.${SITE_ID}.drush.in")
PANTHEON_SFTP=$(echo "${PANTHEON_USER}@${PANTHEON_HOST}")

# Deployment info
COMMIT_MESSAGE=$(git log -1 --pretty=tformat:'%s')

# Push latest code to the dev environment
echo "Ensuring that the dev environment development mode is set to sftp"
terminus connection:set ${DEV} sftp

echo "Pushing code to Pantheon."
# @todo: Instead of StrictHostKeyChecking=no, you can configure ~/.ssh/config file.
# Rsync code artifact over to dev site
rsync -rLvzc --ipv4 --progress -e 'ssh -p 2222 -o StrictHostKeyChecking=no' --exclude-from=".pantheonignore" --delete --temp-dir=~/tmp/ "${ARTIFACT}/" ${PANTHEON_SFTP}:code/

echo "Waiting 30s for changes to properly propagate"
sleep 30

echo "Checking which files have changed in pantheon"
terminus env:diffstat ${DEV}

echo "Commiting changes to the dev environment"
terminus env:commit ${DEV} --message="$COMMIT_MESSAGE"

echo "Clearing DEV cache"
terminus env:clear-cache ${DEV}

# Promote code to the test environment
echo "Promoting code from DEV to TEST"
terminus env:deploy ${TEST} --cc -y --note "$COMMIT_MESSAGE"

echo "Clearing TEST cache"
terminus env:clear-cache ${TEST}
