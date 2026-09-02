#!/usr/bin/env sh

set -eo pipefail

if [ -z "$SERVICE_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$APPS" ]; then
  echo "Error: Required environment variables are not set. Please set SERVICE_URL, USERNAME, PASSWORD, and APPS."
  exit 1
fi

echo "Waiting for DHIS2 service to be ready... $SERVICE_URL"
curl --fail --silent --show-error --output /dev/null --retry 100 --retry-delay 6 --retry-connrefused "$SERVICE_URL"
echo "DHIS2 service is ready."

# then identify the target apps from the APPS array, based on name and version

echo "Fetching the list of all available apps..."
app_list_url="https://apps.dhis2.org/api/v2/apps?pageSize=1000"
all_apps_raw=$(curl --silent --show-error "$app_list_url")
all_apps=$(echo "$all_apps_raw" | jq -r '.result')

if [ -z "$all_apps" ] || [ "$all_apps" = "null" ]; then
  echo "Error: Failed to fetch the list of apps from the App Hub."
  exit 1
fi

echo "Installing apps..."

failed_apps=""

while read -r app; do
  app_name=$(echo "$app" | jq -r '.name')
  app_version=$(echo "$app" | jq -r '.version')

  echo "Processing app: $app_name version $app_version"

  app_info=$(echo "$all_apps" | jq -r ".[] | select(.name==\"$app_name\")")
  
  if [ -z "$app_info" ] || [ "$app_info" = "null" ]; then
    echo "Error: App '$app_name' not found in the App Hub. Skipping."
    failed_apps="$failed_apps $app_name."
    continue
  fi

  if [ "$app_version" = "latest" ]; then
    version_id=$(echo "$app_info" | jq -r '.versions[0].id')
  else
    version_id=$(echo "$app_info" | jq -r ".versions[] | select(.version==\"$app_version\") | .id")
  fi

  if [ -z "$version_id" ] || [ "$version_id" = "null" ]; then
    echo "Error: Could not find version '$app_version' for app '$app_name'. Skipping."
    failed_apps="$failed_apps $app_name."
    continue
  fi
  
  echo "Found version ID: $version_id"
  
  echo "Installing $app_name version $app_version..."
  if curl --fail --silent --show-error --user "$USERNAME:$PASSWORD" --request POST "$SERVICE_URL/api/appHub/$version_id"; then
    echo "Successfully installed $app_name version $app_version"
  else
    echo "Error: Failed to install $app_name version $app_version. Skipping."
    failed_apps="$failed_apps $app_name."
  fi
done << EOL
$(echo "$APPS" | jq -c '.[]')
EOL

if [ -n "$failed_apps" ]; then
  echo "The following apps failed to install:$failed_apps"
  exit 1
fi

echo "All apps installed successfully."
