FROM ubuntu:16.04
LABEL maintaner=nreith@gmail.com
# Use Bash as Default Shell instead of sh
SHELL ["/bin/bash", "-c"]
# Run as root
USER root

ENV LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8 \
LANGUAGE=en_US.UTF-8 \
DEBIAN_FRONTEND=noninteractive \
TZ=America/Chicago \
TERM=xterm-256color \
LD_LIBRARY_PATH=/opt/microsoft/mlserver/9.3.0/runtime/R/lib:$LD_LIBRARY_PATH \
PATH=/opt/microsoft/mlserver/9.3.0/runtime/python/bin/:/opt/microsoft/mlserver/9.3.0/runtime/R/bin/:$PATH

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
  apt-utils \
  bash-completion \
  ca-certificates \
  curl \
  file \
  fonts-texgyre \
  g++ \
  gfortran \
  git \
  gsfonts \
  less \
  libbz2-1.0 \
  libcurl3 \
  libgomp1 \
  libopenblas-dev \
  libpango1.0-0 \
  libpcre3 \
  libpng16-16 \
  libtiff5 \
  liblzma5 \
  libsm6 \
  libxt6 \
  locales \
  make \
  openssh-server \
  unzip \
  wget \
  zip \
  zlib1g \
&& echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
&& locale-gen en_US.utf8 \
&& /usr/sbin/update-locale LANG=en_US.UTF-8 \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
  apt-transport-https \
&& cd /tmp \
&& . /etc/os-release \
&& echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $UBUNTU_CODENAME main" | \
  tee /etc/apt/sources.list.d/azure-cli.list \
&& apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 \
&& apt-get update \
&& apt-get install -y azure-cli apt-get microsoft-r-open-foreachiterators-3.4.3 \
  microsoft-r-open-mkl-3.4.3 microsoft-r-open-mro-3.4.3 microsoft-mlserver-packages-r-9.3.0 \
  microsoft-mlserver-mml-r-9.3.0 microsoft-mlserver-mlm-r-9.3.0 \
  microsoft-mlserver-python-9.3.0 microsoft-mlserver-packages-py-9.3.0 \
  microsoft-mlserver-mml-py-9.3.0 microsoft-mlserver-mlm-py-9.3.0 \
  microsoft-mlserver-adminutil-9.3 microsoft-mlserver-computenode-9.3 \
  microsoft-mlserver-config-rserve-9.3 microsoft-mlserver-webnode-9.3 \
&& /opt/microsoft/mlserver/9.3.0/bin/R/activate.sh -a -l \
&& alias python=mlserver-python \
&& alias python3=mlserver-python \
&& alias R=Revo64 \
&& rm -rf /tmp/* \
&& apt-get autoremove -y \
&& apt-get autoclean -y \
&& rm -rf /var/lib/apt/lists/*
&& chown -R ubuntu:ubuntu /home/ubuntu \
&& chown -R ubuntu:ubuntu /opt \
&& chown -R ubuntu:ubuntu /tmp
