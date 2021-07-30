# galyleo

A shell utility to help you launch [Jupyter](https://jupyter.org) 
notebooks on a remote system in a secure way. 

## Download and configure galyleo with Satellite

A guide for deploying galyleo on your Slurm cluster in conjunction with
the [Satellite](https://github.com/sdsc-hpc-training-org/satellite) 
proxy service is currently under development and should be available 
sometime in the next few months.

## How to use galyleo on Expanse

First, prepend the installation location of the `galyleo.sh` launch 
script to your `PATH` environment variable.
```bash
export PATH="/cm/shared/apps/sdsc/galyleo:${PATH}"
```

Example 1: Launch a JupyterLab session on a single CPU core in the 
'shared' partition on Expanse using the default Anaconda3 distribution
provided as part of Expanse's standard software module environment.
```bash
galyleo launch --account 'abc123' --partition 'shared' --cpus 1 --memory 2 --time-limit 00:30:00 --env-modules 'cpu,gcc,anaconda3' --quiet
```

Example 2: Launch a Jupyter Notebook session on a single GPU in the 
'gpu-shared' partition on Expanse using the latest PyTorch Singularity 
container available.
```bash
galyleo launch --account 'abc123' --partition 'gpu-shared' --cpus 10 --memory 93 --gpus 1 --time-limit 00:30:00 --notebook-dir "/expanse/lustre/projects/abc123/${USER}" --env-modules 'singularitypro' --sif '/cm/shared/apps/containers/singularity/pytorch/pytorch-latest.sif' --bind '/expanse,/scratch' --nv --quiet
```

## Status

This project is currently a prototype under active development at 
[SDSC](https://www.sdsc.edu), where it is currently deployed on both 
[Comet](https://www.sdsc.edu/support/user_guides/comet.html), 
[Expanse](https://expanse.sdsc.edu), and the 
[Triton Shared Compute Cluster (TSCC)](https://www.sdsc.edu/support/user_guides/tscc.html). It has also been integrated with 
the Open OnDemand-based [Expanse User Portal](https://portal.expanse.sdsc.edu)
to help simplify the launching Jupyter notebooks on Expanse. Please see
*Interactive Apps* tab in the toolbar across the top of your browser 
after logging into the portal, then select *Jupyter*.

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

0.4.6

## Last Updated

Friday, July 30th, 2021
