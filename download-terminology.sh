#!/bin/bash

# download terminology resources from NZHTS. Uses jq 
# for json parsing as sed, awk, etc don't do it well

RESOURCETYPE_URLS=(
  "https://nzhts.digital.health.nz/fhir/CodeSystem/"
  "https://nzhts.digital.health.nz/fhir/ValueSet/"
  "https://nzhts.digital.health.nz/fhir/ConceptMap/"
)

# Create directory if it doesn't exist and make sure it's empty
mkdir -p input/resources/
rm -rf input/resources/*

# Function to call curl and save the response to a file
fetch_and_save() {
  local url=$1
  local output_file=$2
  curl -s "$url" -o "$output_file"
  # Check file size and delete if over 5MB
  file_size=$(stat -c%s "$output_file")
  if [[ $file_size -gt 5242880 ]]; then
    rm -rf "$output_file"
    echo "discarding $output_file as file size is over 5MB (actual size is $file_size)"
  else
    echo "saving $output_file"
  fi
}

# Check if jq is installed and install it if it isn't
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Trying to install it..."
  sudo apt update
  sudo apt install -y jq
else
  echo "jq is already installed"
fi

# Loop through search result of each resource type and save each resource
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