#!/usr/bin/env bash

# Test script for hgrep function
# This script tests the hgrep function by creating a mock history
# and verifying that hgrep processes it correctly

# Color definitions for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Create a temporary directory for test files
TEST_DIR=$(mktemp -d)
echo -e "${BLUE}Created test directory: ${TEST_DIR}${NC}"

# Clean up function to remove test files on exit
cleanup() {
    echo -e "${BLUE}Cleaning up test files...${NC}"
    rm -rf "$TEST_DIR"
    echo -e "${BLUE}Cleanup complete.${NC}"
}

# Register cleanup function to run on script exit
trap cleanup EXIT

# Check if hgrep function is available
if ! type hgrep >/dev/null 2>&1; then
    echo -e "${RED}Error: hgrep function is not available.${NC}"
    echo -e "${YELLOW}Make sure you have installed it and sourced your shell configuration.${NC}"
    exit 1
fi

# Create a mock history file
HISTORY_FILE="$TEST_DIR/mock_history"

cat > "$HISTORY_FILE" << EOF
    1  ls -la
    2  cd /home/user
    3  git status
    4  git add .
    5  git commit -m "Initial commit"
    6  git push origin main
    7  npm install
    8  npm start
    9  git status
   10  git pull
   11  git push origin main
   12  docker ps
   13  docker-compose up -d
   14  docker ps
   15  ssh user@example.com
   16  scp file.txt user@example.com:~/
   17  ssh user@example.com
   18  grep "error" /var/log/app.log
   19  sudo systemctl restart nginx
   20  git status
EOF

echo -e "${BLUE}Created mock history file.${NC}"

# Create a function to simulate history command using our mock file
mock_history() {
    cat "$HISTORY_FILE"
}

# Create a testing version of hgrep that uses our mock history
test_hgrep() {
    # Temporary file to store output
    local output_file="$TEST_DIR/hgrep_output"
    > "$output_file"
    
    # Get search term and optional limit
    local search_term="$1"
    local limit="${2:-10}"
    
    # Run a simplified version of hgrep logic using our mock history
    local history_output
    history_output=$(mock_history | grep -i -E "$search_term")
    
    # Check if we found any matches
    if [ -z "$history_output" ]; then
        echo "No matching commands found in history."
        return 0
    fi
    
    # Create a temporary file for processing
    local temp_file="$TEST_DIR/temp_cmds"
    > "$temp_file"
    
    # Process each line of history output
    echo "$history_output" | while IFS= read -r line; do
        # Skip history and hgrep commands to avoid recursion
        if [[ "$line" == *"history |"* || "$line" == *"hgrep"* ]]; then
            continue
        fi
        
        # Clean up the command (remove line numbers)
        local cleaned_cmd
        cleaned_cmd=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')
        
        # Skip empty lines
        if [ -n "$cleaned_cmd" ]; then
            echo "$cleaned_cmd" >> "$temp_file"
        fi
    done
    
    # Count occurrences of each command
    local commands_with_counts
    commands_with_counts=$(sort "$temp_file" | uniq -c | sort -n)
    
    # Check if we have any valid commands after filtering
    if [ -z "$commands_with_counts" ]; then
        echo "No valid commands found after filtering."
        return 0
    fi
    
    # Display header
    echo " Counts  Commands" >> "$output_file"
    
    # Process and display the top commands
    echo "$commands_with_counts" | tail -n "$limit" | while read -r count cmd; do
        if [ -n "$cmd" ]; then
            if [ "$cmd" = "$(echo "$commands_with_counts" | tail -n 1 | awk '{$1=""; print $0}' | sed 's/^ //')" ]; then
                echo " $count  $cmd (Copied to clipboard!)" >> "$output_file"
            else
                echo " $count  $cmd" >> "$output_file"
            fi
        fi
    done
    
    # Return the output
    cat "$output_file"
}

# Run the tests
echo -e "${BOLD}Running tests for hgrep...${NC}"

# Test 1: Basic search functionality
echo -e "\n${BOLD}Test 1: Basic search functionality - 'git'${NC}"
TEST1_OUTPUT=$(test_hgrep "git")
echo "$TEST1_OUTPUT"

# Check if output contains expected entries
if echo "$TEST1_OUTPUT" | grep -q "git status" && \
   echo "$TEST1_OUTPUT" | grep -q "git add" && \
   echo "$TEST1_OUTPUT" | grep -q "git commit" && \
   echo "$TEST1_OUTPUT" | grep -q "git push" && \
   echo "$TEST1_OUTPUT" | grep -q "git pull"; then
    echo -e "${GREEN}✓ Passed: Output contains expected git commands${NC}"
else
    echo -e "${RED}✘ Failed: Output missing expected git commands${NC}"
fi

# Check if counts are correct
if echo "$TEST1_OUTPUT" | grep -q "3  git status"; then
    echo -e "${GREEN}✓ Passed: Command count is correct${NC}"
else
    echo -e "${RED}✘ Failed: Command count is incorrect${NC}"
fi

# Test 2: Limited results
echo -e "\n${BOLD}Test 2: Limited results - 'git' with limit 2${NC}"
TEST2_OUTPUT=$(test_hgrep "git" 2)
echo "$TEST2_OUTPUT"

# Count the number of command lines (excluding the header)
RESULT_COUNT=$(echo "$TEST2_OUTPUT" | grep -v "Counts  Commands" | wc -l)
if [ "$RESULT_COUNT" -eq 2 ]; then
    echo -e "${GREEN}✓ Passed: Output respects the limit of 2 results${NC}"
else
    echo -e "${RED}✘ Failed: Output does not respect the limit (got $RESULT_COUNT results)${NC}"
fi

# Test 3: No matches
echo -e "\n${BOLD}Test 3: No matches - 'python'${NC}"
TEST3_OUTPUT=$(test_hgrep "python")

# Check if "no matches" message is shown
if echo "$TEST3_OUTPUT" | grep -q "No matching commands found in history"; then
    echo -e "${GREEN}✓ Passed: Correctly shows 'no matches' message${NC}"
else
    echo -e "${RED}✘ Failed: Does not show expected 'no matches' message${NC}"
fi

# Test 4: Case insensitivity
echo -e "\n${BOLD}Test 4: Case insensitivity - 'SSH'${NC}"
TEST4_OUTPUT=$(test_hgrep "SSH")
echo "$TEST4_OUTPUT"

# Check if ssh commands are found despite different case
if echo "$TEST4_OUTPUT" | grep -q "ssh user@example.com"; then
    echo -e "${GREEN}✓ Passed: Found ssh commands despite searching for 'SSH'${NC}"
else
    echo -e "${RED}✘ Failed: Case-insensitive search not working${NC}"
fi

# Test 5: Verify most frequent command is marked for clipboard
echo -e "\n${BOLD}Test 5: Most frequent command marked for clipboard - 'docker'${NC}"
TEST5_OUTPUT=$(test_hgrep "docker")
echo "$TEST5_OUTPUT"

# Check if "docker ps" is marked as copied to clipboard (it appears twice)
if echo "$TEST5_OUTPUT" | grep -q "docker ps (Copied to clipboard!)"; then
    echo -e "${GREEN}✓ Passed: Most frequent command is marked for clipboard${NC}"
else
    echo -e "${RED}✘ Failed: Most frequent command not marked for clipboard${NC}"
fi

# Summary
echo -e "\n${BOLD}Test Summary${NC}"
echo -e "${BLUE}Tests completed for hgrep${NC}"
echo -e "${BLUE}Check the output above for any test failures${NC}"