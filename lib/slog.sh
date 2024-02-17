#!/usr/bin/env sh
# ======================================================================
#
# NAME
#
#     slog.sh
#
# DESCRIPTION
#
#     A library of shell functions for writing formatted log messages to
#     standard output, standard error, and log files.
#
# USAGE
#
#     If you would like to use this library in your shell script, then 
#     source it at the beginning of your shell script.
#
#         source slog.sh
#
#     Once the library has been sourced, you can call functions from the 
#     library in your shell script.
#
# AUTHOR
#
#     Marty Kandes, Ph.D.
#     Computational & Data Science Research Specialist
#     High-Performance Computing User Services Group
#     Data-Enabled Scientific Computing Division
#     San Diego Supercomputer Center
#     University of California, San Diego
#
# LAST UPDATED
#
#     Sunday, March 14th, 2021
#
# ----------------------------------------------------------------------

# Declare the global logging level environment variable (SLOG_LEVEL) and
# set its default as not quiet (SLOG_LEVEL=1).

declare -xi SLOG_LEVEL=1

# ----------------------------------------------------------------------
# slog_output
#
#   Prints a message to standard output.
#
# Globals:
#
#   SLOG_LEVEL
#
# Arguments:
#
#   -m | --message 'output_message'
#
# Outputs:
#
#   Writes output_message to standard output.
#
# Returns:
#
#   True  (0) if slog_output executed successfully without issue.
#   False (1) if slog_output failed to execute properly.
#
# ----------------------------------------------------------------------
function slog_output() {

  # Declare local variables.
  local output_message

  # Assign default values to local variables.
  output_message=''

  # Read in command-line options and assign input variables to local
  # variables.
  while (("${#}" > 0)); do
    case "${1}" in
      -m | --message )
        output_message="${2}"
        shift 2
        ;;
      *)
        slog error -m "Command-line option ${1} not recognized or not supported."
        return 1
    esac
  done

  # If quiet mode (SLOG_LEVEL=0) is not enabled, then write the output 
  # message to standard output.
  if (( "${SLOG_LEVEL}" > 0 )); then

    echo "${output_message}" >&1

  fi
 
  return 0 
}

# ----------------------------------------------------------------------
# slog_error
#
#   Prints a message to standard error. These 'error' messages are 
#   intended to precede an exit failure and provide an explanation as 
#   to the cause of the failure.
#
# Globals:
#
#   SLOG_LEVEL
#
# Arguments:
#
#   -m | --message 'error_message'
#
# Outputs:
#
#   Writes error_message to standard error.
#
# Returns:
#
#   True  (0) if slog_error executed successfully without issue.
#   False (1) if slog_error failed to execute properly.
#
# ----------------------------------------------------------------------
function slog_error() {

  # Declare local variables.
  local error_message

  # Assign default values to local variables.
  error_message=''

  # Declare local variables.
  local output_message

  # Assign default  values to local variables.
  output_message=''

  # Read in command-line options and assign input variables to local
  # variables.
  while (("${#}" > 0)); do
    case "${1}" in
      -m | --message )
        error_message="${2}"
        shift 2
        ;;
      *)
        slog error -m "Command-line option ${1} not recognized or not supported."
        return 1
    esac
  done

  # If silent mode (SLOG_LEVEL=-1) is not enabled, then write the error
  # message to standard error.
  if (( "${SLOG_LEVEL}" >= 0 )); then

    echo "ERROR :: ${error_message}" >&2

  fi

  return 0

}

# ----------------------------------------------------------------------
# slog_warning
#
#   Prints a message to standard error. However, these 'warning' messages 
#   are not indended to preceded an exit failure. They are meant to be 
#   used to indicate a possible issue, which could eventually lead to a
#   failure, if not careful.
#
# Globals:
#
#   SLOG_LEVEL
#
# Arguments:
#
#   -m | --message 'warning_message'
#
# Outputs:
#
#   Writes warning_message to standard error.
#
# Returns:
#
#   True  (0) if slog_warning executed successfully without issue.
#   False (1) if slog_warning failed to execute properly.
#
# ----------------------------------------------------------------------
function slog_warning() {

  # Declare local variables.
  local warning_message

  # Assign default values to local variables.
  warning_message=''

  # Read in command-line options and assign input variables to local
  # variables.
  while (("${#}" > 0)); do
    case "${1}" in
      -m | --message )
        warning_message="${2}"
        shift 2
        ;;
      *)
        slog error -m "Command-line option ${1} not recognized or not supported."
        return 1
    esac
  done

  # If quiet mode (LOG_LEVEL=0) is not enabled, then write the warning 
  # message to standard error.
  if (( "${SLOG_LEVEL}" > 0 )); then

    echo "WARNING :: ${warning_message}" >&2

  fi

  return 0

}

# ----------------------------------------------------------------------
# slog_append
#
#   Appends a message to a file.
#
# Globals:
#
#   None
#
# Arguments:
#
#   -f | --file 'path_to_file'
#   -m | --message 'append_message'
#
# Outputs:
#
#   Appends append_message to path_to_file.
#
# Returns:
#
#   True  (0) if slog_append executed successfully without issue.
#   False (1) if slog_append failed to execute properly.
#
# ----------------------------------------------------------------------
function slog_append() {

  # Declare local variables.
  local path_to_file
  local append_message

  # Assign default values to local variables.
  path_to_file=''
  append_message=''

  # Read in command-line options and assign input variables to local
  # variables.
  while (("${#}" > 0)); do
    case "${1}" in
      -f | --file )
        path_to_file="${2}"
        shift 2
        ;;
      -m | --message )
        append_message="${2}"
        shift 2
        ;;
      *)
        slog error -m "Command-line option ${1} not recognized or not supported."
        return 1
    esac
  done

  # If path to file variable is not empty, then append message to file.
  if [[ -n "${path_to_file}" ]]; then

    echo "${append_message}" >> "${path_to_file}"
    if [[ "${?}" -ne 0 ]]; then
      return 1
    fi

  fi

  return 0

}

# ----------------------------------------------------------------------
# slog
#
#   The slog function is the standard interface used to control the 
#   execution of all other logging functions in the slog library. In 
#   general, users of the slog library should only call this function 
#   from their shell scripts. However, in special cases, users may call
#   individual slog library functions directly. 
#
# Globals:
#
#   @
#
# Arguments:
#
#   @
#
# Returns:
#
#   True  (0) if slog executed successfully without issue.
#   False (1) if slog failed to execute properly.
#
# ----------------------------------------------------------------------
function slog() {

  # Define local variables.
  local message_type

  # Assign default values to local variables.
  message_type=''

  # If at least one argument was provided by the user, then start 
  # parsing the list of arguments. Otherwise, throw an error.
  if (( "${#}" > 0 )); then

    # Read in the first command-line argument, which is expected to be
    # the type of log message the user expects to write.
    message_type="${1}"
    shift 1

    # Determine if the log message type provided by user is a valid. If
    # it is a valid message type, then execute the logging function used 
    # to write that type of message. Otherwise, throw an error.
    if [[ "${message_type}" = 'output' ]]; then

      slog_output "${@}"
      if [[ "${?}" -ne 0 ]]; then
        slog error -m 'Failed to run slog_output.'
        exit 1
      fi

    elif [[ "${message_type}" = 'error' ]]; then

      slog_error "${@}"
      if [[ "${?}" -ne 0 ]]; then
        slog error -m 'Failed to run slog_error.'
        exit 1
      fi

    elif [[ "${message_type}" = 'warning' ]]; then
              
      slog_warning "${@}"
      if [[ "${?}" -ne 0 ]]; then
        slog error -m 'Failed to run slog_warning.'
        exit 1
      fi

    elif [[ "${message_type}" = 'append' ]]; then

      slog_append "${@}"
      if [[ "${?}" -ne 0 ]]; then
        slog error -m 'Failed to run slog_append.'
        exit 1
      fi

    else

      slog error -m 'slog message type not recognized or not supported.'
      exit 1

    fi

  else

    slog error -m 'No arguments were provided to the slog function.'
    exit 1  

  fi

  return 0 

}

# ======================================================================
