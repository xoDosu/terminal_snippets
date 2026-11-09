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
