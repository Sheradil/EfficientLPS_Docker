# EfficientLPS Docker

This repository contains a Dockerfile for the Efficient LPS network:

- Paper: https://arxiv.org/pdf/2102.08009.pdf
- Github: https://github.com/robot-learning-freiburg/EfficientLPS/.

Important notes:
- Training works, but the validation currently fails. This will be fixed in a future update.

Side notes:
- This Dockerfile was tested on a Nvidia DGX
- This is meant for people that can't get the official repository to work
- This is meant as a working base. It will not work on every system without some modifications
- System requirements: Host system should have at least the Nvidia driver version 450.203.03, CUDA 11

Usage:
- The last line in the dockerfile is commented out to enable the usage of the interactive mode. Training has to be started manually then (copy the command from the entrypoint.sh file).
- Data has to be stored in "/raid/data/...". Otherwise some smaller changes are necessary.
- sudo docker build -t NAME .
- sudo docker run -v /raid/data:/raid/data -it --gpus all NAME:latest
