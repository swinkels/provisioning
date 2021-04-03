#!/usr/bin/env bash
commit_hash=`cd $1 && git rev-parse HEAD | cut -c1-7`
if [[ $(cd $1 && git status --short --untracked-files=no) ]]; then
    echo $commit_hash-dirty
else
    echo $commit_hash
fi
