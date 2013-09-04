#!/bin/bash
set -e
if [ "X$VERBOSE" != "X" ]; then
  set -x
fi

# makesrpm.sh - generates a .src.rpm from the currently checked out HEAD,
# along with condor.spec and the sources in this directory

usage () {
  echo "usage: $(basename "$0")"
  echo "Sorry, no options yet..."
  exit
}

case $1 in
  --help ) usage ;;
esac

# Do everything in a temp dir that will go away on errors or end of script
tmpd=$(mktemp -d -p $PWD .tmpXXXXXX)
trap 'rm -rf "$tmpd"' EXIT

pushd "$(dirname "$0")"   >/dev/null  # go to srpm dir
if [ "$#" -eq 1 ]; then
  pushd $1                >/dev/null
else
  pushd ../../..          >/dev/null  # go to root of git tree
fi

# why is it so hard to do a "git cat" ?
condor_version=$( git archive HEAD CMakeLists.txt | tar xO \
                  | awk -F\" '/^set\(VERSION / {print $2}' )

git archive HEAD | gzip > "$tmpd/condor.tar.gz"

git_rev=$(git log -1 --pretty=format:%h)

popd >/dev/null # back to srpm dir or initial dir.

# should verify this: [[ $condor_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]

mkdir "$tmpd/SOURCES"
cp -p -- * "$tmpd/SOURCES/"
mv "$tmpd/condor.tar.gz" "$tmpd/SOURCES/"

sed -i "
  s/^%define git_rev .*/%define git_rev $git_rev/
  s/^%define tarball_version .*/%define tarball_version $condor_version/
" "$tmpd/SOURCES/condor.spec"

srpm=$(rpmbuild -bs -D"_topdir $tmpd" "$tmpd/SOURCES/condor.spec")
srpm=${srpm#Wrote: }

popd >/dev/null # back to original working dir
mv "$srpm" .
#echo "Wrote: ${srpm##*/}"
