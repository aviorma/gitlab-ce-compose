#!/bin/bash

# Function to make a GitLab API request
gitlab_api_request() {
  local method=$1
  local token=$2
  local gitlab_url=$3
  local endpoint=$4
  local data=$5

  curl -k --request "$method" \
       --header "PRIVATE-TOKEN: $token" \
       --header "Content-Type: application/json" \
       --data "$data" \
       --url "$gitlab_url/$endpoint" -s | jq .
}


# Function to create GitLab project, users, and groups
create_gitlab_entities() {
  local token=$1
  local gitlab_url=$2

  # Create GitLab project
  local project_data=$(gitlab_api_request "POST" "$token" "$gitlab_url" "api/v4/projects/" '{"name": "dev-workspace", "description": "dev-workspace", "path": "dev-workspace"}')

  # Create GitLab users
  for user in back_dev front_dev; do
    gitlab_api_request "POST" "$token" "$gitlab_url" "api/v4/users/" '{"email": "'$user'@demo.com", "name": "'$user'", "username": "'$user'","password":"Abcd1234@@@"}'
  done

  # Create GitLab groups
  for group in Backend Frontend; do
    gitlab_api_request "POST" "$token" "$gitlab_url" "api/v4/groups" '{"name": "'$group'", "path": "'$group'"}'
  done
}

# Function to share a project with a group
share_project_with_group() {
  local token=$1
  local gitlab_url=$2
  local project_id=$3

  for group in Backend Frontend; do
    local group_id=$(gitlab_api_request "GET" "$token" "$gitlab_url" "api/v4/groups" | jq '.[] | select(.name == "'$group'") | .id')
    gitlab_api_request "POST" "$token" "$gitlab_url" "api/v4/projects/$project_id/share" '{"group_access": 40, "group_id": "'$group_id'"}'
  done
}

# Function to set permissions for developers to merge to main
grant_merge_permissions() {
  local token=$1
  local gitlab_url=$2
  local project_id=$3

  gitlab_api_request "PUT" "$token" "$gitlab_url" "api/v4/projects/$project_id" '{"merge_requests_access_level": "enabled"}'
}

# Set variables
TOKEN="${GITLAB_DEFAULT_TOKEN}"
GITLAB_URL="https://${GITLAB_HOST}:${GITLAB_NGINX_SECURED_PORT}"

# Create GitLab project, users, and groups, and obtain project ID
create_gitlab_entities "$TOKEN" "$GITLAB_URL"

# Search for the project by name
PROJECT_ID=$(gitlab_api_request "GET" "$TOKEN" "$GITLAB_URL" "api/v4/projects?search=dev-workspace" | jq -r '.[0].id')

# Share project with groups
share_project_with_group "$TOKEN" "$GITLAB_URL" "$PROJECT_ID"

# Grant merge permissions to developers
grant_merge_permissions "$TOKEN" "$GITLAB_URL" "$PROJECT_ID"
