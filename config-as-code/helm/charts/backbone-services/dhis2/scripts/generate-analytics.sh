#!/usr/bin/env sh
set -eo pipefail

if [ -z "$SERVICE_URL" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "Error: Required environment variables are not set. Please set SERVICE_URL, USERNAME, and PASSWORD."
  exit 1
fi

echo "Waiting for DHIS2 service to be ready... $SERVICE_URL"
curl --fail --silent --show-error --output /dev/null --retry 100 --retry-delay 6 --retry-connrefused "$SERVICE_URL"
echo "DHIS2 is ready!"

curl --fail --silent --show-error --location --user "$USERNAME:$PASSWORD" --request POST $SERVICE_URL/api/resourceTables/analytics
CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -ne 0 ]; then
  echo "Analytics job failed with exit code: $CURL_EXIT_CODE"
  exit $CURL_EXIT_CODE
fi

echo "Analytics job successfully triggered"
