#!/usr/bin/env bash

set -euo pipefail

home_dir="${HOME:?HOME must be set}"
ssh_dir="${home_dir}/.ssh"
key_name="${INPUT_NAME:-id_rsa}"
key_path="${ssh_dir}/${key_name}"
known_hosts_path="${ssh_dir}/known_hosts"
config_path="${ssh_dir}/config"
if_key_exists="${INPUT_IF_KEY_EXISTS:-fail}"

mkdir -p "${ssh_dir}"
chmod 700 "${ssh_dir}"

if [[ -e "${key_path}" ]]; then
  case "${if_key_exists}" in
    replace)
      ;;
    ignore)
      exit 0
      ;;
    fail)
      echo "SSH key already exists at ${key_path}" >&2
      exit 1
      ;;
    *)
      echo "Unsupported if_key_exists value: ${if_key_exists}" >&2
      exit 1
      ;;
  esac
fi

umask 077
printf '%s\n' "${INPUT_KEY}" > "${key_path}"
chmod 600 "${key_path}"

touch "${known_hosts_path}"
chmod 600 "${known_hosts_path}"

if ! ssh-keyscan -H github.com >> "${known_hosts_path}" 2>/dev/null; then
  echo "Failed to fetch github.com host keys" >&2
  exit 1
fi

if [[ "${INPUT_KNOWN_HOSTS:-}" != "unnecessary" ]]; then
  printf '%s\n' "${INPUT_KNOWN_HOSTS}" >> "${known_hosts_path}"
fi

if [[ -n "${INPUT_CONFIG:-}" ]]; then
  touch "${config_path}"
  chmod 600 "${config_path}"
  printf '%s\n' "${INPUT_CONFIG}" >> "${config_path}"
fi
