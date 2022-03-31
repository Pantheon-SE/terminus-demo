#!/bin/bash -e
# shellcheck disable=SC1091

# This can be used as a framework for adding a progress bar to your scripts.
# Requires progress.sh script in this repo.

# Declare the labels for the steps
declare -rx STEPS=(
  'Terminus step 1'
  'Terminus step 2'
  'Terminus step 3'
)

# Declare the commands associated with the labels
declare -rx CMDS=(
  'terminus command:example:1'
  'terminus command:example:2'
  'terminus command:example:3'
)

source progress.sh && start