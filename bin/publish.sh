#!/bin/sh

. "$(dirname "$0")/../lib/common.sh"

eval "$(getargs src dst)"

if [ -d "$src" ]; then
    if [ -f "$src"/Publish ]; then
        make -C "$src" Publish
        cat "$src"/Publish | sed 's/^/ls -d /' | (cd "$src"; sh) |
            sort | uniq | while read filename;
        do
            mkdir -p "$dst/$(dirname "$filename")"
            make -C "$src" "$filename"
            cp -a "$src/$filename" "$dst/$(dirname "$filename")"
        done
    fi

    ls -a "$src" | grep -v '^[.]*$' | while read filename; do
        if [ -d "$src/$filename" ]; then
            "$0" "$src/$filename" "$dst/$filename"
        fi
    done
else
    echo>&2 "$(basename "$0"): Don’t know what to do with ‘$src’"
    exit 2
fi
