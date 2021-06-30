# galyleo

A shell utility to help you launch [Jupyter](https://jupyter.org) 
notebooks on a remote system in a secure way. 

## Download and configure galyleo with Satellite

A guide for deploying galyleo on your Slurm cluster in conjunction with
the [Satellite](https://github.com/sdsc-hpc-training-org/satellite) 
proxy service is currently under development and should be available 
sometime in the next few months.

## How to use galyleo on Expanse

Example 1: Launch a Jupyter Notebook session on a single CPU core in the 
'shared' partition on Expanse using the 'base' Anaconda3 software 
environment provided as part of Expanse's standard software modules.
```bash
export PATH="/cm/shared/apps/sdsc/galyleo:${PATH}"
galyleo.sh launch --account 'abc123' --partition 'shared' --cpus-per-task 1 --memory-per-node 1 --time-limit 00:30:00 --jupyter 'notebook' --notebook-dir "/expanse/lustre/projects/abc123/${USER}" --env-modules 'cpu,gcc,anaconda3' --conda-env 'base' --quiet
```

Example 2: Launch a JupyterLab session on a single GPU in the 
'gpu-shared' partition on Expanse using the latest PyTorch Singularity 
container available.
```bash
export PATH="/cm/shared/apps/sdsc/galyleo:${PATH}"
galyleo.sh launch --account 'abc123' --partition 'gpu-shared' --cpus-per-task 10 --memory-per-node 93 --gpus 1 --time-limit 00:30:00 --jupyter 'lab' --notebook-dir "/expanse/lustre/projects/abc123/${USER}" --env-modules 'singularitypro' --sif '/cm/shared/apps/containers/singularity/pytorch/pytorch-gpu.sif' --bind '/expanse,/scratch' --nv --quiet
```

## Status

This project is currently a prototype under active development at 
[SDSC](https://www.sdsc.edu), where it is currently deployed on both 
[Comet](https://www.sdsc.edu/support/user_guides/comet.html) and 
[Expanse](https://expanse.sdsc.edu). It has been integrated with the 
Open OnDemand-based [Expanse Portal](https://portal.expanse.sdsc.edu)
to simplify launching Jupyter notebooks on Expanse.

## Contribute

If you would like to contribute custom changes to the project, then 
please submit a pull request. If you have a feature request or want to 
report a problem, then please create an issue.

## Author

Marty Kandes, Ph.D.  
Computational & Data Science Research Specialist  
High-Performance Computing User Services Group  
San Diego Supercomputer Center  
University of California, San Diego  

## Version

0.2.7

## Last Updated

Wednesday, June 30th, 2021
