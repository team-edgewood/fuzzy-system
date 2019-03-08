#!/bin/sh

status_code=$(curl --write-out %{http_code} --silent --output /dev/null https://test.team-edgewood.com)

if [ $status_code -ne 200 ]; then
  echo "Bad status code: $status_code"
  exit 1
fi

exit 0
