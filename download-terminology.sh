#!/bin/bash

# Define the API endpoints and the output directory
API_URLS=(
    "https://nzhts.digital.health.nz/fhir/CodeSystem"
    "https://nzhts.digital.health.nz/fhir/ValueSet"
)
OUTPUT_DIR="./input/resources"

# Create the output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Delete the contents of the output directory if it exists
rm -rf $OUTPUT_DIR/*

# Fetch data from each API endpoint and process the results
for API_URL in "${API_URLS[@]}"; do
    response=$(curl -s $API_URL)
    echo $response | jq -c '.entry[].resource' | while read -r resource; do
        id=$(echo $resource | jq -r '.id')
        echo $resource | jq '.' > "$OUTPUT_DIR/$id.json"
    done
done

echo "Terminology resources saved"
