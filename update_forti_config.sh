#!/bin/bash

set -e


PROVIDER_FILE="${1:-provider.tf}"

extract_provider_config() {
    local provider_name="$1"
    local config_key="$2"
    local provider_file="$3"
    
    # Extract the provider block and then find the specific key
    sed -n "/provider \"$provider_name\"/,/^}/p" "$provider_file" | \
    grep "$config_key" | \
    sed 's/.*'"$config_key"'[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/' | \
    head -1
}

# Extract ZedCloud provider configurations

ZEDCLOUD_URL=$(extract_provider_config "zedcloud" "zedcloud_url" "$PROVIDER_FILE")
ZEDCLOUD_TOKEN=$(extract_provider_config "zedcloud" "zedcloud_token" "$PROVIDER_FILE")

# Remove any remaining quotes and whitespace
ZEDCLOUD_URL=$(echo "$ZEDCLOUD_URL" | tr -d '"' | xargs)
ZEDCLOUD_TOKEN=$(echo "$ZEDCLOUD_TOKEN" | tr -d '"' | xargs)

# Output
echo "ZedCloud URL: $ZEDCLOUD_URL"
echo "ZedCloud Token: $ZEDCLOUD_TOKEN" 

# Capture the script start time in epoch seconds
export TZ="Europe/Lisbon"
start_time=$(date -u +"%s")
start_time_formatted=$(date '+%Y-%m-%d %H:%M:%S %z %Z')
echo "Script start time: $start_time_formatted"

# Run Terraform apply
echo "Running terraform apply..."
if ! terraform apply -auto-approve; then
    echo "ERROR: Terraform apply failed!" >&2
    exit 1
fi
echo "Terraform apply completed successfully."

# Extract list of sidecar app. ids Terraform output
endpoints=$(terraform output -json application_instance_details | jq -r '.[]')

echo "These is the list of Sidecar app endpoints: $endpoints"

all_successful=true

for id in $endpoints; do
  echo "Checking Opaque status for sidecar app $id..."
  
  # Polling configuration
  max_attempts=60
  wait_interval=2  # 2 seconds
  attempt=1
  config_success=false
  
  while [ $attempt -le $max_attempts ] && [ "$config_success" = false ]; do
    echo "Attempt $attempt/$max_attempts for sidecar app $id..."
    
    # Get response body
    response=$(curl -s "$ZEDCLOUD_URL/api/v1/apps/instances/id/$id/opaque-status" \
      -H "Authorization: Bearer $ZEDCLOUD_TOKEN" \
      -H "Accept: application/json")

    # Check if the response is empty
    if [ -z "$response" ]; then
      echo "ERROR: No response received for sidecar app $id (attempt $attempt)" >&2
      if [ $attempt -eq $max_attempts ]; then
        all_successful=false
        break
      fi
      echo "Waiting $wait_interval seconds before retry..."
      sleep $wait_interval
      attempt=$((attempt + 1))
      continue
    fi

    #echo "Response for $id: $response"

    decoded_response=$(echo "$response" | jq -r '.opaqueAppInstanceStatus | @base64d')
    decoded_response=$(echo "$decoded_response" | jq -r '.status | @base64d')

    #check if the decoded_response contains "Configuration was applied successfully" 
    # 2025-08-02 17:42:16 +0100 WEST Configuration was applied successfully
    if [[ "$decoded_response" == *"Configuration was applied successfuly"* ]]; then
        
        # Extract timestamp from the decoded_response string
        # Format: "2025-08-02 17:42:16 +0100 WEST Configuration was applied successfully"
        timestamp=$(echo "$decoded_response" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}')
        
        if [ -n "$timestamp" ]; then
            echo "Configuration timestamp: $timestamp"
            
            # Convert timestamp to epoch seconds for comparison (macOS compatible)
            response_time=$(date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" "+%s" 2>/dev/null || echo "0")
            
            if [ "$response_time" -gt 0 ] && [ "$response_time" -gt "$start_time" ]; then
                echo "✅ Configuration applied successfully for sidecar app $id"
                echo "✅ Timestamp ($timestamp) is newer than script start time"
                config_success=true
                break
            else
                echo "⚠️  Timestamp ($timestamp) is older than script start time - waiting for newer configuration..."
            fi
        else
            echo "⚠️  Could not extract timestamp from response - retrying..."
        fi
    else
        echo "❌ Configuration not yet applied for sidecar app $id: $decoded_response"
        echo "Waiting for configuration to be applied..."
    fi
    
    if [ $attempt -lt $max_attempts ]; then
      echo "Waiting $wait_interval seconds before next check..."
      sleep $wait_interval
    fi
    attempt=$((attempt + 1))
  done
  
  # Check if we succeeded or failed after all attempts
  if [ "$config_success" = false ]; then
    echo "❌ Failed to get valid configuration for sidecar app $id after $max_attempts attempts"
    all_successful=false
  fi

done

# Final check and cleanup
if [ "$all_successful" = true ]; then
  echo ""
  echo "🎉 All checks passed. Running terraform destroy..."
  terraform destroy -auto-approve
else
  echo ""
  echo "❌ Some checks failed. Skipping terraform destroy."
  exit 1
fi
