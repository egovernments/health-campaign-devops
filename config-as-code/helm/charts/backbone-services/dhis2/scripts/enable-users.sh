#!/usr/bin/env sh
set -eo pipefail

if [ -z "$SERVICE_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$TARGET_USER" ]; then
  echo "Error: Required environment variables are not set. Please set SERVICE_URL, USERNAME, PASSWORD, and TARGET_USER."
  exit 1
fi

echo "Waiting for DHIS2 service to be ready... $SERVICE_URL"
curl --fail --silent --show-error --output /dev/null --retry 100 --retry-delay 6 --retry-connrefused "$SERVICE_URL"
echo "DHIS2 service is ready."

# TARGET_USER is a comma-separated list of usernames
for target_username in $(echo $TARGET_USER | tr ',' '\n'); do

    user_id=$(curl --fail --silent --show-error --location --user "$USERNAME:$PASSWORD" --request GET "$SERVICE_URL/api/users?fields=id&filter=username:eq:$target_username" | jq -r '.users[0].id')

    if [ -z "$user_id" ] || [ "$user_id" = "null" ]; then
        echo "Error: Failed to get user ID for $target_username. User not found or error in API request."
        exit 1
    fi

    echo "User ID: $user_id"

    # Enable user (show the response if it fails)
    echo "Enabling user $target_username..."
    response=$(curl --fail --silent --show-error --location --user "$USERNAME:$PASSWORD" --request PATCH "$SERVICE_URL/api/users/$user_id" --header "Content-Type: application/json-patch+json" --data '[{"op": "replace", "path": "/disabled", "value": false}]')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to enable user $target_username."
        echo "Response: $response"
        exit 1
    fi

    echo "User $target_username successfully enabled."
done
