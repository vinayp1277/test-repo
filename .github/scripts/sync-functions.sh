#!/bin/bash
# Shared functions for sync-branches workflow


load_excluded_commits() {
    local arr_name=$1
    if [ -f .github/.commitignore ]; then
        while IFS=' ' read -r sha rest || [ -n "$sha" ]; do
            [[ "$sha" =~ ^#.*$ ]] && continue
            [[ -z "$sha" ]] && continue
            eval "${arr_name}+=('$sha')"
        done < .github/.commitignore
    fi
}


is_excluded_commit() {
    local sha=$1
    local short_sha=${sha:0:8}
    [[ " ${EXCLUDED_COMMITS[@]} " =~ " ${short_sha} " ]]
}


has_non_jenkins_files() {
    local sha=$1
    local files_changed=$(git diff-tree --no-commit-id --name-only -r $sha)
    while IFS= read -r file; do
        if [[ ! "$file" =~ ^jenkins/ ]]; then
            return 0
        fi
    done <<< "$files_changed"
    return 1
}


get_user_info() {
    local sha=$1
    local repo=$2
    local login=$(gh api repos/$repo/commits/$sha --jq '.author.login' || true)
    local email=$(gh api repos/$repo/commits/$sha --jq '.commit.author.email' || true)
    
    if [ -n "$login" ]; then
        echo "@$login|$email"
    elif [ -n "$email" ]; then
        echo "$email|$email"
    fi
}


is_revert_commit() {
    local sha=$1
    local commit_msg=$(git log -1 --pretty=format:'%s' $sha)
    [[ "$commit_msg" =~ ^[Rr]evert ]]
}