# galyleo

A shell utility to help you launch [Jupyter](https://jupyter.org) notebooks 
on high-performance computing systems in a simple, secure way.

- [Description](#description)
- [Quick Start Guide](#quickstart)
- [Defining your software environment](#softwareenv)
  - [Environment modules](#envmodules)
  - [Singularity containers](#singularity)
  - [Conda environments](#conda)
- [Debugging your session](#debug)
- [Additional Information](#additionalinfo)

<div id='description'/>

## Description

`galyleo` is a shell utility to help you launch Jupyter notebooks on 
high-performance computing (HPC) systems in a simple, secure way. It 
works with the [Satellite](https://github.com/sdsc-hpc-training-org/satellite)
[reverse proxy](https://en.wikipedia.org/wiki/Reverse_proxy) service
and a batch job scheduler like [Slurm](https://slurm.schedmd.com) to
provide each Jupyter notebook server you start with its own one-time,
token-authenticated [HTTPS](https://en.wikipedia.org/wiki/HTTPS)
connection between the compute resources of the HPC system the notebook
server is running on and your web browser. This HTTPS-secured connection
affords both privacy and integrity to the data exchanged between the 
notebook server and your browser, helping protect you and your work 
against network eavesdropping and data tampering. 

<div id='quickstart'/>

## Quick Start Guide

`galyleo` is currently deployed on the following HPC systems at SDSC:
- [Comet](https://www.sdsc.edu/support/user_guides/comet.html)
- [Expanse](https://expanse.sdsc.edu)
- [Triton Shared Compute Cluster (TSCC)](
  https://www.sdsc.edu/support/user_guides/tscc.html)

To begin using `galyleo`, you first need to prepend its installation 
location to your `PATH` environment variable. This location is different
for each HPC system at SDSC. 

On Comet, use:
```bash
export PATH="/share/apps/compute/galyleo:${PATH}"
```
On Expanse, use:
```bash
export PATH="/cm/shared/apps/sdsc/galyleo:${PATH}"
```
On TSCC, use:
```bash
export PATH="/projects/builder-group/galyleo:${PATH}"
```

Once `galyleo` is in your `PATH`, you can then use its `launch` command
to create a secure Jupyter notebook session. A number of command-line 
options will allow you to configure:
- the compute resources required to run your Jupyter notebook session;
- the type of Jupyter interface you want to use for the session and the
location of the notebook working directory; and
- the software environment that contains the `jupyter` notebook server 
and the other software packages you want to work with during the session.

For example, the following `galyleo` command will `launch` a 30-minute 
JupyterLab session on a single CPU core with 2 GB of memory on one of 
Expanse's `shared` AMD compute nodes using the base `anaconda3` 
distribution available in its software module environment.
```bash
galyleo launch --account abc123 --partition shared --cpus 1 --memory 2 --time-limit 00:30:00 --env-modules cpu,gcc,anaconda3
```
When the `launch` command completes successfully, you will be issued a 
unique HTTPS URL generated for your secure Jupyter notebook session. 
```bash
https://wages-astonish-recapture.expanse-user-content.sdsc.edu?token=1abe04ac1703ca623e4e907cc37678ae
```
Copy and paste this HTTPS URL into your web browser. Do not share it 
with others. It is effectively the password to your Jupyter notebook
session, which will begin once the requested compute resources are 
allocated to your job by the scheduler.

The complete list of command-line options for the `launch` command are 
described below. Those shown in **bold** are the ones most commonly used. 

Scheduler options:
- **`-A, --account`: charge the compute resources required by this job 
  to the specified account or allocation project id**
- `-R, --reservation`: allow the job to access a set of reserved compute
  resources assigned to the specified reservation name
- **`-p, --partition`: select the compute resource partition or queue 
  the job should be submitted to; default value is set in the system-wide
  galyleo.conf file configured by your system administrator**
- `-q, --qos`: apply a quality of service to the job
- `-N, --nodes`: number of compute nodes required for the job; default
  value is 1
- `-n, --ntasks-per-node`: number of tasks per node required for the
  job; default value is 1
- **`-c, --cpus`: number of cpus (per task) to request for the job;
  default value is 1**
- **`-m, --memory`: amount of memory (in GB) required for the job; 
  default value is set by the scheduler configuration**
- `-g, --gpus`: number of GPUs required for the job; default value is 0
- `--gres`: specify a generic consumable resource (Slurm)
- **`-t, --time-limit`: set a maximum runtime (in HH:MM:SS) for the job;
  default value is 00:30:00**
- `-C, --constraint`: apply a feature constraint to specify the type of 
  compute node required for the job

Jupyter options:
- `-j, --jupyter`: select the user interface for the Jupyter notebook 
  session; default value is *lab*; the other option is *notebook*
- `-d, --notebook-dir`: path to the working directory where the Jupyter 
  notebook session will start; default value is your `$HOME` directory

Software environment options:
- **`-e, --env-modules`: comma-separated list of environment modules
  that will be loaded to create the software environment for the Jupyter
  notebook session**
- **`-s, --sif`: path to a Singularity container image file that will be
  run to create the software environment for the Jupyter notebook session**
- `-B, --bind`: comma-separated list of user-defined bind paths to be
  mounted within a Singularity container
- `--nv`: enable NVIDIA GPU support when running a Singularity container
- `--rocm`: enable AMD GPU support when running a Singularity container; 
  *not tested yet*
- **`--conda-env`: name of a conda environment to activate to create the 
  software environment for the Jupyter notebook session**
- `--conda-init`: path to the conda.sh initialization script of a
  conda distribution
- `--conda-pack`: path to the tarball of a `conda-pack`aged environment
- `--conda-yml`: path to an `environment.yml` file
- `--mamba`: use mamba instead of miniconda to create your conda
  environment from an `environment.yml` file.
- `--scratch-dir`: path to a node-local scratch directory

Other options:
- `-Q, --quiet`: suppresses all standard output except for the HTTPS URL 
  or error messages that are thrown

<div id='softwareenv'/>

## Defining your software environment

After you specify the compute resources required for your Jupyter 
notebook session using the *Scheduler options* outlined above, the 
next most important set of command-line options for the `launch` command
are those that help you define the software environment. Listed in the 
*Software environment options* section above, these command-line options
are discussed in detail in the next few subsections below. Please note,
however, no matter how you define the software environment for your 
Jupyter notebook session, **`galyleo` always assumes that `jupyter` has
been pre-installed within that software environment**. If  `jupyter` has
not been installed, then the `launch` command will fail and throw a 
runtime error.

<div id='envmodules'/>

### Environment modules

Most modern HPC systems use a software module system like 
[Lmod](https://lmod.readthedocs.io) or 
[Environment Modules](http://modules.sourceforge.net) to provide you
with a convenient way to dynamically load pre-installed software 
packages into your shell environment. 

If you need to `module load` any software packages into the environment
for your Jupyter notebook session, you can do so by including them as a
comma-separated list to the `--env-modules` option in your `launch` 
command. Each software module included in the list will be loaded prior
to starting your `jupyter` notebook server. 

In some cases, the `--env-modules` command-line option may be the only 
one you need to define your software environment. For example, if you 
are using Python for data science on Expanse, then you might only need
to load one of the [Anaconda](https://www.anaconda.com) distributions
available in its software module environment.
```bash
galyleo launch --account abc123 --partition shared --cpus 1 --memory 2 --time-limit 00:30:00 --env-modules cpu,gcc,anaconda3
```
By default, each Anaconda distribution comes with over 250 of the most 
popular data science software packages pre-installed, including `jupyter`.

On Comet and TSCC, which share a common software environment, you can 
find a pre-installed version of `jupyter` in their `scipy/3.6` module. 
```bash
galyleo launch --account abc123 --cpus 4 --time-limit 00:30:00 --env-modules python,scipy/3.6 --jupyter notebook
```
Note, however, only the older `--jupyter notebook` interface is available.

<div id='singularity'/>

### Singularity containers

[Singularity](https://sylabs.io/guides/latest/user-guide) containers
bring [operating system-level virtualization](
https://en.wikipedia.org/wiki/OS-level_virtualization) to scientific and 
high-performance computing, allowing you to package complete software 
environments --- including operating systems, software applications, 
libraries, and data --- in a simple, portable, and reproducible way, 
which can then be executed and run almost anywhere.

If you have a Singularity container that you would like to run for your
Jupyter notebook session, you can provide a path to the container by 
including the `--sif` option in your `launch` command. This will start 
the `jupyter` notebook server within the container using the 
[`singularity exec`](
https://sylabs.io/guides/3.8/user-guide/cli/singularity_exec.html) 
command. If necessary, you can also pass [user-defined `--bind` mounts](
https://sylabs.io/guides/3.8/user-guide/bind_paths_and_mounts.html)
to the container and [enable NVIDIA GPU support](
https://sylabs.io/guides/3.8/user-guide/gpu.html)
via the `--nv` flag.

One of the most powerful features of Singularity is its ability to 
[convert an existing Docker container to a Singularity container](
https://sylabs.io/guides/3.8/user-guide/singularity_and_docker.html). 
So, even if you are not familiar with how to build your own Singularity
container from scratch, you can always consider searching the
public container registries like [Docker Hub](https://hub.docker.com) 
for an existing Docker container that may help you get your work done.

For example, let's say you need an [R](https://www.r-project.org) 
environment for your Jupyter notebook session. Why not try the latest 
[r-notebook container](https://hub.docker.com/r/jupyter/r-notebook) 
from the [Jupyter (Docker Stacks) Project](
https://jupyter-docker-stacks.readthedocs.io)? 
To do so, you would first use the [`singularity pull`](
https://sylabs.io/guides/3.8/user-guide/cli/singularity_pull.html)
command to download and convert the Docker container to a Singularity 
container.
```bash
singularity pull docker://jupyter/r-notebook:latest
```
Once all of the layers of the Docker container have been downloaded and
the container conversion process is complete, you can then `launch` your
Jupyter notebook session with the newly built Singularity container.
```bash
galyleo launch --account abc123 --cpus 4 --time-limit 00:30:00 --sif r-notebook_latest.sif
```
On some HPC systems, like Expanse, you may first need to load 
Singularity via the module environment.
```bash
galyleo launch --account abc123 --cpus 4 --time-limit 00:30:00 --env-modules singularitypro --sif r-notebook_latest.sif --bind /expanse,/scratch
```
In this example, note the use of the user-defined `--bind` mount option
that allows you to enable access to [your other storage options on
Expanse](https://www.sdsc.edu/support/user_guides/expanse.html#storage) 
from within the container. By default, only your `HOME` directory is 
accessible from within the container.

Singularity also provides native support for running containerized 
applications on NVIDIA GPUs. If you have a GPU-accelerated application
you would like to run during your Jupyter notebook session, please make
sure your container includes a CUDA-enabled version of the application 
that can utilize NVIDIA GPUs. 

NVIDIA itself distributes a number of [GPU-optimized containers](
https://developer.nvidia.com/ai-hpc-containers) 
via their NVIDIA Container Registry. This includes containers for all of 
the popular deep learning frameworks --- [PyTorch](https://pytorch.org), 
[TensorFlow](https://www.tensorflow.org), and 
[MXNet](https://mxnet.apache.org) --- with `jupyter` pre-installed. Like 
the the containers available from DockerHub, you can `pull` these 
containers to the HPC system you are working on
```bash
singularity pull docker://nvcr.io/nvidia/pytorch:21.07-py3
```
and then `launch` your Jupyter notebook session with `galyleo`. For 
example, you might want to run this PyTorch container on a single NVIDIA 
V100 GPU available in Expanse's `gpu-shared` partition.
```bash
galyleo launch --account abc123 --partition gpu-shared --cpus 10 --memory 93 --gpus 1 --time-limit 00:30:00 --env-modules singularitypro --sif pytorch_21.07-py3.sif --bind /expanse,/scratch --nv 
```

Note, however, how you request GPU resources with `galyleo` may be 
different from one HPC system to another. For example, [you must use the
`--gres` command-line option on Comet](
https://www.sdsc.edu/support/user_guides/comet.html#gpu) to specify both 
the type and number of GPUs required for your Jupyter notebook session.
The following `galyleo` command would `launch` your session within the 
NVIDIA PyTorch container on a single P100 GPU available in Comet's 
`gpu-shared` partition.
```bash
galyleo launch --account abc123 --partition gpu-shared --cpus 7 --gres gpu:p100:1 --time-limit 00:30:00 --sif pytorch_21.07-py3.sif --bind /oasis,/scratch --nv
```
In contrast, on TSCC, you'll never explicitly request a specific number
of GPUs for your Jupyter notebook session. [All GPUs on TSCC are 
allocated implicitly](
https://www.sdsc.edu/support/user_guides/tscc.html#gpu-queue)
in proportion to the number of CPU-cores requested by a job and 
available on the type of GPU-accelerated compute node you expect it to 
run on. For example, most of the GPU nodes available in the `gpu-hotel`
queue are dual Intel Xeon E5-2630v2 processor systems with 12 CPU-cores 
and 4 NVIDIA GeForce GTX 680 GPUs. Therefore, if you want to `launch` 
your Jupyter notebook session on a single GeForce 680 GPU, then you'd 
request only `--cpus 3`.
```bash
galyleo launch --account abc123 --partition gpu-hotel --cpus 3 --time-limit 00:30:00 --sif /projects/builder-group/singularity/pytorch/pytorch-v1.4.0-gpu-20200224.simg --bind '"/oasis,${TMPDIR}"' --nv
```
Note, however, there is no guarantee that the above command will 
actually schedule your session on one of the GTX 680 GPU nodes. The 
`gpu-hotel` queue also has one dual Intel Xeon Silver 4110 processor
node with 16 CPU-cores and 8 NVIDIA GeForce RTX 2080Ti GPUs. So, if you
would like to explicitly request your notebook session be scheduled on 
a certain type of GPU, then you should also pass the type of GPU 
required (listed in the `pbsnodes` properties) via the `--constraint` 
command-line option.
```bash
galyleo launch --account abc123 --partition gpu-hotel --cpus 2 --constraint gpu2080ti --time-limit 00:30:00 --sif pytorch_21.07-py3.sif --bind '"/oasis,${TMPDIR}"' --nv
```

Whatever you do, whenever you're launching your Jupyter notebook session 
with `galyleo` from a Singularity container on compute resources with 
NVIDIA GPUs, **please don't forget the `--nv` flag!**

<div id='conda'/>

### Conda environments

[Conda](https://docs.conda.io) is an open-source software package and 
environment manager developed by [Anaconda Inc.](https://www.anaconda.com). 
Its ease of use, compatibility across multiple operating systems, and 
comprehensive support for both the Python and R software ecosystems has
made it one of the most popular ways to build and maintain custom 
software environments in the data science and machine learning 
communities. And because of the constantly evolving software landscape 
in these spaces, which can involve quite complex software dependencies,
conda is often the simplest way to get your custom Python or R software
environment up and running on an HPC system.

`galyleo` supports the use of conda environments to configure the 
software environment for your Jupyter notebook session. If you've 
already installed a conda distribution --- we recommend [Miniconda](
https://docs.conda.io/en/latest/miniconda.html) --- 
and configured a custom conda environment within it, then you should 
only need to specify the name of the conda environment you want to 
activate for your notebook session with the `--conda-env` command-line 
option. For example, let's imagine you've already created a custom 
conda environment from the following [`environment.yml`](
https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#creating-an-environment-from-an-environment-yml-file)
file.
```yaml
name: notebooks-sharing

channels:
  - conda-forge
  - anaconda

dependencies:
  - conda-pack=0.6.0
  - python=3.7
  - jupyterlab=3
  - pandas=1.2.4
  - matplotlib=3.4.2
  - joblib=1.0.1
  - seaborn=0.11.0
  - ipywidgets=7.6.2
  - scikit-learn=0.23.2
``` 
You should then be able to `launch` a 30-minute JupyterLab session on a
single CPU core with 2 GB of memory on one of Expanse's `shared` AMD 
compute nodes by simply activating the `notebooks-sharing` environment.
```bash
galyleo launch --account abc123 --partition shared --cpus 1 --memory 2 --time-limit 00:30:00 --conda-env notebooks-sharing
```
Note, however, the use of the `--conda-env` command-line option here
assumes you've already configured your `~/.bashrc` file with the `conda
init` command. If you have not done so (or choose not to do so), then
you can also initialize any conda distribution in your `launch` command 
by providing the path to its `conda.sh` initialization script in the 
`etc/profile.d` directory via the `--conda-init` command-line option.
```bash
galyleo launch --account abc123 --partition shared --cpus 1 --memory 2 --time-limit 00:30:00 --conda-env notebooks-sharing --conda-init miniconda3/etc/profile.d/conda.sh
```

While creating your own custom software environment with conda may be 
convenient, it can also generate a high metadata load on the types of 
shared network filesystems you'll often find on an HPC system. At a 
minimum, if you install your conda distribution on a network filesystem, 
you can expect this to increase the installation time of software 
packages into your conda environment when compared to a local filesystem 
installation you may have done previously on your laptop. Under some
circumstances, this metadata issue can lead to a serious degradation of
the aggregate I/O performance across a filesystem, affecting the 
performance of all user jobs on the system. So, please follow best
practices when using conda on an HPC system. For example, one such best
practice is to disable the default auto-loading of your `base` conda 
environment on login.
```bash
conda config --set auto_activate_base false
```

If you have not yet installed your conda environment on a shared 
filesystem (such as in your `$HOME` directory), `galyleo` now also 
allows you to dynamically create the environment at runtime from an 
`environment.yml` file before your Jupyter session starts, but only if 
the system you are working on has fast, node-local storage available, 
like 
[Expanse's local NVMe `/scratch` disk](
https://www.sdsc.edu/support/user_guides/expanse.html#storage)
or
[TSCC's local scratch `$TMPDIR`](
https://www.sdsc.edu/support/user_guides/tscc.html#running). To use 
this feature, you simply need to provide the absolute path to the 
`environment.yml` file with the `--conda-yml` command-line option. For 
example, if you wanted to start an Juoyter notebook session with the 
`notebooks-sharing` environment, you would use the following command:
```bash
galyleo launch --account abc123 --partition shared --cpus 1 --memory 2 --time-limit 00:30:00 --conda-env notebooks-sharing --conda-yml "${HOME}/path/to/environment.yml"
```
   
Another way to avoid the metadata performance issues when working with 
conda on an HPC systems is to use 
[conda-pack](https://conda.github.io/conda-pack). 
This command-line tool allows you to create self-contained, relocatable
conda environments packaged as [tarballs](
https://en.wikipedia.org/wiki/Tar_(computing)). These `conda-pack`aged 
environments can then be copied to the node-local scratch storage, 
unpacked there, and then activated without any of the performance 
issues associated with using conda on a shared network filesystem.

`galyleo` supports the use of these `conda-pack`aged environments. 
To demonstrate this capability, let's create a packaged version of the 
`notebooks-sharing` environment from above on Expanse. First, create an
interactive session on one of Expanse's `debug` nodes.
```bash
srun --account=abc123 --partition=debug --nodes=1 --ntasks-per-node=2 --cpus-per-task=1 --mem=4G --time=00:30:00 --pty --wait=0 /bin/bash
```
Once the interactive session has been allocated compute resources,
download the latest miniconda installer to your `$HOME` directory
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```
and change its permissions such that it is executable.
```bash
chmod +x Miniconda3-latest-Linux-x86_64.sh
```
Next, set the following environment variables to use the node-local 
scratch directory
```bash
export CONDA_INSTALL_PATH="/scratch/${USER}/job_${SLURM_JOB_ID}/miniconda3"
```
```bash
export CONDA_ENVS_PATH="${CONDA_INSTALL_PATH}/envs"
```
```bash
export CONDA_PKGS_DIRS="${CONDA_INSTALL_PATH}/pkgs"
```
and then run the conda installer in batch mode, redirecting its 
installation prefix to the node-local scratch directory using these 
environment variables.
```bash
./Miniconda3-latest-Linux-x86_64.sh -b -p "${CONDA_INSTALL_PATH}"
```
When the installation is complete, you can then initialize the 
distribution
```bash
source "${CONDA_INSTALL_PATH}/etc/profile.d/conda.sh"
```
and activate its `base` conda environment.
```bash
conda activate base
```
You can now create the `notebooks-sharing` environment from
the `environment.yml` file,
```bash
conda env create --file environment.yml
```
which includes `conda-pack`. Once the environment has been created, 
you simply need to activate it,
```bash
conda activate notebooks-sharing
```
pack it,
```bash
conda pack -n notebooks-sharing -o notebooks-sharing.tar.gz
```
and copy the generated tarball back to your `$HOME` directory. You can 
now close your interactive session.

To `launch` your Jupyter notebook session with a `conda-pack`aged 
environment, you must provide a absolute path to the tarball via 
the `--conda-pack` command-line option.
```bash
galyleo launch --account abc123 --partition shared --cpus 1 --memory 2 --time-limit 00:30:00 --conda-env notebooks-sharing --conda-pack "${HOME}/path/to/notebooks-sharing.tar.gz"
```

<div id='debug'/>

## Debugging your session

If you experience a problem launching your Jupyter notebook session with 
`galyleo`, you may be able to debug the issue yourself by reviewing the
batch job script generated by `galyleo` or the standard output/error
file generated by the job itself. You can find these files stored in the 
hidden `~/.galyleo` directory created in your `HOME` directory.

<div id='additionalinfo'/>

## Additional Information

### Expanse User Portal

`galyleo` has been integrated with the Open OnDemand-based [Expanse User
Portal](https://portal.expanse.sdsc.edu) to help simplify launching 
Jupyter notebooks on Expanse. After logging into the portal, you can 
access this web-based interface to `galyleo` from the *Interactive Apps*
tab in the toolbar across the top of your browser, then select *Jupyter*. 

### naked-singularity containers

SDSC builds and maintains a number of [custom Singularity containers for
use on its HPC systems](https://github.com/mkandes/naked-singularity). 
Pre-built copies of many of these containers are made available from a
central storage location on each HPC system. Please check the following
locations for the latest containers. If you do not find the container 
you're looking for, please feel free to contact us and make a request
for a container to be made available.

On Comet:
- `/share/apps/compute/singularity/images`
- `/share/apps/gpu/singularity/images`

On Expanse:
- `/cm/shared/apps/containers/singularity`

On TSCC:
- `/projects/builder-group/singularity`

## Status

A work in progress.

## Contribute

If you would like to contribute to the project, then please submit a 
pull request via GitHub. If you have a feature request or a problem to 
report, then please create a GitHub issue.

## Author

Marty Kandes, Ph.D.  
Computational & Data Science Research Specialist  
High-Performance Computing User Services Group  
San Diego Supercomputer Center  
University of California, San Diego  

## Version

0.5.9

## Last Updated

Wednesday, November 23rd, 2022
