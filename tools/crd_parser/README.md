# crd_parser

A simple Python script to parse the crs file from an Istio bug-report cluster/crs file. 

This script depends on the standard input of a list of CRs under the heading 'items'.  If this is not found, the script 
will fail.

## Dependencies
Make sure you have Python3 enabled in your path.

You will need to `pip install pyyaml`.

## Running 

```commandline
python3 crd_parser.py <path-to-your-crd-file>
```

Output will go to the crs directory as a child of the current directory.  Each type of custom resource will be created
in a directory named by the type of CR.

Note that for production workloads, parsing can take a few minutes.  The script will provide output on progress.