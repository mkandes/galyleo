#!/usr/bin/env sh
# ======================================================================
#
# NAME
#
#     galyleo.sh
#
# DESCRIPTION
#
#     A shell utility to help you launch Jupyter notebooks on a remote
#     system in a secure way.
#
# USAGE
#
#     <INSERT USAGE DESCRIPTION HERE>
#
# DEPENDENCIES
#
#     <INSERT DEPS DESCRIPTION HERE>
#
# AUTHOR(S)
#
#     Marty Kandes, Ph.D.
#     Computational & Data Science Research Specialist
#     High-Performance Computing User Services Group
#     San Diego Supercomputer Center
#     University of California, San Diego
#
# LAST UPDATED
#
#     Saturday, March 13th, 2021
#
# ----------------------------------------------------------------------

declare -xr  GALYLEO_ROOT_DIR="${PWD}"
declare -xr  CURRENT_LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir CURRENT_UNIX_TIME="$(date +'%s')"
declare -xir RANDOM_ID="${RANDOM}"

source "${GALYLEO_ROOT_DIR}/lib/slog.sh"

# ----------------------------------------------------------------------
# galyleo_launch
#
#   Launches a Jupyter notebook server on a remote system. There are
#   several modes of operation that are supported with the 'launch'
#   command.
#
# Globals:
#
#   None
#
# Arguments:
#
#   @
#
# Returns:
#
#   True  (0) if the launch was successful.
#   False (1) if the launch failed and/or was halted.
#
# ----------------------------------------------------------------------
function galyleo_launch() {

  # Define local input variables.
  local -i slog_level
  local launch_mode
  local username
  local hostname
  local private_key
  local scheduler
  local script
  local account
  local reservation
  local queue
  local -i nodes
  local -i cpus_per_node
  local -i memory_per_cpu
  local -i gpus_per_node
  local gpus
  local gres
  local time_limit
  local jupyter_interface
  local jupyter_notebook_dir
  local reverse_proxy_fqdn
  local singularity_container
  local env_modules
  local conda_env
  local files_to_transfer

  # Define local internal variables
  local job_name
  local http_response
  local -i http_status_code
  local jupyter_launch_script
  local -i slurm_job_id

  # Assign default values to local input variables.
  slog_level=1 # Standard logging level. Set slog_level=0 for quiet mode.
  launch_mode='local' # or remote (via ssh)
  username="${USER}"
  hostname='login.expanse.sdsc.edu'
  private_key='id_rsa'
  scheduler='slurm' # or none (for direct launch)
  script=''
  account=''
  reservation=''
  queue='debug'
  nodes=1
  cpus_per_node=1
  memory_per_cpu=2 # in units of GB
  gpus_per_node=-1
  gpus=''
  gres='' 
  time_limit='00:30:00'
  jupyter_interface='lab' # or notebook
  jupyter_notebook_dir=''
  reverse_proxy_fqdn='expanse-user-content.sdsc.edu'
  dns_domain='eth.cluster'
  singularity_container=''
  env_modules=''
  conda_env=''
  files_to_transfer=''

  # Assign default values to internal variables
  job_name="galyleo-${CURRENT_LOCAL_TIME}-${CURRENT_UNIX_TIME}-${RANDOM_ID}"
  http_response=''
  http_status_code=-1
  REVERSE_PROXY_TOKEN=''
  jupyter_launch_script="${job_name}.sh"
  slurm_job_id=-1

  # Read in command-line options and assign input variables to local
  # variables.
  while (("${#}" > 0)); do
    case "${1}" in
      -l | --log-level )
        slog_level="${2}"
        shift 2
        ;;
      -M | --mode )
        launch_mode="${2}"
        shift 2
        ;;
      -u | --username )
        username="${2}"
        shift 2
        ;;
      -h | --hostname )
        hostname="${2}"
        shift 2
        ;;
      -k | --key )
        private_key="${2}"
        shift 2
        ;;
      -S | --scheduler )
        scheduler="${2}"
        shift 2
        ;;
      -b | --script )
        script="{2}"
        shift 2
        ;;
      -a | --account )
        account="${2}"
        shift 2
        ;;
      -r | --reservation )
        reservation="${2}"
        shift 2
        ;;
      -q | --queue )
        queue="${2}"
        shift 2
        ;;
      -n | --nodes )
        nodes="${2}"
        shift 2
        ;;
      -c | --cpus-per-node )
        cpus_per_node="${2}"
        shift 2
        ;;
      -m | --memory-per-cpu )
        memory_per_cpu="${2}"
        shift 2
        ;;
      -g | --gpus-per-node )
        gpus_per_node="${2}"
        shift 2
        ;;
      -G | --gpus )
        gpus="${2}"
        shift 2
        ;;
      --gres )
        gres="${2}"
        shift 2
        ;;
      -t | --time-limit )
        time_limit="${2}"
        shift 2
        ;;
      -j | --jupyter )
        jupyter_interface="${2}"
        shift 2
        ;;
      -d | --directory )
        jupyter_notebook_dir="${2}"
        shift 2
        ;;
      -p | --proxy )
        reverse_proxy_fqdn="${2}"
        shift 2
        ;;
      -D | --dns-domain )
        dns_domain="${2}"
        shift 2
        ;;
      -s | --sif )
        singularity_container="${2}"
        shift 2
        ;;
      -e | --env-modules )
        env_modules="${2}"
        shift 2
        ;;
      --conda-env )
        conda_env="${2}"
        shift 2
        ;;
      -f | --files )
        files_to_transfer="${2}"
        shift 2
        ;;
      *)
        slog_error "${slog_level}" "Command-line option ${1} not recognized or not supported."
        return 1
    esac
  done

  # Print all command-line options read in for launch to standard output.
  slog_output "${slog_level}" 'Preparing galyleo for launch into Jupyter orbit ...'
  slog_output "${slog_level}" ''
  slog_output "${slog_level}" 'Listing all launch parameters ...'
  slog_output "${slog_level}" '  command-line option     : value'
  slog_output "${slog_level}" "    -l | --log-level      : ${slog_level}"
  slog_output "${slog_level}" "    -M | --mode           : ${launch_mode}"
  slog_output "${slog_level}" "    -u | --username       : ${username}"
  slog_output "${slog_level}" "    -h | --hostname       : ${hostname}"
  slog_output "${slog_level}" "    -k | --key            : ${private_key}"
  slog_output "${slog_level}" "    -S | --scheduler      : ${scheduler}"
  slog_output "${slog_level}" "    -b | --script         : ${script}"
  slog_output "${slog_level}" "    -a | --account        : ${account}"
  slog_output "${slog_level}" "    -r | --reservation    : ${reservation}"
  slog_output "${slog_level}" "    -q | --queue          : ${queue}"
  slog_output "${slog_level}" "    -n | --nodes          : ${nodes}"
  slog_output "${slog_level}" "    -c | --cpus-per-node  : ${cpus_per_node}"
  slog_output "${slog_level}" "    -m | --memory-per-cpu : ${memory_per_cpu}"
  slog_output "${slog_level}" "    -g | --gpus-per-node  : ${gpus_per_node}"
  slog_output "${slog_level}" "    -G | --gpus           : ${gpus}"
  slog_output "${slog_level}" "       | --gres           : ${gres}"
  slog_output "${slog_level}" "    -t | --time-limit     : ${time_limit}"
  slog_output "${slog_level}" "    -j | --jupyter      : ${jupyter_interface}"
  slog_output "${slog_level}" "    -d | --directory      : ${jupyter_notebook_dir}"
  slog_output "${slog_level}" "    -p | --proxy          : ${reverse_proxy_fqdn}"
  slog_output "${slog_level}" "    -D | --dns-domain     : ${dns_domain}"
  slog_output "${slog_level}" "    -s | --sif            : ${singularity_container}"
  slog_output "${slog_level}" "    -e | --env-modules    : ${env_modules}"
  slog_output "${slog_level}" "       | --conda-env      : ${conda_env}"
  slog_output "${slog_level}" "    -f | --files          : ${files_to_transfer}"
  slog_output "${slog_level}" ''

  # Request a subdomain connection token from reverse proxy service. If the 
  # reverse proxy service returns an HTTP/S error, then halt the launch.
  http_response="$(curl -s -w %{http_code} https://manage.${reverse_proxy_fqdn}/getlink.cgi -o -)"
  http_status_code="$(echo ${http_response} | awk '{print $NF}')"
  if (( "${http_status_code}" != 200 )); then
    slog_error "${slog_level}" "Unable to connect to the reverse proxy service: ${http_status_code}"
    return 1
  fi

  # Export the fully qualified domain name of the reverse proxy host as
  # a read-only environment variable.
  declare -xr REVERSE_PROXY_FQDN="${reverse_proxy_fqdn}"
 
  # Extract the reverse proxy connection token and export it as a
  # read-only environment variable.
  declare -xr REVERSE_PROXY_TOKEN="$(echo ${http_response} | awk 'NF>1{printf $((NF-1))}' -)"

  # Check if the user specified a working directory for their Jupyter
  # notebook server. If the user did not specify a working directory, 
  # then set the working directory to the user's $HOME directory.
  if [[ -z "${jupyter_notebook_dir}" ]]; then
    jupyter_notebook_dir="${HOME}"  
  fi

  # Change the present working directory to the Jupyter notebook 
  # directory. If the directory does not exist, then halt the launch.
  cd "${jupyter_notebook_dir}"
  if [[ "${?}" -ne 0 ]]; then
    if [[ ! -d "${jupyter_notebook_dir}" ]]; then 
      slog_error "${slog_level}" "Jupyter notebook directory does not exist. Cannot change directory."
    else
      slog_error "${slog_level}" "Unable to change directory to the Jupyter notebook directory." 
    fi 
    return 1 
  fi

  # Generate an authentication token to be used for first-time 
  # connections to the Jupyter notebook server and export it as a 
  # read-only environment variable.
  declare -xr JUPYTER_TOKEN="$(openssl rand -hex 16)"

  # Generate a Jupyter launch script.
  slog_output "${slog_level}" 'Generating Jupyter launch script ...'
  if [[ ! -f "${jupyter_launch_script}" ]]; then

    echo '#!/usr/bin/env sh' > "${jupyter_launch_script}"
    echo '' >> "${jupyter_launch_script}"

    echo "#SBATCH --job-name=${job_name}" >> "${jupyter_launch_script}"
    if [[ -n "${account}" ]]; then
      echo "#SBATCH --account=${account}" >> "${jupyter_launch_script}"
    else
      slog_error "${slog_level}" 'No account specified. You must specify an account to charge the job against.'
      rm "${jupyter_launch_script}"
      return 1
    fi
    if [[ -n "${reservation}" ]]; then
      echo "#SBATCH --reservation=${reservation}" >> "${jupyter_launch_script}"
    fi 
    echo "#SBATCH --partition=${queue}" >> "${jupyter_launch_script}"
    echo "#SBATCH --nodes=${nodes}" >> "${jupyter_launch_script}"
    echo "#SBATCH --ntasks-per-node=${cpus_per_node}" >> "${jupyter_launch_script}"
    echo '#SBATCH --cpus-per-task=1' >> "${jupyter_launch_script}"
    echo "#SBATCH --mem-per-cpu=${memory_per_cpu}G" >> "${jupyter_launch_script}"
    if (( "${gpus_per_node}" > 0 )); then
      echo "#SBATCH --gpus-per-node=${gpus_per_node}" >> "${jupyter_launch_script}"
    elif [[ -n "${gpus}" && -z "${gres}" ]]; then
      echo "#SBATCH --gpus=${gpus}" >> "${jupyter_launch_script}"
    elif [[ -z "${gpus}" && -n "${gres}" ]]; then
      echo "#SBATCH --gres=${gres}" >> "${jupyter_launch_script}"
    fi
    echo "#SBATCH --time=${time_limit}" >> "${jupyter_launch_script}"
    echo "#SBATCH --output=${job_name}.o%j.%N" >> "${jupyter_launch_script}"
    echo '' >> "${jupyter_launch_script}"

    echo 'declare -xi  JUPYTER_PORT=-1' >> "${jupyter_launch_script}"
    echo 'declare -xir LOWEST_EPHEMERAL_PORT=49152' >> "${jupyter_launch_script}"
    echo 'declare -i   random_port=-1' >> "${jupyter_launch_script}"
    echo '' >> "${jupyter_launch_script}"

    echo 'module purge' >> "${jupyter_launch_script}"
    if [[ -n "${env_modules}" ]]; then
      IFS=','
      read -r -a modules <<< "${env_modules}"
      unset IFS
      for module in "${modules[@]}"; do
        echo "module load ${module}" >> "${jupyter_launch_script}"
      done
    fi

    if [[ -n "${conda_env}" ]]; then
      echo 'source ~/.bashrc' >> "${jupyter_launch_script}"
      echo "conda activate ${conda_env}" >> "${jupyter_launch_script}"
    fi
    echo '' >> "${jupyter_launch_script}"

    echo 'while (( "${JUPYTER_PORT}" < 0 )); do' >> "${jupyter_launch_script}"
    echo '  while (( "${random_port}" < "${LOWEST_EPHEMERAL_PORT}" )); do' >> "${jupyter_launch_script}"
    echo '    random_port="$(od -An -N 2 -t u2 -v < /dev/urandom)"' >> "${jupyter_launch_script}"
    echo '  done' >> "${jupyter_launch_script}"
    echo '  ss -nutlp | cut -d : -f2 | grep "^${random_port})" > /dev/null' >> "${jupyter_launch_script}"
    echo '  if [[ "${?}" -ne 0 ]]; then' >> "${jupyter_launch_script}"
    echo '    JUPYTER_PORT="${random_port}"' >> "${jupyter_launch_script}"
    echo '  fi' >> "${jupyter_launch_script}"
    echo 'done' >> "${jupyter_launch_script}"
    echo '' >> "${jupyter_launch_script}"

    echo 'declare -xr JUPYTER_RUNTIME_DIR="${HOME}/.jupyter/runtime"' >> "${jupyter_launch_script}"
    echo '' >> "${jupyter_launch_script}"

    if [[ -n "${singularity_container}" ]]; then
      echo "singularity exec ${singularity_container} jupyter ${jupyter_interface} --ip=\"\$(hostname -s).${dns_domain}\" --port=\"\${JUPYTER_PORT}\" --notebook-dir='${jupyter_notebook_dir}' --NotebookApp.allow_origin='*' --no-browser &" >> "${jupyter_launch_script}"
      echo 'if [[ "${?}" -ne 0 ]]; then' >> "${jupyter_launch_script}"
      echo "  echo 'ERROR: Failed to launch Jupyter.'" >> "${jupyter_launch_script}"
      echo '  exit 1' >> "${jupyter_launch_script}"
      echo 'fi' >> "${jupyter_launch_script}"
    else
      echo "jupyter ${jupyter_interface} --ip=\"\$(hostname -s).${dns_domain}\" --notebook-dir='${jupyter_notebook_dir}' --port=\"\${JUPYTER_PORT}\" --NotebookApp.allow_origin='*' --no-browser &" >> "${jupyter_launch_script}"
      echo 'if [[ "${?}" -ne 0 ]]; then' >> "${jupyter_launch_script}"
      echo "  echo 'ERROR: Failed to launch Jupyter.'" >> "${jupyter_launch_script}"
      echo '  exit 1' >> "${jupyter_launch_script}"
      echo 'fi' >> "${jupyter_launch_script}"
    fi
    echo '' >> "${jupyter_launch_script}"

    # Redeem the connection token from reverse proxy service.
    echo 'echo "https://manage.${REVERSE_PROXY_FQDN}/redeemtoken.cgi?token=${REVERSE_PROXY_TOKEN}&port=${JUPYTER_PORT}"' >> "${jupyter_launch_script}"
    echo "eval curl '\"https://manage.\${REVERSE_PROXY_FQDN}/redeemtoken.cgi?token=\${REVERSE_PROXY_TOKEN}&port=\${JUPYTER_PORT}\"'" >> "${jupyter_launch_script}"
    echo '' >> "${jupyter_launch_script}"

    echo 'wait' >> "${jupyter_launch_script}"

  else
    slog_error "${slog_level}" 'Jupyter launch script already exists. Cannot overwrite.'
    return 1
  fi

  # Launch Jupyter.
  slurm_job_id="$(sbatch ${jupyter_launch_script} | grep -o '[[:digit:]]*')"
  if [[ "${?}" -ne 0 ]]; then
    slog_error "${slog_level}" 'Failed job submission to Slurm.'
    return 1
  fi

  # Always print to standard output the URL where the Jupyter notebook 
  # server may be accessed by the user.
  echo "${slurm_job_id} https://${REVERSE_PROXY_TOKEN}.${REVERSE_PROXY_FQDN}?token=${JUPYTER_TOKEN}"

  return 0

}

# ----------------------------------------------------------------------
# galyleo_help
#
#   Provides usage information to help users run galyleo.
#
# Globals:
#
#   None
#
# Arguments:
#
#   None
#
# Returns:
#
#   True (0) always.
#
# ----------------------------------------------------------------------

function galyleo_help() {

  # Define local variables.
  local -i slog_level

  # Assign default values to local variables.
  slog_level=1 # Standard logging level. Set slog_level=0 for quiet mode.

  slog_output "${slog_level}" 'USAGE: galyleo.sh <command> [options] {values}'

  return 0

}

# ----------------------------------------------------------------------
# galyleo
#
#   Controls the execution of galyleo.
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
#   True  (0) if galyleo executed successfully without issue.
#   False (1) if galyleo failed to execute properly.
#
# ----------------------------------------------------------------------
function galyleo() {

  # Define local variables.
  local -i slog_level
  local galyleo_command

  # Assign default values to local variables.
  slog_level=1 # Standard logging level. Set slog_level=0 for quiet mode.

  # If at least one command-line argument was provided by the user, then
  # start parsing the command-line arguments. Otherwise, throw an error.
  if (( "${#}" > 0 )); then
 
    # Read in the first command-line argument, which is expected to be 
    # the main command issued by the user.
    galyleo_command="${1}"
    shift 1

    # Determine if the command provided by user is a valid. If it is a
    # valid command, then execute that command. Otherwise, throw an error.
    if [[ "${galyleo_command}" = 'launch' ]]; then

      galyleo_launch "${@}"
      if [[ "${?}" -ne 0 ]]; then
        slog_error "${slog_level}" 'galyleo_launch failed.'
        exit 1
      fi

    elif [[ "${galyleo_command}" = 'help' || \
            "${galyleo_command}" = '-h' || \
            "${galyleo_command}" = '--help' ]]; then

      galyleo_help
      if [[ "${?}" -ne 0 ]]; then
        slog_error "${slog_level}" 'galyleo_help failed.'
        exit 1
      fi
    
    else
    
      slog_error "${slog_level}" 'Command not recognized or not supported.'
      exit 1

    fi

  else

    slog_error "${slog_level}" 'No command-line arguments were provided.'
    exit 1

  fi
  
  exit 0

}

# ----------------------------------------------------------------------

galyleo "${@}"

# ======================================================================
