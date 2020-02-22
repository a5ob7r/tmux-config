#!/usr/bin/env bash
#
# A deploy script to remote server
#

# Set useful shell options
set -Cueo pipefail

readonly REPO_URL='https://api.github.com/repos/a5ob7r/tmux-config/tarball'
readonly CONF_DIR=~/.config
readonly TMUX_CONFIG_DIR="${CONF_DIR}/tmux"

readonly TMP_DIR="$(mktemp -d /tmp/a5ob7r_tmux-config_XXXXXXXX)"
trap 'rm -vrf ${TMP_DIR}' 0
trap 'rm -vrf ${TMP_DIR}; exit 1' 1 2 3 15
echo ":: Make a temporary working directory: ${TMP_DIR}"

echo ":: Download a archived repository and extract it"
curl -L "${REPO_URL}" | tar zx -C "${TMP_DIR}"
readonly REPO_DIR=$(find "${TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -name "a5ob7r-tmux-config-*")

if [[ -d "${CONF_DIR}" ]]; then
  echo ":: A config directory already exists: ${CONF_DIR}"
else
  echo ":: Make a config directory: ${CONF_DIR}"
  mkdir -vp "${CONF_DIR}"
fi

echo ":: Move a repository directory to a tmux config directory"
mv -vT --backup=t "${REPO_DIR}" "${TMUX_CONFIG_DIR}"

echo ":: Generate ~/.tmux.conf wihch is remote version into your home directory"
readonly TMPFILE="$(mktemp tmux.conf.XXXXXXXX)"
grep -Ev 'tmux-plugins/tmux-battery|@TMUX_CZ' "${TMUX_CONFIG_DIR}/tmux.conf" >| "${TMPFILE}"
mv -v --backup=t "${TMPFILE}" ~/.tmux.conf
