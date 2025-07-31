#!/bin/bash

# Exit on any error
set -e

FILE_NAME=$1

if [ -z "$FILE_NAME" ]; then
    echo "Usage: $0 <yaml-file>"
    exit 1
fi

if [ ! -f "$FILE_NAME" ]; then
    echo "Error: File '$FILE_NAME' not found"
    exit 1
fi

echo "Extracting YAML resources from $FILE_NAME..."

# Extract individual YAML resources and create files
yq '.items[]? | select(. != null)' "${FILE_NAME}" | \
  awk 'NR==1{print $0; next} /^apiVersion:/{print "---"} {print $0}' | \
  yq 'del(.metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"],.metadata.creationTimestamp,.metadata.generation,.metadata.managedFields,.metadata.resourceVersion,.metadata.selfLink,.metadata.uid,.status)' | \
  yq -s '.kind + "_" + (.metadata.name|sub("\.","_"))' --no-doc

FILE_NAME_WITHOUT_EXTENSION=$(basename "${FILE_NAME}" | cut -f1 -d.)
OUTPUT_DIR="extracted-files-from-${FILE_NAME_WITHOUT_EXTENSION}"

echo "Organizing files into directories..."

# Count total files to process for progress tracking
total_files=0
for file in *_*.yml; do
    [ ! -f "$file" ] && continue
    if [[ "$file" == "${FILE_NAME}"* ]] || [[ "$file" == *.sh ]] || [[ "$file" == *.yaml ]]; then
        continue
    fi
    ((total_files++))
done

# Find all generated YAML files and organize them by type
current_file=0
for file in *_*.yml; do
    # Skip if no files match the pattern
    [ ! -f "$file" ] && continue
    
    # Extract the type (everything before the first underscore)
    TYPE=$(echo "$file" | cut -f1 -d "_")
    
    # Skip files that are not from our extraction
    if [[ "$file" == "${FILE_NAME}"* ]] || [[ "$file" == *.sh ]] || [[ "$file" == *.yaml ]]; then
        continue
    fi
    
    # Update progress
    ((current_file++))
    percentage=$((current_file * 100 / total_files))
    printf "\rProcessing files: %d/%d (%d%%)" "$current_file" "$total_files" "$percentage"
    
    # Create directory and move file
    mkdir -p "${OUTPUT_DIR}/${TYPE}"
    mv "$file" "${OUTPUT_DIR}/${TYPE}/" || echo -e "\nWarning: Failed to move $file"
done

echo -e "\nExtraction complete! Files organized in: $OUTPUT_DIR"

# Show summary
echo ""
echo "Summary of extracted resources:"
find "$OUTPUT_DIR" -name "*.yml" | cut -d'/' -f2 | sort | uniq -c | sort -nr
