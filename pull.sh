#!/bin/bash

# Replace with your GitHub organization name
ORG_NAME="DOH-EPI-Coders"

# CSV Header (matching the desired column names)
echo "repo,create_date,mode_date,size,commits,collaborators,language,URL" > repo_activity.csv

# List repositories in the organization
REPOS=$(gh repo list $ORG_NAME --json name --limit 1000 | jq -r '.[].name')

# Loop through each repository and fetch various activity metrics
for REPO in $REPOS; do
  # Fetch repository size in kilobytes
  REPO_SIZE=$(gh api repos/$ORG_NAME/$REPO --jq '.size')

  # Initialize commit counter
  COMMIT_COUNT=0
  PAGE=1

  # If the repository size is less than 10KB, set commit count to 1 (but still fetch other data)
  if [ "$REPO_SIZE" -lt 10 ]; then
    echo "Repository is smaller than 10KB, setting commits to 1 for $REPO"
    COMMIT_COUNT=1
  else
    # Fetch commits in a paginated manner and count all commits
    while : ; do
      # Fetch commits for the current page
      PAGE_COMMIT_COUNT=$(gh api repos/$ORG_NAME/$REPO/commits?page=$PAGE --jq 'length')

      # If no more commits, break the loop
      if [ "$PAGE_COMMIT_COUNT" -eq 0 ]; then
        break
      fi

      # Add the number of commits from the current page
      COMMIT_COUNT=$((COMMIT_COUNT + PAGE_COMMIT_COUNT))

      # Increment page number
      PAGE=$((PAGE + 1))
    done
  fi

  # Fetch creation date and last modified date
  CREATION_DATE=$(gh api repos/$ORG_NAME/$REPO --jq '.created_at')
  LAST_MODIFIED_DATE=$(gh api repos/$ORG_NAME/$REPO --jq '.updated_at')

  # Fetch number of contributors
  CONTRIBUTOR_COUNT=$(gh api repos/$ORG_NAME/$REPO/contributors --jq 'length')

  # Fetch top language
  TOP_LANGUAGE=$(gh api repos/$ORG_NAME/$REPO/languages | jq 'to_entries | sort_by(-.value) | .[0].key // "Unknown"')

  # Clean quotes from top language
  TOP_LANGUAGE=$(echo $TOP_LANGUAGE | sed 's/"//g')

  # Fetch repository URL
  REPO_URL=$(gh api repos/$ORG_NAME/$REPO --jq '.html_url')

  # Output the information
  echo "Repository: $REPO - Created on: $CREATION_DATE - Last Modified: $LAST_MODIFIED_DATE - Size: $REPO_SIZE KB - Commits: $COMMIT_COUNT - Contributors: $CONTRIBUTOR_COUNT - Top Language: $TOP_LANGUAGE - URL: $REPO_URL"

  # Append to CSV file (use the updated header columns)
  echo "$REPO,$CREATION_DATE,$LAST_MODIFIED_DATE,$REPO_SIZE,$COMMIT_COUNT,$CONTRIBUTOR_COUNT,$TOP_LANGUAGE,$REPO_URL" >> repo_activity.csv
done
