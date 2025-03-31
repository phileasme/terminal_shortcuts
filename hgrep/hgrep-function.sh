#!/usr/bin/env bash

# hgrep function definition
hgrep() {
    # Show usage if no search term provided
    if [ -z "$1" ]; then
        echo "Usage: hgrep <search_term> [number_of_results]"
        return 1
    fi
    
    # Set default number of results to show
    local top_n=${2:-10}
    
    # Get history and filter by search term
    # Using grep with case-insensitive search for better results
    local history_output
    history_output=$(history | grep -i -E "$1")
    
    # Check if we found any matches
    if [ -z "$history_output" ]; then
        echo "No matching commands found in history."
        return 0
    fi
    
    # Create a temporary file for processing
    local temp_file
    temp_file=$(mktemp)
    
    commands_with_counts=$(
        echo "$history_output" | 
        grep -v "history \|hgrep" |
        sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//' |
        sed 's/^sudo //' |
        grep -v '^$' |
        sort |
        uniq -c |
        sort -n
    )
    
    # Check if we have any valid commands after filtering
    if [ -z "$commands_with_counts" ]; then
        echo "No valid commands found after filtering."
        rm "$temp_file"
        return 0
    fi
    
    # Display header
    echo "$(tput sgr0) Counts $(tput setaf 3) Commands"
    
    # Process and display the top commands
    echo "$commands_with_counts" | tail -n "$top_n" | while read -r count cmd; do
        if [ -n "$cmd" ]; then
            # Check if this is the last line to display (most frequent command)
            if [ "$cmd" = "$(echo "$commands_with_counts" | tail -n 1 | awk '{$1=""; print $0}' | sed 's/^ //')" ]; then
                echo "$(tput sgr0) $count $(tput setaf 2) $cmd $(tput sgr0) (Copied to clipboard!)"
                
                # Try different clipboard commands based on the OS
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS
                    echo "$cmd" | tr -d '\n' | pbcopy
                elif command -v xclip >/dev/null 2>&1; then
                    # Linux with xclip
                    echo "$cmd" | tr -d '\n' | xclip -selection clipboard
                elif command -v wl-copy >/dev/null 2>&1; then
                    # Wayland
                    echo "$cmd" | tr -d '\n' | wl-copy
                else
                    # No clipboard utility available
                    echo "Note: No clipboard utility available. Most frequent command not copied."
                fi
            else
                echo "$(tput sgr0) $count $(tput setaf 3) $cmd"
            fi
        fi
    done
    
    # Clean up
    rm "$temp_file"
}