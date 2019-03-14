#/usr/bin/env bash
# ======================================================================
#
# NAME
# 
#     galyleo.sh
#
# DESCRIPTION
#
#     A bash script to help launch Jupyter notebooks on a remote system.
#
# USAGE
#
#     ./galyleo.sh configure --user mkandes
#
#     ./galyleo.sh launch --user mkandes --account use300 --partition gpu-shared --nodes 1 --tasks-per-node 6 --gpus-per-node 1 --time-limit 00:30:00 --image /share/apps/gpu/singularity/images/pytorch/pytorch-gpu.simg --workdir /oasis/scratch/comet/mkandes/temp_project
#
# LAST UPDATED
#
#     Wednesday, March 13th, 2019
#
# ----------------------------------------------------------------------

declare -xr CURRENT_LOCAL_TIME="$(date +'%Y%m%dT%H%M%S%z')"
declare -xir CURRENT_UNIX_TIME="$(date +'%s')"
declare -xir LOWEST_EPHEMERAL_PORT=49152
declare -xir HIGHEST_EPHEMERAL_PORT=65535

galyleo_output() {

  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: galyleo: $@" >&1

}

galyleo_error() {

  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: galyleo: ERROR :: $@" >&2

}


galyleo_warning() {

  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: galyleo: WARNING :: $@" >&2

}

galyleo_configure() {

  galyleo_output "Configuring ~/.ssh/config and ssh keys for galyleo ..."

  local user="${USER}"
  local system='comet'
  local domain='sdsc.edu'
  local key='id_rsa'

  galyleo_output "Reading in all command-line options for 'configure' command ..."
  while (("${#}" > 0)); do
    galyleo_output "Read in command-line option '${1}' with input value '${2}'."
    case "${1}" in
      -u | --user )
        user="${2}"
        ;;
      -s | --system )
        system="${2}"
        ;;
      -d | --domain )
        domain="${2}"
        ;;
      -k | --key )
        key="${2}"
        ;;
      *)
        galyleo_error "Command-line option ${1} not recognized or not supported."
        return 1
    esac
    shift 2
  done
  galyleo_output "All command-line options for 'configure' command have been read. "

  galyleo_output "Printing out 'configure' command settings ..."
  galyleo_output "user@system.domain: ${user}@${system}.${domain}"
  galyleo_output "key: ${key}"

  galyleo_output "Checking if ~/.ssh/config exists ..."
  if [[ ! -f "${HOME}/.ssh/config" ]]; then
    galyleo_output "~/.ssh/config does not exist."
    galyleo_output "Creating new ~/.ssh/config ..."
    echo "Host ${system}" > "${HOME}/.ssh/config"
    echo "Hostname ${system}.${domain}" >> "${HOME}/.ssh/config"
    echo "User ${user}" >> "${HOME}/.ssh/config"
  else
    galyleo_output "~/.ssh/config already exists."
    galyleo_output "Checking if ${system}.${domain} is already exists in ~/.ssh/config ..."
    grep "Hostname ${system}.${domain}" "${HOME}/.ssh/config"
    if [[ "${?}" -ne 0 ]]; then
      galyleo_output "${system}.${domain} not found in ~/.ssh/config."
      galyleo_output " Appending ${system}.${domain} configuration to ~/.ssh/config ..."
      echo '' >> "${HOME}/.ssh/config"
      echo "Host ${system}" > "${HOME}/.ssh/config"
      echo "Hostname ${system}.${domain}" >> "${HOME}/.ssh/config"
      echo "User ${user}" >> "${HOME}/.ssh/config"
    else
      galyleo_output "${system}.${domain} already exists in ~/.ssh/config."
    fi
  fi

  galyleo_output "Checking if ssh public key already exists ..."
  if [[ ! -f "${HOME}/.ssh/${key}.pub" ]]; then
    galyleo_output "ssh public key not found."
    galyleo_output "Generating new ssh keypair ..."
    # Future ssh-keygen command once Comet updates to CentOS 7 / OpenSSH 6.5+?
    #   ssh-keygen -o -t rsa -a 100 -b 4096 -f "${HOME}/.ssh/${key}"
    ssh-keygen -t rsa -f "${HOME}/.ssh/${key}"
    galyleo_output "New ssh keypair generated."
    galyleo_output "Adding new ssh key to ssh-agent ..."
    ssh-add "${HOME}/.ssh/${key}"
    galyleo_output "New ssh key added to ssh-agent."
  else
    galyleo_output "ssh public key already exists."
  fi
  galyleo_output "Copying ssh public key to ${system}.${domain} ..."
  ssh-copy-id -i "${HOME}/.ssh/${key}.pub" "${user}@${system}.${domain}"

  return 0

}


galyleo_launch() {

  galyleo_output "Launching galyleo into Jupyter orbit ..."

  local user="${USER}"
  local system='comet'
  local domain='sdsc.edu'
  local key='id_rsa'

  local job_name='galyleo'
  local account=''
  local partition='debug'
  local -i nodes=1
  local -i tasks_per_node=24
  local -i cpus_per_task=1
  local -i gpus_per_node=0
  local gpu_type=''
  local time_limit='00:30:00'
  local jupyter='jupyter'
  local image='/share/apps/compute/singularity/images/jupyter/jupyter-cpu.simg'
  local workdir=''

  local galyleo_job_id=''
  local job_script=''
  local -i port=8888
  local -r token="$(openssl rand -hex 32)"
  local -i slurm_job_id=0
  local slurm_job_state='UNKNOWN' 

  galyleo_output "Reading in all command-line options for 'launch' command ..."
  while (("${#}" > 0)); do
    galyleo_output "Read in command-line option '${1}' with input value '${2}'."
    case "${1}" in
      -u | --user )
        user="${2}"
        ;;
      -s | --system )
        system="${2}"
        ;;
      -d | --domain )
        domain="${2}"
        ;;
      -k | --key )
        key="${2}"
        ;;
      -j | --job-name )
        job_name="${2}"
        ;;
      -a | --account )
        account="${2}"
        ;;
      -p | --partition )
        partition="${2}"
        ;;
      -n | --nodes )
        nodes="${2}"
        ;;
      -t | --tasks-per-node )
        tasks_per_node="${2}"
        ;;
      -c | --cpus-per-task )
        cpus_per_task="${2}"
        ;;
      -g | --gpus-per-node )
        gpus_per_node="${2}"
        ;;
      -gt | --gpu-type )
        gpu_type="${2}"
        ;;
      -w | --time-limit )
        time_limit="${2}"
        ;;
      -i | --image )
        image="${2}"
        ;;
      --workdir )
        workdir="${2}"
        ;;
      --ipython )
        jupyter='ipython'
        ;;
      *)
        galyleo_error "Command-line option ${1} not recognized or not supported."
        return 1
    esac
    shift 2
  done
  galyleo_output "All command-line options for 'launch' command have been read. "

  galyleo_output "Printing out 'launch' command settings ..."
  galyleo_output "user@system.domain: ${user}@${system}.${domain}"
  galyleo_output "key: ${key}"
  galyleo_output "job_name: ${job_name}"
  galyleo_output "account: ${account}"
  galyleo_output "partition: ${partition}"
  galyleo_output "nodes: ${nodes}"
  galyleo_output "tasks_per_node: ${tasks_per_node}"
  galyleo_output "cpus_per_task: ${cpus_per_task}"
  galyleo_output "gpus_per_node: ${gpus_per_node}"
  galyleo_output "gpu_type: ${gpu_type}"
  galyleo_output "time_limit: ${time_limit}"
  galyleo_output "image: ${image}"
  galyleo_output "workdir: ${workdir}"

  galyleo_output "Generating ephemeral port for Jupyter ..."
  while (( "${port}" < "${LOWEST_EPHEMERAL_PORT}" )); do
    port="$(od -An -N 2 -t u2 -v < /dev/urandom)"
  done
  galyleo_output "Ephemeral port generated: ${port}"

  galyleo_output "Generating batch job script to launch Jupyter ..."
  galyleo_job_id="$(openssl rand -hex 8)" 
  job_script="galyleo-${system}-${job_name}-${CURRENT_UNIX_TIME}-${CURRENT_LOCAL_TIME}-${galyleo_job_id}.slurm" 
  echo "#!/usr/bin/env bash" > "${job_script}"
  echo "# ${job_script}" >> "${job_script}"
  echo " " >> "${job_script}"
  echo "#SBATCH --job-name=${job_name}" >> "${job_script}"
  if [[ -n "${account}" ]]; then
    echo "#SBATCH --account=${account}" >> "${job_script}"
  fi
  echo "#SBATCH --partition=${partition}" >> "${job_script}"
  echo "#SBATCH --nodes=${nodes}" >> "${job_script}"
  echo "#SBATCH --ntasks-per-node=${tasks_per_node}" >> "${job_script}"
  echo "#SBATCH --cpus-per-task=${cpus_per_task}" >> "${job_script}"
  if (( "${gpus_per_node}" > 0 )); then
    if [[ -n "${gpu_type}" ]]; then
      echo "#SBATCH --gres=gpu:${gpu_type}:${gpus_per_node}" >> "${job_script}" 
    else
      echo "#SBATCH --gres=gpu:${gpus_per_node}" >> "${job_script}"
    fi
  fi
  echo "#SBATCH --time=${time_limit}" >> "${job_script}"
  echo "#SBATCH --no-requeue" >> "${job_script}"
  echo "#SBATCH --output=${job_name}.o%j.%N" >> "${job_script}"
  echo " " >> "${job_script}"
  echo 'declare -xr LOCAL_SCRATCH="/scratch/${USER}/${SLURM_JOB_ID}"' >> "${job_script}"
  echo 'declare -xr LUSTRE_SCRATCH="/oasis/scratch/comet/${USER}/temp_project"' >> "${job_script}"
  echo " " >> "${job_script}"
  echo "module purge" >> "${job_script}"
  echo "module load singularity" >> "${job_script}"
  echo "module list" >> "${job_script}"
  echo "printenv" >> "${job_script}"
  echo " " >> "${job_script}"
  echo "cd ${SLURM_SUBMIT_DIR}" >> "${job_script}"
  echo "singularity exec ${image} ${jupyter} notebook --notebook-dir=${workdir} --no-browser --port=${port} --NotebookApp.token=${token}" >> "${job_script}"
  galyleo_output "Batch job script generated."

  galyleo_output "Uploading Jupyter batch job script to ${system} ..."
  if [[ -z "${workdir}" ]]; then
    workdir="$(ssh ${system} 'echo ${HOME}')"
  fi
  scp "${job_script}" "${system}:${workdir}"
  galyleo_output "Upload complete."
 
  galyleo_output "Submitting Jupyter batch job script to ${system} ..."
  slurm_job_id="$(ssh ${system} "cd ${workdir}; sbatch ${job_script} | grep -o '[[:digit:]]*'")" 
  galyleo_output "Batch job submitted. Batch job id: ${slurm_job_id}"

  while [[ "${slurm_job_state}" != 'RUNNING' ]]; do
    slurm_job_state="$(ssh ${system} "squeue -j ${slurm_job_id} --noheader --Format='state:.7'")"
    echo "${slurm_job_state}"
    galyleo_output "Waiting for batch job to start running ..."
    sleep 30
  done
  galyleo_output "Batch job is running!"

  galyleo_output "Determining job nodelist ..."
  slurm_job_nodelist="$(ssh ${system} "squeue -j ${slurm_job_id} --noheader --Format='nodelist' | sed -e 's/[[:space:]]*$//'")"
  galyleo_output "Job nodelist: ${slurm_job_nodelist}"

  galyleo_output "Opening SSH tunnel ..."
  ssh -f -N -L "localhost:${port}:localhost:${port}" "${user}@${slurm_job_nodelist}.${domain}"
  galyleo_output "SSH tunnel opened."

  galyleo_output "Opening web browser ..."
  firefox --new-window "http://localhost:${port}/?token=${token}"
  if [[ "${?}" -ne 0 ]]; then
     open -a safari "http://localhost:${port}/?token=${token}"
  fi 

  return 0

}


main() {

  local galyleo_command=''

  if (( "${#}" > 0 )); then 
    # at least one command-line arguments was provided. The first 
    # argument is expected to be main command issued by the user. Read 
    # in that command and then determine if it is a valid command.

    galyleo_command="${1}"
    shift 1

    if [[ "${galyleo_command}" = 'configure' ]]; then

      galyleo_configure "${@}"
      if [[ "${?}" -ne 0 ]]; then
        exit 1
      fi

    elif [[ "${galyleo_command}" = 'launch' ]]; then

      galyleo_launch "${@}"
      if [[ "${?}" -ne 0 ]]; then
        exit 1
      fi

    elif [[ "${galyleo_command}" = 'help' || \
            "${galyleo_command}" = '-h' || \
            "${galyleo_command}" = '--help' ]]; then 

      galyleo_output "USAGE: galyleo.sh <command> [options] {values}"
      galyleo_output ""
      galyleo_output "Finish writing help later ... ."

    else

      galyleo_error 'Command not recognized or not supported.'
      exit 1

    fi

  else

    galyleo_error 'No command-line arguments were provided.'
    exit 1

  fi

  exit 0

}

main "${@}"

# ======================================================================


