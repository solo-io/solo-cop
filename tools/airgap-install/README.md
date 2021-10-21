# Air-gap Installation Image List
This utility scripts the functionality found in the Gloo Mesh Enterprise [documentation](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/installation/airgap_install/).  

## Pre-requisites
The following packages need to be installed.
- wget
- yq
- jq

This script assumes a *nix environment (Mac OS is fine).

To run the utility, type

```
./get-image-list <version>
```

where <version> is the Gloo Mesh Enterprise version (e.g. 1.1.6).

This will print the list of images to stdout.