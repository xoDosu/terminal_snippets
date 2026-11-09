#!/usr/bin/env bash
# setup.sh - installs prerequisites and hooks histsuggest into your shell.
# Run it (do not source it):  ./setup.sh
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

say() { printf '==> %s\n' "$*"; }

# 1. Bash 4+ ---------------------------------------------------------------
if ((BASH_VERSINFO[0] < 4)); then
  if [ "$OS" = Darwin ] && command -v brew >/dev/null; then
    say "Bash $BASH_VERSION is too old, installing Bash 5 with Homebrew"
    brew install bash
    say "Now run this script again with: $(brew --prefix)/bin/bash setup.sh"
    exit 0
  fi
  echo "Need Bash 4 or newer (you have $BASH_VERSION)." >&2
  exit 1
fi

# 2. Tools the engine uses (awk, sort, cut) --------------------------------
missing=0
for t in awk sort cut head; do
  command -v "$t" >/dev/null || { echo "missing: $t" >&2; missing=1; }
done
if ((missing)); then
  say "Installing missing tools"
  if   command -v dnf     >/dev/null; then sudo dnf install -y gawk coreutils
  elif command -v apt-get >/dev/null; then sudo apt-get install -y gawk coreutils
  elif command -v pacman  >/dev/null; then sudo pacman -S --noconfirm gawk coreutils
  elif command -v brew    >/dev/null; then brew install gawk coreutils
  else echo "Install awk and coreutils manually." >&2; exit 1; fi
fi

# 2b. Write the tool itself if it is not here ---------------------------------
if [ ! -f "$DIR/histsuggest.sh" ]; then
  say "Creating $DIR/histsuggest.sh"
  cat > "$DIR/histsuggest.sh" <<'TOOL_EOF'
# histsuggest.sh - use with: source histsuggest.sh   (needs Bash 4+)
HS_FILE=${HS_FILE:-$HOME/.bash_history}

# Engine: prefix in, best history line out (most frequent, ties -> most recent).
suggest() {
  [ -z "$1" ] && return
  HS_P="$1" awk '
    BEGIN { p = ENVIRON["HS_P"] }
    index($0, p) == 1 { c[$0]++; last[$0] = NR }
    END { for (l in c) printf "%d\t%d\t%s\n", c[l], last[l], l }
  ' "$HS_FILE" | sort -t$'\t' -k1,1nr -k2,2nr | head -1 | cut -f3-
}

# Display: grey text after the cursor, cursor put back.
_hs_promptwidth() {
  local p=${PS1@P}
  while [[ $p =~ $'\001'[^$'\002']*$'\002' ]]; do p=${p/"${BASH_REMATCH[0]}"/}; done
  p=${p##*$'\n'}
  HS_PW=${#p}
}

_hs_show() {
  local s rest
  s=$(suggest "$READLINE_LINE")
  rest=${s:${#READLINE_LINE}}
  _hs_promptwidth
  printf '\e7\e[%dC\e[90m%s\e[0m\e[K\e8' "$((HS_PW + ${#READLINE_LINE}))" "$rest"
}

_hs_key() {   # $1 = ascii code of typed key
  local ch
  printf -v ch "\\x$(printf %02x "$1")"
  READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}$ch${READLINE_LINE:READLINE_POINT}"
  ((READLINE_POINT++))
  _hs_show
}

_hs_accept() {
  local s
  s=$(suggest "$READLINE_LINE")
  if [ -n "$s" ]; then READLINE_LINE=$s; READLINE_POINT=${#s}; fi
}

for i in $(seq 32 126); do
  bind -x "\"\\x$(printf %02x "$i")\": _hs_key $i"
done
bind '"\C-x\C-d": backward-delete-char'
bind -x '"\C-x\C-s": _hs_show'
bind '"\C-?": "\C-x\C-d\C-x\C-s"'
bind -x '"\t": _hs_accept'
TOOL_EOF
fi

# 3. Pick the startup file -------------------------------------------------
if [ "$OS" = Darwin ]; then RC="$HOME/.bash_profile"; else RC="$HOME/.bashrc"; fi
touch "$RC"

# 4. Add the config once ----------------------------------------------------
MARK="# >>> histsuggest >>>"
if grep -qF "$MARK" "$RC"; then
  say "Already set up in $RC, nothing to do."
else
  cat >> "$RC" <<EOT

$MARK
shopt -s histappend
PROMPT_COMMAND='history -a'
case \$- in *i*) ((BASH_VERSINFO[0] >= 4)) && source "$DIR/histsuggest.sh" ;; esac
# <<< histsuggest <<<
EOT
  say "Added to $RC"
fi

say "Done. Open a new terminal (or run: source $RC)."
