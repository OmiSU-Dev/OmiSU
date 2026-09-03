omisu_log_to_stdout() {
  [[ ${OMISU_LOG_TO_STDOUT:-} == "1" || -z ${OMISU_INSTALL_LOG_FILE:-} ]]
}

omisu_log_line() {
  if omisu_log_to_stdout; then
    echo "$1"
  else
    echo "$1" >>"$OMISU_INSTALL_LOG_FILE"
  fi
}

start_install_log() {
  if ! omisu_log_to_stdout; then
    mkdir -p "$(dirname "$OMISU_INSTALL_LOG_FILE")"
    touch "$OMISU_INSTALL_LOG_FILE"
    chmod 666 "$OMISU_INSTALL_LOG_FILE" 2>/dev/null || true
  fi

  export OMISU_START_TIME="${OMISU_START_TIME:-$(date '+%Y-%m-%d %H:%M:%S')}"
  export OMISU_START_EPOCH="${OMISU_START_EPOCH:-$(date +%s)}"

  omisu_log_line "=== OmiSu Setup Started: $OMISU_START_TIME ==="
}

stop_install_log() {
  local end_time end_epoch duration mins secs
  end_time=$(date '+%Y-%m-%d %H:%M:%S')
  end_epoch=$(date +%s)

  omisu_log_line "=== OmiSu Setup Completed: $end_time ==="

  if [[ -n ${OMISU_START_EPOCH:-} ]]; then
    duration=$((end_epoch - OMISU_START_EPOCH))
    mins=$((duration / 60))
    secs=$((duration % 60))
    omisu_log_line "OmiSu setup: ${mins}m ${secs}s"
  fi
}

run_logged() {
  local script="$1"
  local exit_code errexit_was_set=0

  omisu_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script"

  case $- in
    *e*)
      errexit_was_set=1
      set +e
      ;;
  esac

  local runner=(bash -eE)
  if [[ ${OMISU_INSTALL_DEBUG:-} == "1" ]]; then
    runner=(bash -x -eE)
  fi

  if omisu_log_to_stdout; then
    PS4='+ ${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}: ' \
      "${runner[@]}" -c 'source "$1"' bash "$script" </dev/null 2>&1
  else
    PS4='+ ${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}: ' \
      "${runner[@]}" -c 'source "$1"' bash "$script" </dev/null >>"$OMISU_INSTALL_LOG_FILE" 2>&1
  fi

  exit_code=$?
  (( errexit_was_set )) && set -e

  if (( exit_code == 0 )); then
    omisu_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script"
  else
    omisu_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)"
  fi

  return $exit_code
}
