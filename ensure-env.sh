#!/bin/bash
##
## Copyright © 2018 Cisco Systems, Inc.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
set -uo pipefail

#################################################
# CONSTANTS
DEP_ERROR="######################### DEPENDENCY ERROR #########################"

#################################################
# FUNCTIONS

pyrealpath() {
  python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${@}
}

silent() {
  $@ 2>&1 > /dev/null
}

ensureTools() {
  MISSING_TOOLS=""
  for tool in $@; do
    if ! silent which $tool; then
      MISSING_TOOLS+="\n  $tool"
    fi
  done
  if [ ! -z "$MISSING_TOOLS" ]; then
      echo ${DEP_ERROR}
      echo "Please install the following missing tools'"
      echo -e "  $MISSING_TOOLS"
      echo ${DEP_ERROR}
      exit 1
  fi
}

#################################################
# Ensure Primary Tool Dependencies are Installed and Configured

ensureTools "direnv go python"

if [ -z "${GOPATH}" ]; then
  echo ${DEP_ERROR}
  echo '$GOPATH must be set for go builds and installs to work properly'
  echo ${DEP_ERROR}
  exit 1
fi

if ! (echo "${PATH}" | silent grep "${GOPATH}/bin"); then
  echo ${DEP_ERROR}
  echo 'The path "${GOPATH}/bin" must be set in your $PATH for go installed tools to work properly'
  echo ${DEP_ERROR}
  exit 1
fi

#################################################
# Remove old versions of tools

if which yq |grep ${GOPATH} > /dev/null; then
  echo "Please uninstall the golang version of 'yq'"
  echo "  It must be replaced with the python version of 'yq'"
  echo "  rm -f `which yq`"
  exit 1
fi

#################################################
# Final check for missing tools,
#   some of which could not be auto-installed from above

ensureTools "direnv go kubectl jinja2 ansible ansible-playbook kops dig python ssh-keygen aws mh terraform pip helm"


#################################################
# Ensure Helm settings

declare -A repo_to_url
repo_to_url=( \
  ["incubator"]="https://kubernetes-charts-incubator.storage.googleapis.com" \
  ["cisco-sso"]="https://raw.githubusercontent.com/cisco-sso/charts/master/pkg" \
)

helm_dirty=false
if [[ ! -f ~/.helm/repository/repositories.yaml ]]; then
  echo "Initializing Helm Client"
  helm init --client-only
  helm_dirty=true
fi

helm_repos=$(helm repo list)
for repo in "${!repo_to_url[@]}"; do
  url=${repo_to_url[$repo]}
  if ! (echo "$helm_repos" | grep "$repo" &>/dev/null); then
    echo "Adding Helm Repo '$repo' '$url'"
    helm repo add "$repo" "$url"
    helm_dirty=true
  fi
done

if $helm_dirty; then
  helm repo update
fi

#################################################
# kubectl symlink
if [[ -n ${KUBE_SERVER_VERSION+set} ]]; then
  kube_major=${KUBE_SERVER_VERSION%%.*}
  kube_minor=${KUBE_SERVER_VERSION%.*} ; kube_minor=${kube_minor#*.}
  default_kube_symlink=$(which kubectl)
  kubectl_dir=$(dirname $default_kube_symlink)
  if compgen -G "$kubectl_dir/kubectl_${kube_major}.${kube_minor}*" &>/dev/null; then
    # there is kubectl available matching cluster version
    kubectl_bin=$(compgen -G "$kubectl_dir/kubectl_${kube_major}.${kube_minor}*")
    mkdir -p bin
    bin_folder=$(pwd)/bin
    PATH_add $bin_folder
    ln -s -f ${kubectl_bin} $bin_folder/kubectl
  fi
fi
