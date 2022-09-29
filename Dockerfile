# Dockerfile for Deep Learning on PointClouds with PyTorch
FROM nvidia/cuda:11.7.0-devel-ubuntu18.04

# Install base utilities
RUN apt-get update && \
    apt-get install -y wget && \
    apt-get install -y git && \
    apt-get install -y nano && \
    apt-get install -y ffmpeg && \
    apt-get install -y libsm6 && \
    apt-get install -y libxext6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------- Install Miniconda -------------------------
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Put conda in path so we can use conda activate
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py37_4.10.3-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

RUN pip install absl-py==0.11.0 addict==2.4.0 appdirs==1.4.4 attrs==20.3.0 cachetools==4.2.0 chardet==4.0.0 cityscapesscripts==2.2.0 coloredlogs==15.0 cycler==0.10.0 decorator==4.4.2 future==0.18.2 google-auth==1.24.0 google-auth-oauthlib==0.4.2 grpcio==1.34.0 humanfriendly==9.1 idna==2.10 imageio==2.9.0 importlib-metadata==3.4.0 iniconfig==1.1.1 kiwisolver==1.3.1 markdown==3.3.3 matplotlib==3.3.3 networkx==2.5 numpy==1.19.5 oauthlib==3.1.0 opencv-python==4.5.1.48 packaging==20.8 pandas==1.2.0 pillow==6.2.2 pluggy==0.13.1 protobuf==3.14.0 py==1.10.0 pyasn1==0.4.8 pyasn1-modules==0.2.8 pyparsing==2.4.7 pyquaternion==0.9.9 pytest==6.2.1 python-dateutil==2.8.1 pytz==2020.5 pywavelets==1.1.1 pyyaml==5.3.1 requests==2.25.1 requests-oauthlib==1.3.0 rsa==4.7 scikit-image==0.18.1 scipy==1.6.0 seaborn==0.11.1 six==1.15.0 terminaltables==3.1.0 tifffile==2021.1.14 toml==0.10.2 tqdm==4.56.0 typing==3.7.4.3 typing-extensions==3.7.4.3 urllib3==1.26.2 werkzeug==1.0.1 xdoctest==0.15.0 yapf==0.30.0 zipp==3.4.0 mmcv==0.5.9
#tensorboard==2.4.0 tensorboard-plugin-wit==1.7.0 torch==1.7.1 torchvision==0.8.2

# Create environment and use it in new shell sessions
#RUN conda create --name effenv 
#RUN echo "conda activate effenv" >> ~/.bashrc
SHELL [ "/bin/bash", "--login", "-c" ]

# Install pytorch and related packages
RUN conda install pytorch==1.7.1 torchvision==0.8.2 torchaudio==0.7.2 cudatoolkit=10.2 -c pytorch

# Install ninja (used to build custom c++ code for the GPU and PyTorch)
RUN conda install -c conda-forge ninja
RUN conda install pip
RUN pip install ninja
RUN pip install pycocotools

# Set the environment variable for cuda. This is needed for 
# some custom c++ code from efficient lps net
ENV CUDA_HOME "/usr/local/cuda/"
ENV TORCH_CUDA_ARCH_LIST="Volta"
ENV IABN_FORCE_CUDA=1
ENV FORCE_CUDA=1

# Clone and install the efficientLPS network
WORKDIR /app
RUN git clone https://github.com/robot-learning-freiburg/EfficientLPS.git
WORKDIR /app/EfficientLPS
# With the current environment.yml the installation will fail therefor we will install the packages that cause problems manually

RUN pip install inplace-abn
RUN pip install git+https://github.com/waspinator/pycococreator.git@0.2.0
# Now install the remaining packages
RUN conda env update --file environment.yml --prune

WORKDIR /app/EfficientLPS/efficientNet
RUN python setup.py develop

WORKDIR /app/EfficientLPS
RUN python setup.py develop

RUN pip install --upgrade numpy

WORKDIR /app/EfficientLPS/configs
RUN sed -i "s|path_to_dataset_folder|/raid/data/kitti/dataset/|g" efficientLPS_multigpu_sample.py
WORKDIR /app/EfficientLPS/efficientNet/geffnet
RUN sed -i "s|from torch._six import container_abcs|from collections import abc as container_abcs|g" conv2d_layers.py

RUN pip install future tensorboard

WORKDIR /app/EfficientLPS
COPY entrypoint.sh ./
RUN chmod +777 ./entrypoint.sh

# Comment out if you want to use the interactive mode
#ENTRYPOINT [ "./entrypoint.sh" ]
