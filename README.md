# hgrep - History Grep and Command Counter

**hgrep** is a shell function that lets you search your command history for specific patterns, count command occurrences, and automatically copy the most frequently used command to your clipboard.

## Features

- 🔍 Search through your shell history with grep patterns
- 📊 Display commands sorted by usage frequency 
- 📋 Automatically copy the most frequent command to clipboard
- 🎨 Color-coded output for better readability
- ⚙️ Configurable number of results to display

## Installation

From the `terminal_shortcuts/hgrep` directory, run:

```bash
chmod +x test-hgrep.sh
chmod +x install.sh
./install.sh
```

This will:
1. Add the hgrep function to your shell configuration file (.bashrc, .zshrc, etc.)
2. Provide instructions for activating the function

After installation, you'll need to either:
- Restart your terminal
- Run `source ~/.bashrc` (or `~/.zshrc` depending on your shell)

## Usage

Basic usage:

```bash
hgrep <search_term> [number_of_results]
```

Examples:

```bash
# Find all docker commands in history
hgrep docker

# Find git commit commands and show top 5 results
hgrep "git commit" 5

# Find all npm commands (case-insensitive)
hgrep npm

# Find SSH commands
hgrep ssh

# Find all python scripts you've run
hgrep "python.*\.py"
```

### Sample Output

```
➜ hgrep git
 Counts  Commands
 2  git status
 3  git add .
 5  git pull
 7  git push
 12  git commit -m "Update documentation" (Copied to clipboard!)
```

## How It Works

The function:
1. Searches your command history for the given pattern (case-insensitive)
2. Filters out recursive history/hgrep commands
3. Counts unique command occurrences
4. Displays results ordered by frequency
5. Automatically copies the most frequent command to clipboard

## Requirements

- Bash or Zsh shell
- For clipboard functionality:
  - macOS: uses `pbcopy` (pre-installed)
  - Linux: uses `xclip` (install with `apt-get install xclip` if needed)
  - Wayland: uses `wl-copy` (install with `apt-get install wl-clipboard` if needed)

## Why a Shell Function?

The hgrep tool is implemented as a shell function rather than a standalone script because:

1. **Direct History Access**: Shell functions can directly access the history builtin, while scripts cannot
2. **Better Integration**: Functions integrate seamlessly with your shell environment
3. **Persistent Updates**: Changes to your history are immediately available to the function

## Troubleshooting

If hgrep doesn't work after installation:

1. Make sure you've reloaded your shell configuration with `source ~/.bashrc` (or equivalent)
2. Check that the `history` command works in your shell
3. Verify your terminal has permission to access the clipboard

## Uninstallation

To uninstall, remove the hgrep function from your shell configuration file:

1. Open your `.bashrc`, `.zshrc`, or similar file
2. Find and remove the hgrep function block (starts with "# hgrep function definition")
3. Save the file and reload your shell configuration

## License

This software is free to use and distribute under the terms of the MIT License.