# Notes: galyleo.py

- Create conda, pip, and spack-based packaging and installation options
- Create default system configuration files for ACCESS-CI resources
- Use sqlite3db for database operations
- Containerize software environments by default
- Prefer container-only or containerized conda environment.yaml
- Specify containers by URI only, including local ones (e.g., file://)
- Use singularity instances 
- Support HTCondor, OpenStack, K8s, and Slurm scheduled resources
- Support SSH tunnels, including at least one jump host 
- Support self-hosted reverse proxy and certificate service
- Provide integrated SSH keypair generation and management for end users
- Only use static shell scripts; do not dynamically generate execution code
- Minimize all commands executed outside of container;
- Move conda-pack environment tarballs to ~/.conda directory
- What should be configured in a user's ~/.condarc?
- Use reverse proxy status page to communicate with users (docs, tips, surveys)
- Use persistent overlays with Singularity containers (by default?)
