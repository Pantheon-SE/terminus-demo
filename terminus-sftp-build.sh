# Push latest code to the dev environment
echo "Ensuring that the dev environment development mode is set to sftp"
terminus connection:set ${PANTHEON_SITE}.$PANTHEON_ENVIRONMENT sftp

echo "Pushing code to pantheon."
# TODO: find a better solution than setting StrictHostKeyChecking=no
rsync -rLvzc --ipv4 --progress -e 'ssh -p 2222 -o StrictHostKeyChecking=no' --exclude-from=".pantheonignore" --delete --temp-dir=~/tmp/ "${ARTIFACT}/" ${PANTHEON_USER}@${PANTHEON_HOST}:code/

echo "Waiting 30s for changes to properly propagate on patheon's side"
sleep 30

echo "Checking which files have changed in pantheon"
terminus env:diffstat ${PANTHEON_SITE}.${PANTHEON_ENVIRONMENT}

echo "Commiting changes to the dev environment"
terminus env:commit ${PANTHEON_SITE}.${PANTHEON_ENVIRONMENT} --message="$PANTHEON_COMMIT_MESSAGE"

echo "Clearing DEV cache"
terminus env:clear-cache ${PANTHEON_SITE}.${PANTHEON_ENVIRONMENT}

# Promote code to the test environment
echo "Promoting code from DEV to TEST"
terminus env:deploy ${PANTHEON_SITE}.test --cc -y --note "$PANTHEON_COMMIT_MESSAGE"

echo "Clearing TEST cache"
terminus env:clear-cache ${PANTHEON_SITE}.test
