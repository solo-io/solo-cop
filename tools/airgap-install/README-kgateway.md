# Air-gap Installation Image List for Solo Enterprise for kgateway

This utility scripts the functionality to extract all Docker images required for an air-gapped installation of Solo Enterprise for kgateway.

## Pre-requisites

The following packages need to be installed:
- helm (v3.0+)
- yq
- jq
- docker (for pulling images locally)

This script assumes a *nix environment (Mac OS is fine).

## Usage

To run the utility, type:

```bash
./get-kgateway-image-list <version>
```

where **version** is the Solo Enterprise for kgateway version (e.g., `2.1.0-beta.2`).

This will print the list of images to stdout.

## Options

- `-cr | --chart-repo`  - Chart repository (Defaults to `oci://us-docker.pkg.dev/solo-public/gloo-gateway/charts` if not specified)
- `-p  | --pull`        - Execute a Docker pull for all discovered images
- `-sc | --skip-crds`   - Skip CRDs chart processing (By default it will process all charts)
- `-r  | --retain`      - Retain `.images.out` at the end of the run and don't purge it
- `-v  | --validate`    - Validate the discovered Docker repositories
- `-d  | --debug`       - Print script debug info
- `-h  | --help`        - Print help and exit

## How It Works

The script:

1. **Downloads Helm charts** using `helm pull` and `helm template`:
   - CRDs chart: Uses `helm template` to render the CRDs chart
   - Control plane chart: Uses `helm pull` to download the main chart

2. **Extracts images** by:
   - Parsing `values.yaml` files using `yq` and `jq` to find image references
   - Scanning Kubernetes manifests for container images
   - Handling different image formats (registry/repository:tag)

3. **Outputs** a sorted, deduplicated list of all required images

4. **Optionally**:
   - Validates that image repositories exist
   - Pulls images locally using Docker

## Example Output

Example output when specifying version `2.1.0-beta.2`:

```bash
$ ./get-kgateway-image-list 2.1.0-beta.2
Finding images for Solo Enterprise for kgateway version 2.1.0-beta.2

###################################
# Getting CRDs chart              #
###################################

###################################
# Getting control plane chart     #
###################################
gcr.io/gloo-gateway/gloo-gateway:2.1.0-beta.2
gcr.io/gloo-gateway/gloo-gateway-operator:2.1.0-beta.2
...
```

## Example with Image Pulling

To pull all images locally:

```bash
$ ./get-kgateway-image-list -p 2.1.0-beta.2
Finding images for Solo Enterprise for kgateway version 2.1.0-beta.2

###################################
# Getting CRDs chart              #
###################################

###################################
# Getting control plane chart     #
###################################
gcr.io/gloo-gateway/gloo-gateway:2.1.0-beta.2
gcr.io/gloo-gateway/gloo-gateway-operator:2.1.0-beta.2
...

Pulling images locally
2.1.0-beta.2: Pulling from gloo-gateway/gloo-gateway
...
```

## Notes

- The script uses Helm's OCI registry support to pull charts from `us-docker.pkg.dev/solo-public/gloo-gateway/charts`
- Images are extracted from both `values.yaml` files and rendered Kubernetes manifests
- The script automatically cleans up temporary files unless `--retain` is specified
- Version format supports semantic versioning with pre-release tags (e.g., `2.1.0-beta.2`)

