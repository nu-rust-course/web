#!/bin/sh

. "$(dirname "$0")/../lib/common.sh"

cd "$COURSE_ROOT"

src=.
dst=/tmp/upload

rm -Rf $dst
"$COURSE_BIN"/publish.sh $src $dst
rsync -avz --delete $dst/ $web_host:$web_path
ssh $web_host chmod -R a+rX $web_path
rm -Rf $dst
