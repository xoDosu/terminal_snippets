
A Bash tool that suggests commands from my shell history as I type.

## Usage
Type `cd` and `cd ~/Documents/projects/notepad` appears highlighted after the cursor. Press Tab to accept.

## Requirements
- R1: The top match appears highlighted after the cursor as I type.
- R2: Tab inserts the suggestion.
- R3: Matches are ranked by frequency, most frequent first. Ties: most recent first.
- R4: Each distinct line is shown once.
- R5: Prefix match only.
- R6: Show 1 suggestion.
- R7: It appears within 50 ms of a keypress.
- R8: No match means nothing is shown.

## Data
`~/.bash_history`

## Tests
| I type | Expected |
|--------|----------|
| `cd` | `cd ~/Documents/projects/notepad` |
| `git` | most frequent `git ...` line |
| `zzz` | nothing |

## Out of scope
- Fuzzy matching
- Other shells

## Plan
1. Engine in Bash
2. Display
3. Rewrite in C and benchmark
# terminal_snippets
