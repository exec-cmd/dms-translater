#!/bin/sh
# Remove the dmsTranslate plugin directory. Settings and API keys in plugin_settings.json stay.
set -eu

id=dmsTranslate
config=${XDG_CONFIG_HOME:-$HOME/.config}
for dest in "$config/dms/plugins/$id" "$config/DankMaterialShell/plugins/$id"; do
	[ -e "$dest" ] || [ -L "$dest" ] || continue
	if ! grep -q "\"id\": \"$id\"" "$dest/plugin.json" 2>/dev/null; then
		echo "skip    $dest (not $id)" >&2
		continue
	fi
	rm -rf "$dest"
	echo "removed $dest"
done
