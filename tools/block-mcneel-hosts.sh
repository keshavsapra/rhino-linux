#!/usr/bin/env bash
# block-mcneel-hosts.sh — add or remove McNeel server blocks in /etc/hosts.
#
# Every name in mcneel-domains.txt is resolved to 127.0.0.1 (and ::1), so the
# system refuses connections to McNeel's servers outright. Wine resolves host
# names through the system resolver, so Rhino's update checks, statistics,
# licence pings, news panel and package manager all stop connecting.
#
#   block-mcneel-hosts.sh add      map McNeel servers to 127.0.0.1 in /etc/hosts
#   block-mcneel-hosts.sh remove   remove the block again
#   block-mcneel-hosts.sh list     show the block currently in /etc/hosts
#
# Needs root to edit /etc/hosts (uses sudo when run as a normal user). The
# entries sit between "# >>> rhino-linux mcneel block >>>" and its closing
# marker line, so adding twice changes nothing and removing takes the block
# out exactly. To also run Rhino in an isolated namespace instead of just
# blocking servers, see rhino-linux --offline and docs/offline.md.

set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DOMAINS_FILE="$TOOLS_DIR/mcneel-domains.txt"
HOSTS="/etc/hosts"

cmd="${1:-}"
case "$cmd" in
    add|remove|list) ;;
    *)
        echo "Usage: $0 add|remove|list" >&2
        exit 2
        ;;
esac

if [ "$cmd" = list ]; then
    if [ -f "$HOSTS" ] && grep -q "rhino-linux mcneel block" "$HOSTS"; then
        sed -n '/^# >>> rhino-linux mcneel block >>>/,/^# <<< rhino-linux mcneel block <<</p' "$HOSTS"
    else
        echo "No rhino-linux McNeel block found in $HOSTS."
    fi
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "error: editing $HOSTS needs root, and sudo is not available." >&2
        exit 1
    fi
    exec sudo "$0" "$cmd"
fi

if [ ! -f "$DOMAINS_FILE" ]; then
    echo "error: $DOMAINS_FILE not found next to this script." >&2
    exit 1
fi

python3 - "$cmd" "$DOMAINS_FILE" <<'PY'
import sys

cmd, domains_file = sys.argv[1], sys.argv[2]
path = "/etc/hosts"
OPEN = "# >>> rhino-linux mcneel block >>>"
CLOSE = "# <<< rhino-linux mcneel block <<<"

with open(domains_file) as f:
    domains = [line.strip() for line in f
               if line.strip() and not line.strip().startswith("#")]

with open(path) as f:
    lines = f.read().splitlines()

# Take the current block out first, so "add" twice keeps one block.
out, inside = [], False
for line in lines:
    if line.strip() == OPEN:
        inside = True
        continue
    if line.strip() == CLOSE:
        inside = False
        continue
    if not inside:
        out.append(line)
while out and not out[-1].strip():
    out.pop()

if cmd == "add":
    block = "\n".join([OPEN] + [f"127.0.0.1 {d}\n::1 {d}" for d in domains] + [CLOSE])
    text = "\n".join(out) + "\n\n" + block + "\n" if out else block + "\n"
else:
    text = "\n".join(out) + "\n" if out else ""

with open(path, "w") as f:
    f.write(text)

print(f"{cmd.capitalize()}ed the McNeel block ({len(domains)} domains, x2 for IPv6) in {path}.")
PY
