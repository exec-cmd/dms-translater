#!/bin/sh
# Install src/ as the dmsTranslate plugin of DankMaterialShell 1.x or Dux Shell 2.x.
set -eu

usage() {
	cat <<'EOF'
Usage: install.sh [--link] [--force]

--link   symlink src/ instead of copying (edits in the repo apply after a reload)
--force  replace an existing plugin directory that is not dmsTranslate
EOF
	exit "${1:-0}"
}

link=0 force=0
while [ $# -gt 0 ]; do
	case $1 in
	--link) link=1 ;;
	--force) force=1 ;;
	-h | --help) usage ;;
	*) usage 1 ;;
	esac
	shift
done

id=dmsTranslate
repo=$(cd "$(dirname "$0")" && pwd)
config=${XDG_CONFIG_HOME:-$HOME/.config}
# Dux Shell 2.x reads ~/.config/dms, DankMaterialShell 1.x ~/.config/DankMaterialShell.
if [ -d "$config/dms" ]; then base=$config/dms/plugins; else base=$config/DankMaterialShell/plugins; fi
dest=$base/$id

if [ -e "$dest" ] || [ -L "$dest" ]; then
	if [ "$force" -eq 0 ] && ! grep -q "\"id\": \"$id\"" "$dest/plugin.json" 2>/dev/null; then
		echo "$dest exists and is not $id; use --force to replace it" >&2
		exit 1
	fi
	rm -rf "$dest"
fi

mkdir -p "$base"
if [ "$link" -eq 1 ]; then
	ln -s "$repo/src" "$dest"
else
	cp -R "$repo/src" "$dest"
fi

echo "installed $dest"
echo "reload: dms ipc call plugins reload $id (or Settings -> Plugins -> Scan for Plugins)"
