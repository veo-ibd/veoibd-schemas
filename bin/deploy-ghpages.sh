#!/usr/bin/env bash

# A script to deploy JSON schema files to a GitHub pages branch.
# If the expected output directory already exists,  the script exits 
# without modifying anything (releases will not be overwritten).

set -o errexit

# The prefix of the URL where new released files will be
URLSTUB='https://github.com/veo-ibd/veoibd-schemas/blob/gh-pages/'

git config --global user.email "deploy@travis-ci.org"
git config --global user.name "Travis CI"

git checkout master

# Find the last released tag version on the master branch.
newversion=$(cat ./VERSION)

# Last commit on this tag to build URL to
lastcommit=$(git rev-parse HEAD)

echo "Found release version ${newversion}, commit ${lastcommit}."

# Copy schema files to temporary directory
rm -rf pages-out || exit 0;
mkdir pages-out
cp schemas/*.json ./pages-out/

# Create new release files on gh-pages branch
git remote add upstream "https://$GITHUB_TOKEN@github.com/veo-ibd/veoibd-schemas.git"
git fetch upstream
git checkout -b my-gh-pages upstream/gh-pages

if [ -d "assets/releases/${newversion}" ]
then
echo "Release ${newversion} directory exists, exiting.";
exit 0;
fi

mkdir assets/releases/${newversion}
cp ./pages-out/*.json assets/releases/${newversion}

printf "## ${newversion} ([view source](https://github.com/veo-ibd/veoibd-schemas/tree/${lastcommit}))\n\n" > pages-out/tmp-index.md

thefiles=$(find assets/releases/${newversion} -name "*.json")
for f in ${thefiles} ; do
    basefilename=$(basename ${f})
    echo "- [${basefilename}](${f})" >> pages-out/tmp-index.md ;
done

# Build new index.md
head -n 2 index.md > pages-out/new-index.md
cat pages-out/tmp-index.md >> pages-out/new-index.md
tail -n +2 index.md >> pages-out/new-index.md
cp pages-out/new-index.md index.md

git add assets/releases/${newversion}
git add index.md

git commit -m "Deployed new release ${newversion} to Github Pages"

git push --force --quiet upstream HEAD:gh-pages
