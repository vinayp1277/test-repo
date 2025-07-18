#!/bin/bash
# Shared functions for sync-branches workflow

set -e

has_non_jenkins_files() {
    local sha=$1
    local files_changed
    files_changed=$(git diff-tree --no-commit-id --name-only -r "$sha" 2>/dev/null || echo "")
    
    if [ -z "$files_changed" ]; then
        return 1
    fi
    
    while IFS= read -r file; do
        if [[ -n "$file" && ! "$file" =~ ^jenkins/ ]]; then
            return 0
        fi
    done <<< "$files_changed"
    return 1
}

get_user_info() {
    local sha=$1
    local repo=$2
    local login
    local email
    
    login=$(gh api "repos/$repo/commits/$sha" --jq '.author.login' 2>/dev/null || echo "")
    email=$(gh api "repos/$repo/commits/$sha" --jq '.commit.author.email' 2>/dev/null || echo "")
    
    if [ -n "$login" ] && [ "$login" != "null" ]; then
        echo "@$login|$email"
    elif [ -n "$email" ] && [ "$email" != "null" ]; then
        echo "$email|$email"
    fi
}

is_revert_commit() {
    local sha=$1
    local commit_msg
    commit_msg=$(git log -1 --pretty=format:'%s' "$sha" 2>/dev/null || echo "")
    [[ "$commit_msg" =~ ^[Rr]evert ]]
}