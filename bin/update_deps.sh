#!/bin/bash

# Copyright 2019 Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

UPDATE_BRANCH=${UPDATE_BRANCH:-"release-1.4"}

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR=$(dirname "${SCRIPTPATH}")
cd "${ROOTDIR}"

# Get the sha of top commit
# $1 = repo
function getSha() {
  local dir result
  dir=$(mktemp -d)
  git clone --depth=1 "https://github.com/istio/${1}.git" -b "${UPDATE_BRANCH}" "${dir}"

  result="$(cd "${dir}" && git rev-parse HEAD)"
  rm -rf "${dir}"

  echo "${result}"
}

make update-common

export GO111MODULE=on
go get -u "istio.io/operator@${UPDATE_BRANCH}"
go get -u "istio.io/api@${UPDATE_BRANCH}"
go get -u "istio.io/gogo-genproto@${UPDATE_BRANCH}"
go get -u "istio.io/pkg@${UPDATE_BRANCH}"
go mod tidy

sed -i "s/^BUILDER_SHA=.*\$/BUILDER_SHA=$(getSha release-builder)/" prow/release-commit.sh
sed -i '/PROXY_REPO_SHA/,/lastStableSHA/ { s/"lastStableSHA":.*/"lastStableSHA": "'"$(getSha proxy)"'"/  }' istio.deps
sed -i '/CNI_REPO_SHA/,/lastStableSHA/ { s/"lastStableSHA":.*/"lastStableSHA": "'"$(getSha cni)"'"/  }' istio.deps