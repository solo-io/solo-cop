#!/bin/sh
# generate_protos.sh
protoc -I. \
  --include_imports --include_source_info \
  --descriptor_set_out fortune.pb \
  fortune.proto