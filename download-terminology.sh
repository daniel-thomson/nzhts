#!/bin/bash

# script to download terminology resources from NZHTS. Retrieves list of 
# each resource type from the BASE_URLS list then retrieves each resource 
# by the fullURL and saves them to the input/resources/ directory

# Base URLs
BASE_URLS=(
  "https://nzhts.digital.health.nz/fhir/CodeSystem/"
  "https://nzhts.digital.health.nz/fhir/ValueSet/"

)

# Create directory if it doesn't exist and clear its contents if it does
mkdir -p input/resources/
rm -rf input/resources/*

# Function to make API calls and save responses
fetch_and_save() {
  local url=$1
  local output_file=$2
  curl -s "$url" -o "$output_file"
  echo "saving $output_file"
}

# Loop through base URLs
for base_url in "${BASE_URLS[@]}"; do
  # Fetch the main response
  main_response=$(curl -s "$base_url")
  
  # Save the main response
  main_output_file="input/resources/$(basename $base_url).json"
  echo "$main_response" > "$main_output_file"
  
  # Extract fullUrl values and loop through them
  full_urls=$(echo "$main_response" | jq -r '.entry[].fullUrl')
  for full_url in $full_urls; do
    # Define output file name
    output_file="input/resources/$(basename $full_url).json"
    
    # Fetch and save each fullUrl response
    fetch_and_save "$full_url" "$output_file"
  done
  rm -rf "$main_output_file"
done

# Delete giant nzmt codeSystem
rm -rf input/resources/nzmt.json
