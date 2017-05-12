#!/usr/bin/env bash
set -eu

: "${BASEDIR:=.}"
: "${BUILDIR:=$BASEDIR/build}"

mkdir -p "$BUILDIR/dist"

cd "$BASEDIR"
BASENAME=$(basename "$(pwd)")

PLUGINS=( $(for f in */plugin.yaml; do dirname "$f"; done) )

package() {
	local -r build_dir=$1 plugin=$2
	mkdir -p "$build_dir/$BASENAME-$plugin"
	cp -r "$plugin"/* "$build_dir/$BASENAME-$plugin"
	(cd "$build_dir" &&
	zip -r "dist/${BASENAME}-${plugin}.zip" "$BASENAME-$plugin")
}

install() {
	local -r build_dir=$1 plugin=$2
	cp -v "$BUILDIR/dist/${BASENAME}-${plugin}.zip" "$RDECK_BASE/libext"
}


package_all() {
	local -ra plugins=("$@")
	for plugin in ${plugins[*]:-}
	do
		package $BUILDIR "$plugin"
	done
}

install_all() {
	local -ra plugins=("$@")
	for plugin in ${plugins[*]:-}
	do
		install $BUILDIR "$plugin"
	done	
}

# Package the plugins
package_all "${PLUGINS[@]}"

# Copy the plugins to the libext directory
if [[ -n "${RDECK_BASE:-}" ]]
then
	install_all "${PLUGINS[@]}"
fi

exit $?
# end.
