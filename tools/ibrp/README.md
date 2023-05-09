# Istio Bug Report Parser

A simple Python script to assist with parsing various aspects of the istioctl bug-report output.

Currently, this script can parse custom resources and nodes.

To parse CRs, this script depends on the standard input of a list of CRs under the heading 'items'.  If this is not 
found, the script will fail.

## Dependencies
Make sure you have Python3 enabled in your path.

You will need to `pip install pyyaml`.

## Running 

```commandline
python3 ibrp.py <operation> <path-to-your-crd-file>
```

Operation will be either 'crparse' or 'nodeparse'.  

### Parsing CRs
Output will go to the crs directory as a child of the current directory.  Each type of custom resource will be created
in a directory named by the type of CR.

Note that for production workloads, parsing can take a few minutes.  The script will provide output on progress.

### Parsing Nodes
Nodes will be parsed to capture the name, roles and cpus.  Output will be sent to stdout.