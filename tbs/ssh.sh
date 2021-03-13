#!/usr/bin/env bash
# ======================================================================
#
# NAME
#
#   ssh.sh
#
# DESCRIPTION
#
#   A library of bash functions to simplify SSH-related tasks.
#
# USAGE
#
#   If you would like to use this library in your own bash script, 
#   then you'll need to source it from your bash script.
#
#       source ssh.sh
#
#   Once the library has been sourced, you can call functions from the 
#   library in your own bash script.
#
# AUTHOR
#
#   Marty Kandes, Ph.D.
#   Computational & Data Science Research Specialist
#   High-Performance Computing User Services Group
#   San Diego Supercomputer Center
#   University of California, San Diego
#
# LAST UPDATED
#
#   Saturday, March 6th, 2021
#
# ----------------------------------------------------------------------

source "${GALYLEO_ROOT_DIR}/lib/log.sh"

# ----------------------------------------------------------------------
# ssh_authorize_public_key
#
#   Authorizes public SSH key on a remote host via password
#   authentication.
#
# Globals:
#
#   None
#
# Augments:
#
#   ssh_private_key
#   remote_username
#   remote_hostname
#
# Returns:
#
#   True  (0) if ssh-copy-id command succeeds.
#   False (1) if ssh-copy-id command fails.
#
# ----------------------------------------------------------------------
ssh_authorize_public_key() {

  # Define local variables.
  local ssh_private_key
  local ssh_public_key
  local remote_username
  local remote_hostname

  # Read in input variables and assign to local variables.
  ssh_private_key="${HOME}/.ssh/${1}"
  ssh_public_key="${ssh_private_key}.pub"
  remote_username="${2}"
  remote_hostname="${3}"

  # Copy public SSH key to authorized_keys file on remote host.
  log::output 'Authorizing public SSH key on remote host ...'
  log::output "  ssh-copy-id -i ${ssh_private_key} ${remote_username}@${remote_hostname}"
  ssh-copy-id -i "${ssh_private_key}" \
              -o PasswordAuthentication=yes \
              -o PubkeyAuthentication=no \
              -o PreferredAuthentications=password \
              "${remote_username}@${remote_hostname}"
  if [[ "${?}" -ne 0 ]]; then
    log::error 'Failed to authorize public SSH key on remote host.'
    return 1
  fi

  # If ssh-copy-id command succeeded, then public SSH key should have 
  # been written to ~/.ssh/authorized_keys file on remote host.
  log::output 'Authorized public SSH key on remote host.'
  return 0

}

# ----------------------------------------------------------------------
# ssh_directory_protected
# 
#   Checks if ~/.ssh directory where the SSH keypairs are stored is 
#   protected by secure permissions settings. 
#
# Globals:
#
#   None
#
# Arguments:
#
#   ssh_private_key
#
# Returns:
# 
#   True  (0) if ...
#   False (1) if ...
#
# ----------------------------------------------------------------------
ssh_directory_protected() {

  return 0

}

# ----------------------------------------------------------------------
# ssh_execute_command
#
#   Executes a command on a remote host.
#
# Globals:
#
#   None
#
# Arguments:
#
#   ssh_private_key
#   remote_username
#   remote_hostname
#   remote_command
#
# Returns:
#
#   True  (0) if remote_command was executed successfully on remote_host.
#   False (1) if remote_command failed to execute on remote_host and/or
#     returned a non-zero exit code.
#
# ----------------------------------------------------------------------
ssh_execute_command() {

  # Define local variables.
  local ssh_private_key
  local ssh_public_key
  local remote_username
  local remote_hostname
  local remote_command

  # Read in input variables and assign to local variables.
  ssh_private_key="${HOME}/.ssh/${1}"
  ssh_public_key="${ssh_private_key}.pub"
  remote_username="${2}"
  remote_hostname="${3}"
  remote_command="${4}"

  # Execute the command on the remote host.
  ssh -i "${ssh_private_key}" \
      -o IdentitiesOnly=yes \
      -o PasswordAuthentication=no \
      -o PubkeyAuthentication=yes \
      -o PreferredAuthentications=publickey \
      "${remote_username}@${remote_hostname}" \
      "${remote_command}"
  if [[ "${?}" -ne 0 ]]; then
    log::warning 'Failed to execute the command on remote host or the command was executed successfully, but it returned a non-zero exit code.'
    return 1
  fi

  # If the command executed successfully on remote host, do not return
  # any additional information to standard output in order to avoid 
  # unexpected output if it needs to be parsed further on return.
  return 0

}

# ----------------------------------------------------------------------
# ssh_find_keys
# 
#   Checks if an SSH keypair exists.
#
# Globals:
#
#   None
#
# Arguments:
#
#   ssh_private_key
#
# Returns:
#
#   True  (0) if ssh_private_key and ssh_public_key are found.
#   False (1) if ssh_private_key and ssh_public_key are not found.
#
# ----------------------------------------------------------------------
ssh_find_keys() {

  # Declare local variables.
  local ssh_private_key
  local ssh_public_key

  # Read in input variables and assign to local variables.
  ssh_private_key="${HOME}/.ssh/${1}"
  ssh_public_key="${ssh_private_key}.pub"

  # Check if private SSH key exists.
  log::output "Checking if private SSH key ${ssh_private_key} exists ..."
  if [[ ! -f "${ssh_private_key}" ]]; then
    log::error "Private SSH key ${ssh_private_key} not found."
    return 1
  else
    log::output "Private SSH key ${ssh_private_key} found."
  fi

  # Check if public SSH key exists.
  log::output "Checking if public SSH key ${ssh_public_key} exists ..."
  if [[ ! -f "${ssh_public_key}" ]]; then
    log::error "Public SSH key ${ssh_public_key} not found."
    return 1
  else
    log::output "Public SSH key ${ssh_public_key} found."
  fi

  # If both private and public SSH keys are found, then keypair exists.
  log::output "SSH keypair exists."
  return 0

}

# ----------------------------------------------------------------------
# ssh_generate_keys
#
#   Generates a new SSH keypair.
#
# Globals:
#
#   None
#
# Arguments:
#
#   ssh_private_key
#
# Returns:
# 
#   True  (0) if ssh-keygen command succeeds.
#   False (1) if ssh-keygen command fails.
#
# ----------------------------------------------------------------------
ssh_generate_keys() {

  # Declare local variables.
  local ssh_private_key
  local ssh_public_key

  # Read in input variables and assign to local variables.
  ssh_private_key="${HOME}/.ssh/${1}"
  ssh_public_key="${ssh_private_key}.pub"

  # Generate new SSH keypair.
  log::output 'Generating a new SSH keypair ...'
  ssh-keygen -o -t rsa -a 100 -b 4096 -f "${HOME}/.ssh/${ssh_private_key}"
  if [[ "${?}" -ne 0 ]]; then
    log::error 'Failed to generate new SSH keypair.'
    return 1
  fi

  # If ssh-keygen command succeeded, then a new SSH keypair should have 
  # been generated in ${HOME}/.ssh.
  log::output 'New SSH keypair was generated successfully.'
  return 0

}

# ----------------------------------------------------------------------
# ssh_private_key_protected
# 
#   Checks if a private SSH key is protected by a passphrase by 
#   attempting to change its passphrase.
#
# Globals:
#
#   None
#
# Arguments:
#
#   ssh_private_key
#
# Returns:
# 
#   True  (0) if ssh_private_key is protected by passphrase.
#   False (1) if ssh_private_key is not protected by passphrase.
#
# ----------------------------------------------------------------------
ssh_private_key_protected() {

  # Define local variables.
  local ssh_private_key

  # Read in input variables and assign to local variables.
  ssh_private_key="${HOME}/.ssh/${1}"

  # Check if private SSH key is protected by a passphrase.
  log::output 'Checking if private SSH key is protected by a passphrase ...'
  log::output 'Attempting to change passphrase on private SSH key ...'
  ssh-keygen -p -P '' -N '' -f "${ssh_private_key}"
  if [[ "${?}" -eq 0 ]]; then
    log::warning 'Passphrase of private SSH key has been changed!'
    log::error 'Private SSH key is not protected by a passphrase.'
    return 1
  fi

  # If the passphrase change failed, then the private SSH key is 
  # protected by a passphrase.
  log::output 'Failed to change passphrase of private SSH key.'
  log::output 'Private SSH key is protected by a passphrase.'
  return 0

}

# ----------------------------------------------------------------------
# ssh_mkdir
#
#   Create a directory on a remote host, if it does not already exist.
#
# Globals:
#
# Arguments:
#
#   ssh_private_key
#   remote_username
#   remote_hostname
#   remote_directory
#
# Returns:
#
#   True  (0) if ...
#   False (0) if ...
#
# ----------------------------------------------------------------------
ssh_mkdir() {

  # Define local variables.
  local ssh_private_key
  local remote_username
  local remote_hostname
  local remote_directory

  # Read in input variables and assign to local variables.
  ssh_private_key="${1}"
  remote_username="${2}"
  remote_hostname="${3}"
  remote_directory="${4}"

  # Check if the directory exists on the remote host's filesystem. If
  # the directory does not exist, then create it.
  log::output "Checking if the directory ${remote_directory} exists on ${remote_hostname} ..."
  ssh_execute_command "${ssh_private_key}" \
                       "${remote_username}" \
                       "${remote_login_hostname}" \
                       "cd ${remote_directory}"
  if [[ "${?}" -ne 0 ]]; then
    # Remote directory does not yet exist. Attempt to create it.
    log::warning 'Directory not found on remote host.'
    log::output "Attempting to create the directory ${remote_directory} on ${remote_hostname} ..."
    ssh_execute_command "${ssh_private_key}" \
                         "${remote_username}" \
	                 "${remote_login_hostname}" \
                         "mkdir -m 700 -p ${remote_directory}"
    if [[ "${?}" -ne 0 ]]; then
      # Failed to create the directory. Halt launch.
      log::error 'Failed to create the directory on the remote host.'
      return 1
    else
      log::output 'Directory created successfully on the remote host.'
    fi
  else
    log::output 'Found an existing directory on the remote host.'
  fi

  return 0

}

# ----------------------------------------------------------------------
# ssh_transfer_files
#
#   Transfer a file or set of files to a directory on a remote host.
#
# Globals:
#
# Arguments:
#
#   ssh_private_key
#   remote_username
#   remote_hostname
#   remote_directory
#   files_to_transfer
#
# Returns:
#   
#   True  (0) if ...
#   False (0) if ...
#
# ----------------------------------------------------------------------
ssh_transfer_files() {

  # Define local variables.
  local ssh_private_key
  local remote_username
  local remote_hostname
  local remote_directory
  local files_to_transfer
  local -a files
  local -a md5sums

  # Read in input variables and assign to local variables.
  ssh_private_key="${HOME}/.ssh/${1}"
  remote_username="${2}"
  remote_hostname="${3}"
  remote_directory="${4}"
  files_to_transfer="${5}"
  files=()

  # Parse the list of files to be transfered from the local host to the
  # remote host and store the local paths to these files in an array.
  IFS=', '
  read -r -a files <<< "$(echo ${files_to_transfer})"
  unset IFS

  # Check if all of the files to be transfered to the remote host can be
  # found on the local host. If at least one of the files cannot be 
  # found, then throw an error and stop the file transfer.
  for file in "${files[@]}"; do
    if [[ ! -f "${file}" ]]; then
       log::error "File not found: ${file}"
       log::error "File transfer cannot be started."
       return 1
    fi     
  done

  # Compute md5sum for each file to check integrity on the remote host 
  # after all of the file transfers have been completed. 
  for file in "${files[@]}"; do
    md5sum "${file}" >> md5s
  done
  files+=('md5s')

  # Transfer all files via scp to remote directory. 
  for file in "${files[@]}"; do
    scp -i "${ssh_private_key}" \
        -o IdentitiesOnly=yes \
        -o PasswordAuthentication=no \
        -o PubkeyAuthentication=yes \
        -o PreferredAuthentications=publickey \
        "${file}" \
        "${remote_username}@${remote_hostname}:${remote_directory}/${file}"
    if [[ "${?}" -ne 0 ]]; then
      log::warning "Failed to transfer file on first attempt: ${file}"
      log::output "Making second attempt at file transfer ..."
      scp -i "${ssh_private_key}" \
          -o IdentitiesOnly=yes \
          -o PasswordAuthentication=no \
          -o PubkeyAuthentication=yes \
          -o PreferredAuthentications=publickey \
          "${file}" \
          "${remote_username}@${remote_hostname}:${remote_directory}/${file}"
      if [[ "${?}" -ne 0 ]]; then
        log::error "Failed to transfer file on second attempt: ${file}"
        return 1
      fi
    fi
  done

  return 0

}

# ======================================================================
