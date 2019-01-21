FROM ubuntu:16.04
LABEL maintaner=nreith@gmail.com
# Use Bash as Default Shell instead of sh
SHELL ["/bin/bash", "-c"]
# Run as root
USER root

# Other Environment variables
ENV LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8 \
LANGUAGE=en_US.UTF-8 \
DEBIAN_FRONTEND=noninteractive \
TZ=America/Chicago \
TERM=xterm-256color \
LD_LIBRARY_PATH=/opt/microsoft/mlserver/9.3.0/runtime/R/lib:$LD_LIBRARY_PATH \
PATH=/opt/microsoft/mlserver/9.3.0/runtime/python/bin:/opt/microsoft/mlserver/9.3.0/runtime/R/bin:$PATH \
PYTHONIOENCODING=utf-8 \
LANG=en_US.UTF-8 \
JOBLIB_TEMP_FOLDER=/tmp \
LC_ALL=en_US.UTF-8

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
&& cd /tmp \
&& . /etc/os-release \
&& apt-get install -y --no-install-recommends apt-transport-https wget \
&& echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ xenial main" | tee /etc/apt/sources.list.d/azure-cli.list \
&& wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O /tmp/prod.deb \
&& dpkg -i /tmp/prod.deb \
&& rm -f /tmp/prod.deb \
#&& apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 \
&& apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 \
&& apt-get -y update \
&& apt-get install -y microsoft-r-open-foreachiterators-3.4.3 \
&& apt-get install -y microsoft-r-open-mkl-3.4.3 \
&& apt-get install -y microsoft-r-open-mro-3.4.3 \
&& apt-get install -y microsoft-mlserver-packages-r-9.3.0 \
&& apt-get install -y microsoft-mlserver-python-9.3.0 \
&& apt-get install -y microsoft-mlserver-packages-py-9.3.0 \
&& apt-get install -y microsoft-mlserver-mml-r-9.3.0 \
&& apt-get install -y microsoft-mlserver-mml-py-9.3.0 \
&& apt-get install -y microsoft-mlserver-mlm-r-9.3.0 \
&& apt-get install -y microsoft-mlserver-mlm-py-9.3.0 \
&& apt-get install -y azure-cli=2.0.26-1~xenial \
&& apt-get install -y dotnet-runtime-2.0.0 \
&& apt-get install -y microsoft-mlserver-adminutil-9.3.0 \
&& apt-get install -y microsoft-mlserver-config-rserve-9.3.0 \
&& apt-get install -y microsoft-mlserver-computenode-9.3.0 \
&& apt-get install -y microsoft-mlserver-webnode-9.3.0 \
&& /opt/microsoft/mlserver/9.3.0/bin/R/activate.sh \
&& alias python=mlserver-python \
&& alias python3=mlserver-python \
&& alias R=Revo64 \
# Layer Cleanup
&& rm -rf /tmp/* \
&& apt-get autoremove -y \
&& apt-get autoclean -y \
&& rm -rf /var/lib/apt/lists/*

####################################################################################
# Domino-Specific Config
####################################################################################
RUN \
#
# Add User needed by Domino
    groupadd -g 12574 ubuntu && \
    useradd -u 12574 -g 12574 -m -N -s /bin/bash ubuntu && \
# A bunch of Dell-specific, necessary stuff for network, etc.
    # Fix annoying "writing more than expected" error with apt/apt-get when using corporate proxy
    rm -rf /var/lib/apt/lists/* && \
    echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99fixbadproxy && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99fixbadproxy && \
    echo "Acquire::BrokenProxy true;" >> /etc/apt/apt.conf.d/99fixbadproxy && \
    apt-get update -o Acquire::CompressionTypes::Order::=gz && \
    echo "Acquire::http::proxy \"$http_proxy\";" > /etc/apt/apt.conf && \
    echo "Acquire::https::proxy \"$https_proxy\";" >> /etc/apt/apt.conf && \
    echo "Acquire::ftp::proxy \"$http_proxy\";" >> /etc/apt/apt.conf && \
    apt-get clean && apt-get update && \
  # chown user permissions for some folders
    chown -R ubuntu:ubuntu /home/ubuntu/ && \
    chown -R ubuntu:ubuntu /opt && \
    chown -R ubuntu:ubuntu /tmp && \
#
# Domino SSH and Workspaces Stuff
#
# ADD SSH start script
    mkdir -p /scripts && \
    echo '#!/bin/bash'> /scripts/start-ssh && \
    echo 'service ssh start' >> /scripts/start-ssh && \
    chmod +x /scripts/start-ssh && \
    source /home/ubuntu/.bashrc && \
    echo 'source /home/ubuntu/.bashrc' >> /home/ubuntu/.domino-defaults && \
# Installing Notebooks,Workspaces,IDEs,etc
  # Clone in workspaces install scripts
    mkdir -p /var/opt/workspaces && \
    cd /tmp && wget https://github.com/dominodatalab/workspace-configs/archive/2019q1-v1.1.zip && unzip 2019q1-v1.1.zip && \
    cp -Rf workspace-configs*/* /var/opt/workspaces && \
    rm -rf /tmp/workspace-configs* && \
  #
  # Install Jupyterlab from workspaces
    # chmod +x /var/opt/workspaces/Jupyterlab/install && \
    # /var/opt/workspaces/Jupyterlab/install && \
  #
  # Install Zeppelin from workspaces
    # chmod +x /var/opt/workspaces/Zeppelin/install && \
    # /var/opt/workspaces/Zeppelin/install && \
  #
  # Install h20 from workspaces
    # chmod +x /var/opt/workspaces/h2o/install && \
    # /var/opt/workspaces/h2o/install && \
  #
  # Install Jupyter-Tensorboard from workspaces
    # chmod +x /var/opt/workspaces/jupyter-tensorboard/install && \
    # /var/opt/workspaces/jupyter-tensorboard/install && \
  #
  # Install Jupyter Notebooks from workspaces
    chmod +x /var/opt/workspaces/jupyter/install && \
    /var/opt/workspaces/jupyter/install && \
  #
  # Install PySpark Notebooks from workspaces
    # chmod +x /var/opt/workspaces/pyspark/install && \
    # /var/opt/workspaces/pyspark/install && \
  #
  # Install Rstudio from workspaces
    # Little fix so previous existing folder doesn't cause issue with mkdir
    sed -i 's/mkdir /mkdir -p /g' /var/opt/workspaces/rstudio/install && \
    chmod +x /var/opt/workspaces/rstudio/install && \
    /var/opt/workspaces/rstudio/install && \
  #
  # Add update .Rprofile with Domino customizations
    mv /var/opt/workspaces/rstudio/.Rprofile /home/ubuntu/.Rprofile && \
    chown ubuntu:ubuntu /home/ubuntu/.Rprofile && \
  #
  # Install superset from workspaces
    # chmod +x /var/opt/workspaces/superset/install && \
    # /var/opt/workspaces/superset/install && \
#
# Layer Cleanup
rm -rf /tmp/* && \
apt-get autoremove -y && \
apt-get autoclean -y && \
rm -rf /var/lib/apt/lists/*

####################################################################################
# Additional Requested Packages
####################################################################################
RUN \
  alias ipython=/opt/microsoft/mlserver/9.3.0/runtime/python/bin/ipython && \
#
  # USER REQUESTED PACKAGES
    apt-get update && \
    apt-get install -y \
        net-tools && \
  # Python Packages
    pip install \
        flashtext \
        pyodbc \
        spacy && \
#
# Layer Cleanup
rm -rf /tmp/* && \
apt-get autoremove -y && \
apt-get autoclean -y && \
rm -rf /var/lib/apt/lists/*

USER ubuntu
CMD /bin/bash
