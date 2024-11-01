#!/bin/bash

# download terminology resources from NZHTS via FHIR API

RESOURCES_TO_SAVE=(
  "https://nzhts.digital.health.nz/fhir/CodeSystem/"
)
RESOURCES_TO_EXPAND_AND_SAVE=(
  "https://nzhts.digital.health.nz/fhir/ValueSet/"
)

count_param="&count=100"
nzhts_expansion_prefix="https://nzhts.digital.health.nz/fhir/ValueSet/\$expand?url="
BEARER_TOKEN=""

# Create output directory if it doesn't exist and make sure it's empty
mkdir -p input/resources/
rm -rf input/resources/*

# Make request and save the response to a file
fetch_and_save() {
  local url=$1
  local output_file=$2
  curl -s "$url" -o "$output_file" -H "Authorization: Bearer $BEARER_TOKEN"
  # Check file size and delete if over 5MB
  file_size=$(stat -c%s "$output_file")
  if [[ $file_size -gt 5242880 ]]; then
    rm -rf "$output_file"
    echo "skipping $output_file as file size is over 5MB (actual size is $file_size)"
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
for base_url in "${RESOURCES_TO_SAVE[@]}"; do
  # Fetch the list of resources
  main_response=$(curl -s "$base_url")
  # Save the response with the fullUrls to retreive
  main_output_file="input/resources/$(basename $base_url).json"
  echo "$main_response" > "$main_output_file"
  # Extract fullUrl values and loop through them
  full_urls=$(echo "$main_response" | jq -r '.entry[].fullUrl')
  for full_url in $full_urls; do
    output_file="input/resources/$(basename $full_url).json"
    # Fetch and save each fullUrl response
    fetch_and_save "$full_url" "$output_file"
  done
  rm -rf "$main_output_file"
done

# And do the same but request expansion from resource url and save
for base_url in "${RESOURCES_TO_EXPAND_AND_SAVE[@]}"; do
  main_response=$(curl -s "$base_url")
  main_output_file="input/resources/$(basename $base_url).json"
  echo "$main_response" > "$main_output_file"
  # use the .entry[].resource.url this time
  full_urls=$(echo "$main_response" | jq -r '.entry[].resource.url')
  for full_url in $full_urls; do
    output_file="input/resources/$(basename $full_url).json"
    fetch_and_save "$nzhts_expansion_prefix$full_url$count_param" "$output_file"
     
    # Extract the last part of the URL to use as the id and add to valueset
    id=$(basename "$full_url")
    jq --arg id "$id" '. + {id: $id}' "$output_file" > tmp.$$.json && mv tmp.$$.json "$output_file"

  done
  rm -rf "$main_output_file"
done