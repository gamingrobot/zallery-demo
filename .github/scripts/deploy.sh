#!/bin/bash
# MIT License

# Copyright (c) 2019 Shaleen Jain

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e
set -o pipefail

# For backwards compatibility
if [[ -n "$TOKEN" ]]; then
    GITHUB_TOKEN=$TOKEN
fi

if [[ -z "$PAGES_BRANCH" ]]; then
    PAGES_BRANCH="gh-pages"
fi

if [[ -z "$BUILD_DIR" ]]; then
    BUILD_DIR="."
fi

if [[ -z "$OUT_DIR" ]]; then
    OUT_DIR="public"
fi

if [[ -n "$REPOSITORY" ]]; then
    TARGET_REPOSITORY=$REPOSITORY
else
    if [[ -z "$GITHUB_REPOSITORY" ]]; then
        echo "Set the GITHUB_REPOSITORY env variable."
        exit 1
    fi
    TARGET_REPOSITORY=${GITHUB_REPOSITORY}
fi

if [[ -z "$BUILD_ONLY" ]]; then
    BUILD_ONLY=false
fi

if [[ -z "$BUILD_THEMES" ]]; then
    BUILD_THEMES=true
fi

if [[ -z "$CHECK_LINKS" ]]; then
    CHECK_LINKS=false
fi

if [[ -z "$GITHUB_TOKEN" ]] && [[ "$BUILD_ONLY" == false ]]; then
    echo "Set the GITHUB_TOKEN or TOKEN env variables."
    exit 1
fi

if [[ -z "$GITHUB_HOSTNAME" ]]; then
    GITHUB_HOSTNAME="github.com"
fi

main() {
    echo "Starting deploy..."

    echo "Building in $BUILD_DIR directory"
    cd "$BUILD_DIR"

    git config --global url."https://".insteadOf git://
    ## $GITHUB_SERVER_URL is set as a default environment variable in all workflows, default is https://github.com
    git config --global url."$GITHUB_SERVER_URL/".insteadOf "git@${GITHUB_HOSTNAME}":

    # needed or else we get 'doubious ...' error
    echo "Disable safe directory check"
    git config --global --add safe.directory '*'

    if ${BUILD_THEMES}; then
        echo "Fetching themes"
        git submodule update --init --recursive
    fi

    version=$(zola --version)
    remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@${GITHUB_HOSTNAME}/${TARGET_REPOSITORY}.git"
    remote_branch=$PAGES_BRANCH

    echo "Using $version"

    echo Building with flags: ${BUILD_FLAGS:+"$BUILD_FLAGS"}
    zola build ${BUILD_FLAGS:+$BUILD_FLAGS}

    if ${CHECK_LINKS}; then
        echo "Checking links with flags: ${CHECK_FLAGS:+$CHECK_FLAGS}"
        zola check ${CHECK_FLAGS:+$CHECK_FLAGS}
    fi

    if ${BUILD_ONLY}; then
        echo "Build complete. Deployment skipped by request"
        exit 0
    else
        echo "Pushing artifacts to ${TARGET_REPOSITORY}:$remote_branch"

        cd "${OUT_DIR}"
        git init
        git config user.name "GitHub Actions"
        git config user.email "github-actions-bot@users.noreply.${GITHUB_HOSTNAME}"
        git add .

        git commit -m "Deploy ${TARGET_REPOSITORY} to ${TARGET_REPOSITORY}:$remote_branch"
        git push --force "${remote_repo}" master:"${remote_branch}"

        echo "Deploy complete"
    fi
}

main "$@"
