# Terminus Demo

This repo is a sample of demo deploy scripts to showcase how Terminus works.

## Terminus Deploy sequence
### Dependencies: working terminus environment (assumed), jq 

```bash
./terminus-deploy-sequence.sh <site_id>
```

This will run through a series of deployment functions to pull in the latest updates for an individual site, then deploy those changes out to test and live.

This script also comes with a progress bar for a bit fancier output.

```
./terminus-deploy-sequence.sh dunder-mifflin-drupal
-------- Site Information --------
Name:           Dunder Mifflin Drupal
Upstream:       Drupal 9
Organization:   Dunder Mifflin

- Check upstream updates [✔]
- Setting site connection: git [✔]
- Applying code updates to dev [✔]
- Run drush updb [✔]
- Clear dev cache [✔]
- Deploying to test [✔]
- Deploying to live [✔]
[##########] 100 %

Finished dunder-mifflin-drupal in 0.58 minutes
```

## Terminus SFTP Deployment

```bash
./terminus-deploy-sftp.sh <site_id>
```

When generating a site artifact through an external build process or CI system, you can use this method to sync the code to a Pantheon site through a manual deployment of code, especially if the sites do not share a common git history. This will enable SFTP mode on the site, sync the code, and then commit it on the Pantheon side.

```
./terminus-deploy-sftp.sh dunder-mifflin-drupal
```

## Terminus Git Audit

```
./terminus-git-auditor <upstream ID>
```

The intention of this script is to audit sites created from an upstream to check if their code is in complete compliance with the upstream code, identifying which sites are outdated, or have an altered git state that does not match the upstream, and the produce a report in a CSV format.
