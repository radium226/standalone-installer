#!/bin/bash
set -euo pipefail

export SCRIPT_FILE_PATH="${0}"
export SCRIPT_FILE_NAME="$( basename "${SCRIPT_FILE_PATH}" )"
export FOLDER_PATH="./${SCRIPT_FILE_NAME%.*}.d"

export SUCCESS_CODE=0
export FAILURE_CODE=1

step_title()
{
  echo " ==> ${*}" >&2
}

step_detail()
{
  echo "      - ${*}" >&2
}

error()
{
  echo "${*}" >&2
}

die()
{
  local code
  code="${1}" ; shift
  error "${@}"
  exit ${code}
}

decompress_archive()
{
  local skip

  step_title "Decompressing data"
  skip="$( awk '/^__DATA__/ { print NR + 1; exit 0; }' "${SCRIPT_FILE_PATH}" )"
  test -d "${FOLDER_PATH}" || mkdir -p "${FOLDER_PATH}"
  tail -n +${skip} "${SCRIPT_FILE_PATH}" | base64 -d | tar -zpx -C "${FOLDER_PATH}"

  echo ${FOLDER_PATH}
}

filter_files()
{
  local as_root="${1}"
  while read file_path; do
    if [[ ! -f "${file_path}-SPEC" ]]; then
      die ${FAILURE_CODE} "No SPEC found for $( basename "${file_path}" )! "
    fi

    (
      set +u

      FOR_ROOT=false # By default, root is not required

      source ${file_path}-SPEC

      if ${FOR_ROOT} && ${as_root}; then
        echo "${file_path}"
      fi

      if ! ${FOR_ROOT} && ! ${as_root}; then
        echo "${file_path}"
      fi
    )
  done
}

filter_hooks()
{
  local as_root="${1}"
  while read hook_file_path; do
    (
      set +u

      FOR_ROOT=false # By default, root is not required
      source ${hook_file_path}

      if ${FOR_ROOT} && ${as_root}; then
        echo "${hook_file_path}"
      fi

      if ! ${FOR_ROOT} && ! ${as_root}; then
        echo "${hook_file_path}"
      fi
    )
  done
}

call_hooks()
{
  local hook_name="${1}"

  local folder_path="${2}"
  local environment="${3}"
  local as_root="${4}"

  step_title "Calling ${hook_name} hooks: "
  find "${folder_path}/hooks" -type "f" | filter_hooks ${as_root} | while read file_path; do
    (
      source "${folder_path}/variables/commons"
      source "${folder_path}/variables/${environment}"
      source "${file_path}"

      if type -t "${hook_name}" | grep -q '^function$' 2>/dev/null; then
        step_detail "$( basename "${file_path}" )"
        "${hook_name}"
      fi
    )
  done
}

install_files()
{
  local folder_path="${1}"
  local environment="${2}"
  local as_root="${3}"

  local file_path

  step_title "Installing files:"
  if [[ ! -f "${folder_path}/variables/${environment}" ]]; then
    die ${FAILURE_CODE} "Unable to find the ${environment} environment! "
  fi

  find "${folder_path}/files" -type "f" | grep -vE -- '-SPEC' | filter_files ${as_root} | while read file_path; do
    step_detail "$( basename "${file_path}" )"

    (
      FOR_ROOT=false
      TEMPLATE=false
      OWNER="$( id -un )"
      GROUP="$( id -gn )"
      TARGET_FILE_PATH=

      source "${folder_path}/variables/commons"
      source "${folder_path}/variables/${environment}"
      source "${file_path}-SPEC"

      if [[ -z "${TARGET_FILE_PATH}" ]]; then
        die ${FAILURE_CODE} "The TARGET_FILE_PATH should be defined for $( basename "${file_path}" )"
      fi

      mkdir -p "$( dirname "${TARGET_FILE_PATH}" )"

      if ${TEMPLATE}; then
        EOF="EOF_$RANDOM"
        eval echo "\"$(cat <<$EOF
$(<${file_path})
$EOF
)\""
      else
        cat "${file_path}"
      fi | tee "${TARGET_FILE_PATH}" >"/dev/null"
      chown "${OWNER}:${GROUP}" "${TARGET_FILE_PATH}"
    )
  done
}

main()
{
  local folder_path
  local as_root
  local environment
  local arguments

  arguments="$( getopt -o "" --long environment:,as-root -n "${SCRIPT_FILE_NAME}" -- "$@" )"
  eval set -- "${arguments}"

  as_root=false
  environment=
  while true; do
    case "${1}" in
      --as-root) as_root=true ; shift 1 ;;
      --environment ) environment="${2}"; shift 2 ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  if [[ -z "${environment}" ]]; then
    die ${FAILURE_CODE} "The --environment option must be defined! "
  fi

  folder_path="$( decompress_archive )"

  call_hooks "ON_BEGIN" "${folder_path}" "${environment}" "${as_root}"
  install_files "${folder_path}" "${environment}" "${as_root}"
  call_hooks "ON_END" "${folder_path}" "${environment}" "${as_root}"
}

main "${@}"
exit ${?}

__DATA__
