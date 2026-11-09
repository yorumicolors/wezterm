#!/usr/bin/env bash
# Yorumi theme installer for WezTerm (Linux & macOS)
set -euo pipefail

# ── flavour, target config, and whether to activate ────────────────────────
FLAVOUR=""
FLAVOURS="ether abyss bifrost kraken kabocha cosmic ryujin"
CONFIG=""
ACTIVATE=1

# Print the real file $1's bytes belong in, following any final-component
# symlink chain. Plain readlink: -f is GNU, and this must also work on macOS
# and in Git Bash. Nothing is written here, so a bad link leaves the file alone.
resolve_config() {
  local cfg="$1" link hops=0
  while [ -L "$cfg" ]; do
    hops=$((hops + 1))
    if [ "$hops" -gt 40 ]; then
      echo "yorumi: $1 is a symbolic link loop; configuration unchanged" >&2
      return 1
    fi
    if ! link=$(readlink "$cfg"); then
      echo "yorumi: cannot read the symbolic link $cfg; configuration unchanged" >&2
      return 1
    fi
    case "$link" in
      /*) cfg="$link" ;;
      *) cfg="$(dirname "$cfg")/$link" ;;
    esac
  done
  if [ "$hops" -gt 0 ] && [ ! -e "$cfg" ]; then
    echo "yorumi: $1 points at $cfg, which does not exist; configuration unchanged" >&2
    return 1
  fi
  printf '%s\n' "$cfg"
}

# replace $1 (already resolved) with $2 atomically: the temp is a safely named
# sibling of the real file, so the rename never crosses a filesystem, and a
# failed write leaves $1 exactly as it was. cp -p carries the mode, owner and
# timestamps of an existing config onto the temp, as before.
commit() {
  local tmp mode
  # Fail closed before copying: cp -p would clone an immutable (uchg) or
  # otherwise unwritable config's flags onto the temp, which could then be
  # neither written nor removed. An append-open writes no bytes, and it only
  # runs for a file that already exists.
  if [ -e "$1" ] && ! : 2>/dev/null >> "$1"; then
    echo "yorumi: $1 is not writable (read-only or protected); configuration unchanged" >&2
    return 1
  fi
  if ! tmp=$(mktemp "$1.yorumi-tmp.XXXXXX"); then
    echo "yorumi: cannot create a temporary file next to $1" >&2
    return 1
  fi
  if [ -e "$1" ]; then
    cp -p "$1" "$tmp" || { rm -f "$tmp"; return 1; }
  else
    # a fresh config keeps the mode a `: >` under this umask would have given it
    mode=$(umask)
    chmod "$(printf '%o' "$(( 0666 & ~0$mode ))")" "$tmp" || { rm -f "$tmp"; return 1; }
  fi
  if cat "$2" > "$tmp" && mv "$tmp" "$1"; then
    return 0
  fi
  rm -f "$tmp"
  return 1
}

# No default flavour. Ask, or fail where nobody can answer.
ask_flavour() {
  # a real open, not a -r test: /dev/tty exists even when nothing is attached
  if ! { exec 3<>/dev/tty; } 2>/dev/null; then
    echo "no flavour given. pass --flavour <name>: $FLAVOURS" >&2
    exit 2
  fi
  i=0
  {
    echo "Yorumi flavours:"
    for f in $FLAVOURS; do i=$((i + 1)); echo "  $i) $f"; done
  } >&3
  while :; do
    printf 'flavour (1-%s or a name): ' "$i" >&3
    answer=""
    IFS= read -r answer <&3 || {
      exec 3>&-
      echo "no flavour given. pass --flavour <name>: $FLAVOURS" >&2
      exit 2
    }
    [ -z "$answer" ] && continue
    case "$answer" in
      *[!0-9]*) candidate="$answer" ;;
      *) candidate=""
         n=0
         for f in $FLAVOURS; do n=$((n + 1)); [ "$n" -eq "$answer" ] && candidate="$f"; done ;;
    esac
    case " $FLAVOURS " in
      *" $candidate "*) FLAVOUR="$candidate"; exec 3>&-; return 0 ;;
    esac
    printf 'not a flavour: %s\n' "$answer" >&3
  done
}

if [[ "${XDG_CONFIG_HOME:-}" = /* ]]; then
  _YORUMI_XDG="$XDG_CONFIG_HOME"
else
  _YORUMI_XDG="$HOME/.config"
fi
if [ -n "${WEZTERM_CONFIG_FILE:-}" ]; then
  _YORUMI_CFG="$WEZTERM_CONFIG_FILE"
else
  _YORUMI_CANDS=("$HOME/.wezterm.lua" "$_YORUMI_XDG/wezterm/wezterm.lua")
  _dirs="${XDG_CONFIG_DIRS:-/etc/xdg}"
  [ -z "$_dirs" ] && _dirs="/etc/xdg"
  IFS=':' read -ra _dirarr <<< "$_dirs"
  for _d in "${_dirarr[@]}"; do
    if [[ "$_d" = /* ]]; then
      _YORUMI_CANDS+=("$_d/wezterm/wezterm.lua")
    fi
  done
  _YORUMI_CFG=""
  for _c in "${_YORUMI_CANDS[@]}"; do
    if [ -e "$_c" ]; then _YORUMI_CFG="$_c"; break; fi
  done
  [ -z "$_YORUMI_CFG" ] && _YORUMI_CFG="$_YORUMI_XDG/wezterm/wezterm.lua"
fi
DEFAULT_CONFIG="$_YORUMI_CFG"

while [ $# -gt 0 ]; do
  case "$1" in
    --flavour|-f)
      [ -n "${2:-}" ] || { echo "--flavour needs a flavour name. One of: $FLAVOURS" >&2; exit 2; }
      FLAVOUR="$2"; shift 2 ;;
    --config|-c)
      [ -n "${2:-}" ] || { echo "--config needs a path" >&2; exit 2; }
      CONFIG="$2"; shift 2 ;;
    --no-activate) ACTIVATE=0; shift ;;
    -h|--help)
      echo "usage: ./install.sh [--flavour <name>] [--config <path>] [--no-activate]"
      echo "flavours: $FLAVOURS"
      exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -n "$FLAVOUR" ]; then
  case " $FLAVOURS " in
    *" $FLAVOUR "*) ;;
    *) echo "unknown flavour '$FLAVOUR'. One of: $FLAVOURS" >&2; exit 2 ;;
  esac
fi

[ -z "$FLAVOUR" ] && [ "$ACTIVATE" -eq 1 ] && ask_flavour


DEST_DIR="$_YORUMI_XDG/wezterm/colors"
mkdir -p "$DEST_DIR"
DEST_DIR="$(cd "$DEST_DIR" && pwd -P)"

RAW_BASE="https://raw.githubusercontent.com/yorumicolors/wezterm/main"
FILES=("yorumi-ether.toml" "yorumi-abyss.toml" "yorumi-bifrost.toml" "yorumi-kraken.toml" "yorumi-kabocha.toml" "yorumi-cosmic.toml" "yorumi-ryujin.toml")

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
fi

echo "Installing Yorumi theme for WezTerm..."

for f in "${FILES[@]}"; do
  basename_f="$(basename "$f")"
  target="$DEST_DIR/$basename_f"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$f" ]]; then
    cp "$SCRIPT_DIR/$f" "$target"
  elif [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$basename_f" ]]; then
    cp "$SCRIPT_DIR/$basename_f" "$target"
  else
    part="$DEST_DIR/$basename_f.part.$$"
    if ! curl -fsSL "$RAW_BASE/$f" -o "$part"; then
      rm -f "$part"
      echo "yorumi: could not download $f from $RAW_BASE" >&2
      echo "yorumi: if that repository is not public yet, clone it and run ./install.sh from the checkout." >&2
      exit 3
    fi
    mv "$part" "$target"
  fi
  echo "✓ Installed: $target"
done

cat << 'INFO'

Successfully installed the Yorumi files for WezTerm.

Activate it — the block below is rewritten by every run, so switching flavour is
just `./install.sh --flavour <name>`:

    -- >>> yorumi >>>
    config.color_scheme = 'yorumi-<flavour>'
    -- <<< yorumi <<<
INFO

# ── activation: one marked block, replaced whole ───────────────────────────
# Supported: a missing, empty or comments-only file (gets a whole config), or a
# Lua file with balanced blocks, exactly one depth-0 `local config = {}` /
# `wezterm.config_builder()` binding and one depth-0 `return config` after it.
# Depth, not column: a binding inside a function is a different variable. Code
# is lexed apart from quoted strings, long strings and long comments, so
# declarations, returns and our markers inside a string are never code.
# Everything else is refused with the file byte-for-byte untouched.
BEGIN="-- >>> yorumi >>>"
END="-- <<< yorumi <<<"

write_block() {
  CONFIG="${CONFIG:-$DEFAULT_CONFIG}"
  CONFIG_REAL=$(resolve_config "$CONFIG") || exit 1
  mkdir -p "$(dirname "$CONFIG_REAL")" || { echo "yorumi: cannot create $(dirname "$CONFIG_REAL")" >&2; exit 1; }

  # a missing config is a fresh one, not an error; commit() creates the file
  created=0
  [ -e "$CONFIG_REAL" ] || created=1

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  # every comparison runs on a copy with the CRs stripped; the endings come
  # back on the way out, so a CRLF config is neither duplicated nor converted
  crlf=""
  if [ "$created" -eq 0 ]; then
    tr -d '\r' < "$CONFIG_REAL" > "$work/in"
    if [ "$(wc -c < "$work/in")" -lt "$(wc -c < "$CONFIG_REAL")" ]; then
      crlf=1
    fi
  else
    : > "$work/in"
  fi

  printf "config.color_scheme = 'yorumi-%s'\n" "$FLAVOUR" > "$work/body"

  # Lex first: keep each line's code with strings and comments blanked out, plus
  # the block depth at its start and whether it held any code. Verdict goes to
  # $work/status.
  awk -v b="$BEGIN" -v e="$END" -v bf="$work/body" -v sf="$work/status" \
      -v dl="config.color_scheme = 'yorumi-$FLAVOUR'" \
      -v key="color_scheme = 'yorumi-$FLAVOUR'," '
    BEGIN { st = "code"; esc = 0; depth = 0; pd = 0; bn = 0; en = 0; md = 0; q = "\047" }

    function rep(c, k,   r) { r = ""; while (k-- > 0) r = r c; return r }
    function trim(x) { sub(/^[ \t]+/, "", x); sub(/[ \t]+$/, "", x); return x }

    function emit(   line) {
      print b
      while ((getline line < bf) > 0) print line
      close(bf); print e
    }

    # `config.color_scheme` only when a named `config` binding exists; else a
    # table entry, which fits any returned table
    function refuse(why, havecfg) {
      if (bn > 0) why = why "; it still holds a yorumi block from an earlier run, delete those marker lines by hand"
      if (havecfg)
        rec = "NO\t" why "\tAdd this line to your config:\t" dl
      else
        rec = "NO\t" why "\tAdd this inside the table your config returns:\t" key
      print rec > sf
      exit
    }

    # blank out comments, quoted strings and long brackets; what is left is code
    function lex(s,   i, n, ch, j, z, out) {
      n = length(s); out = ""; i = 1
      while (i <= n) {
        ch = substr(s, i, 1)
        if (st == "long") {
          if (substr(s, i, length(cl)) == cl) {
            out = out rep(" ", length(cl)); i += length(cl); st = "code"
          } else { out = out " "; i++ }
          continue
        }
        if (st == "sq" || st == "dq") {
          out = out " "
          if (esc) { esc = 0; i++; continue }
          if (ch == "\\") { esc = 1; i++; continue }
          if ((st == "sq" && ch == "\047") || (st == "dq" && ch == "\"")) st = "code"
          i++; continue
        }
        if (ch == "-" && substr(s, i + 1, 1) == "-") {
          j = i + 2; z = 0
          if (substr(s, j, 1) == "[") {
            j++
            while (substr(s, j, 1) == "=") { z++; j++ }
            if (substr(s, j, 1) == "[") {
              cl = "]" rep("=", z) "]"
              out = out rep(" ", j - i + 1); st = "long"; i = j + 1; continue
            }
          }
          out = out rep(" ", n - i + 1); st = "lc"; i = n + 1; continue
        }
        if (ch == "[") {
          j = i + 1; z = 0
          while (substr(s, j, 1) == "=") { z++; j++ }
          if (substr(s, j, 1) == "[") {
            cl = "]" rep("=", z) "]"; saw = 1
            out = out rep(" ", j - i + 1); st = "long"; i = j + 1; continue
          }
        }
        if (ch == "\047" || ch == "\"") { out = out " "; st = (ch == "\047" ? "sq" : "dq"); saw = 1; i++; continue }
        if (ch != " " && ch != "\t") saw = 1
        out = out ch; i++
      }
      return out
    }

    # block depth from the code: function/if/repeat open, for/while open but
    # leave their own `do` to the statement, a bare `do` opens, end/until close
    function scan(s,   i, n, w, m, pos) {
      n = length(s); pos = 1
      while (pos <= n) {
        m = match(substr(s, pos), /[A-Za-z_][A-Za-z0-9_]*/)
        if (m == 0) return
        pos += m - 1
        w = ""
        while (pos <= n && substr(s, pos, 1) ~ /[A-Za-z0-9_]/) { w = w substr(s, pos, 1); pos++ }
        if (w == "function" || w == "if" || w == "repeat") depth++
        else if (w == "for" || w == "while") { depth++; pd++ }
        else if (w == "do") { if (pd > 0) pd--; else depth++ }
        else if (w == "end" || w == "until") { depth--; if (depth < 0) unbal = 1 }
      }
    }

    { raw[NR] = $0; beg[NR] = st; saw = 0; cd = lex($0); sawv[NR] = saw
      if (st == "lc") st = "code"
      if (st == "sq" || st == "dq") { if (esc) esc = 0; else badstr = 1 }
      dep[NR] = depth
      scan(cd) }

    END {
      n = NR

      # an unclosed quote or long bracket makes every later line opaque
      if (badstr) refuse("a quoted string is not closed on its line", 0)
      if (st == "long") refuse("it ends inside an unclosed long comment or long string", 0)
      if (st == "sq" || st == "dq") refuse("it ends inside an unclosed quoted string", 0)
      if (unbal || depth != 0 || pd != 0) refuse("its Lua blocks do not balance (a stray or missing `end`, `do` or `until`)", 0)

      # 1. markers count on comment lines only, and never nested
      for (i = 1; i <= n; i++) {
        t = (beg[i] == "code") ? trim(raw[i]) : ""
        mark[i] = 0
        if (t == b) { bn++; if (md > 0) broke = 1; md++; mark[i] = 1 }
        else if (t == e) { en++; if (md > 0) md--; else broke = 1; mark[i] = 2 }
      }
      if (bn != en || broke) {
        print "MARK\t" bn " " q b q " and " en " " q e q " markers, nested or unpaired" > sf
        exit
      }

      # 2. drop the whole managed block, plus the blank line we add after it
      m = 0; skip = 0; inside = 0
      for (i = 1; i <= n; i++) {
        if (mark[i] == 1) { inside = 1; continue }
        if (mark[i] == 2) { inside = 0; skip = 1; continue }
        if (inside) continue
        if (skip && trim(raw[i]) == "") { skip = 0; continue }
        skip = 0
        m++; K[m] = raw[i]; KB[m] = beg[i]; KD[m] = dep[i]; KS[m] = sawv[i]
      }
      n = m

      # 3. no code at all: write a whole config, keeping its comment lines
      blank = 1
      for (i = 1; i <= n; i++) if (KS[i]) { blank = 0; break }
      if (blank) {
        for (i = 1; i <= n; i++) print K[i]
        if (n && trim(K[n]) != "") print ""
        print "local wezterm = require \047wezterm\047"
        print "local config = wezterm.config_builder()"
        print ""
        emit()
        print ""
        print "return config"
        print "NEW" > sf
        exit
      }

      # code that shares a line with a comment or a string close cannot be
      # placed, so it is refused instead of being read as a comment
      for (i = 1; i <= n; i++) {
        if (!KS[i]) continue
        if (KB[i] == "code" && substr(trim(K[i]), 1, 2) != "--") continue
        refuse("it has code on a line that also carries a comment or a string close; put that statement on its own line", 0)
      }

      # 4. one binding and one `return config`, both at depth 0
      qc = "[\047\"]"
      decl = "^[ \t]*local[ \t]+config[ \t]*=[ \t]*([{][ \t]*[}]|wezterm[ \t]*[.][ \t]*config_builder[ \t]*[(][ \t]*[)]|require[ \t]*[(][ \t]*" qc "wezterm" qc "[ \t]*[)][ \t]*[.][ \t]*config_builder[ \t]*[(][ \t]*[)])[ \t]*;?[ \t]*(--.*)?$"

      for (i = 1; i <= n; i++) {
        if (KD[i] != 0 || KB[i] != "code") continue
        if (K[i] ~ /^[ \t]*local[ \t]+config[ \t]*=/) { dc++; dp = i }
        if (K[i] ~ /^[ \t]*return[ \t]+config[ \t]*;?[ \t]*(--.*)?$/) { rc++; rp = i }
        if (K[i] ~ /^[ \t]*return[ \t]*[{]/) literal = 1
      }

      hascfg = (dc == 1 && K[dp] ~ decl) ? 1 : 0

      if (dc == 0) {
        if (literal) refuse("it returns a table literal (`return { ... }`) instead of a named `config` table", 0)
        refuse("it has no top-level `local config = {}` or `local config = wezterm.config_builder()` line", 0)
      }
      if (dc > 1) refuse("it declares `local config = ...` more than once at the top level", 0)
      if (!hascfg) refuse("its top-level `local config =` line is not `{}` or `wezterm.config_builder()`", 0)
      if (rc == 0) {
        if (literal) refuse("it returns a table literal (`return { ... }`) instead of a named `config` table", 0)
        refuse("it has no top-level `return config` line", 1)
      }
      if (rc > 1) refuse("it has more than one top-level `return config` line", 1)
      if (rp < dp) refuse("its `return config` comes before its `local config = ...` line", 1)

      # 5. insert above the return, so nothing below can shadow it
      for (i = 1; i < rp; i++) print K[i]
      if (rp > 1 && trim(K[rp - 1]) != "") print ""
      emit()
      print ""
      for (i = rp; i <= n; i++) print K[i]
      print "OK" > sf
    }
  ' "$work/in" > "$work/out" || {
    echo "yorumi: could not read $CONFIG; the file was not touched." >&2
    exit 1
  }

  IFS="$(printf '\t')" read -r verdict reason where line < "$work/status" || :
  new=0
  case "${verdict:-}" in
    NEW) new=1 ;;
    OK) ;;
    MARK)
      echo "yorumi: $CONFIG has $reason." >&2
      echo "yorumi: the config was not touched; fix or delete those lines, then run this again." >&2
      exit 1
      ;;
    NO)
      echo "yorumi: $CONFIG is not a config this installer can edit: $reason." >&2
      echo "yorumi: the file was not touched. ${where:-}" >&2
      printf '    %s\n' "${line:-}" >&2
      exit 1
      ;;
    *)
      echo "yorumi: could not work out the shape of $CONFIG; the file was not touched." >&2
      exit 1
      ;;
  esac

  if [ -n "$crlf" ]; then
    awk -v cr="$(printf '\r')" '{ printf "%s%s\n", $0, cr }' "$work/out" > "$work/crlf"
    mv "$work/crlf" "$work/out"
  fi

  if ! cmp -s "$CONFIG_REAL" "$work/out"; then
    if [ -e "$CONFIG_REAL" ] && ! : 2>/dev/null >> "$CONFIG_REAL"; then
      echo "yorumi: $CONFIG_REAL is not writable (read-only or protected); configuration unchanged" >&2
      return 1
    fi
    [ -e "$CONFIG_REAL.yorumi-backup" ] || [ ! -s "$CONFIG_REAL" ] || cp -p "$CONFIG_REAL" "$CONFIG_REAL.yorumi-backup"
    if ! commit "$CONFIG_REAL" "$work/out"; then
      echo "yorumi: could not write $CONFIG" >&2
      exit 1
    fi
    if [ "$new" -eq 1 ]; then
      echo "✓ Wrote a config at $CONFIG ($FLAVOUR)"
    else
      echo "✓ Block written to $CONFIG ($FLAVOUR)"
    fi
  else
    echo "✓ Block already current in $CONFIG ($FLAVOUR)"
  fi
}

if [ "$ACTIVATE" -eq 1 ]; then
  write_block
else
  echo "• Activation skipped (--no-activate); the files are installed."
fi
