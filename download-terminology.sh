#!/bin/bash

# script to download terminology resources from NZHTS. Uses curl and jq 
# as using sed, awk, etc. to parse json wasn't a good time

RESOURCETYPE_URLS=(
  "https://nzhts.digital.health.nz/fhir/CodeSystem/"
  "https://nzhts.digital.health.nz/fhir/ValueSet/"
)

# Create directory if it doesn't exist and clear its contents if it does
mkdir -p input/resources/
rm -rf input/resources/*

# Function to call curl and save the response to a file
fetch_and_save() {
  local url=$1
  local output_file=$2
  curl -s "$url" -o "$output_file"
  # Check file size and delete if over 5mb
  file_size=$(stat -c%s "$output_file")
  if [[ $file_size -gt 5242880 ]]; then
    rm -rf "$output_file"
    echo "deleting $output_file as file size is over 5MB (actual size is $file_size)"
  else
    echo "saving $output_file"
  fi
}

# Loop through search of each resource type to save
for base_url in "${RESOURCETYPE_URLS[@]}"; do
  # Fetch the list of resources
  main_response=$(curl -s "$base_url")
  
  # Save the response with the fullUrls to retreive
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

