# Terminus Demo

This repo is a sample of demo deploy scripts to showcase how Terminus works.

## Deploy sequence

```bash
./terminus-deploy-sequence.sh <site_id>
```

This will run through a series of deployment functions to pull in the latest updates for a site on a custom upstream, then deploy those changes out to test and live.

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
