#!/bin/bash

KEYS=("START_TIME" "REQ(:METHOD)  REQ(X-ENVOY-ORIGINAL-PATH?:PATH) PROTOCOL" "RESPONSE_CODE" "RESPONSE_FLAGS" "RESPONSE_CODE_DETAILS" "CONNECTION_TERMINATION_DETAILS" "UPSTREAM_TRANSPORT_FAILURE_REASON" "BYTES_RECEIVED" "BYTES_SENT" "DURATION" "RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)" "REQ(X-FORWARDED-FOR)" "REQ(USER-AGENT)" "REQ(X-REQUEST-ID)" "REQ(:AUTHORITY)" "UPSTREAM_HOST" "UPSTREAM_CLUSTER" "UPSTREAM_LOCAL_ADDRESS" "DOWNSTREAM_LOCAL_ADDRESS" "DOWNSTREAM_REMOTE_ADDRESS" "REQUESTED_SERVER_NAME" "ROUTE_NAME")

# Read a line from a file
read -r line < input.txt

# Remove leading and trailing spaces from the line
line="${line#"${line%%[![:space:]]*}"}"
line="${line%"${line##*[![:space:]]}"}"

# Set the delimiter to space
IFS=' ' read -ra units <<<"$line"

# Initialize variables
in_quote=false
i=0;
# Loop through the units
for unit in "${units[@]}"; do
    if [[ $unit == \"* && $unit != *\" ]]; then
        # Found the start of a quoted sequence
        in_quote=true
        extracted_unit="$unit"
    elif [[ $unit == *\" ]]; then
        # Found the end of a quoted sequence
        in_quote=false
        extracted_unit+=" $unit"
        echo "${KEYS[$i]}: $extracted_unit"
        ((i=i+1))
        extracted_unit=""
    elif [ "$in_quote" = true ]; then
        # Inside a quoted sequence
        extracted_unit+=" $unit"
    else
        # Outside a quoted sequence
        echo "${KEYS[$i]}: $unit"
        ((i=i+1))
    fi
done
