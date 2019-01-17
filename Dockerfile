#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
# phusion/baseimage - ML-SERVER: Py3.x, R3.x.x, and Julia 1.x.x
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#

FROM phusion/baseimage

LABEL maintainer="Nick Reith <nreith@gmail.com>"

# Use Bash as Default Shell instead of sh
SHELL ["/bin/bash", "-c"]

# Run as root
USER root

####################################################################################
# UBUNTU INSTALLS + CONFIGS
####################################################################################
#
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=America/Chicago
#
RUN \
  # Create User account
    groupadd -g 12574 ubuntu && \
    useradd -u 12574 -g 12574 -m -N -s /bin/bash ubuntu && \
  # Fix annoying "writing more than expected" error with apt/apt-get when using corporate proxy
    rm -rf /var/lib/apt/lists/* && \
    echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99fixbadproxy && \
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99fixbadproxy && \
    echo "Acquire::BrokenProxy true;" >> /etc/apt/apt.conf.d/99fixbadproxy && \
    apt-get update -o Acquire::CompressionTypes::Order::=gz && \
  # Install common for Ubuntu
    apt-get clean -y && apt-get update -y && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      build-essential \
      curl \
      dialog \
      ed \
      git \
      libzmq3-dev \
      locales \
      nano \
      net-tools \
      nodejs \
      openssh-server \
      python-software-properties \
      software-properties-common \
      sudo \
      tmux \
      unzip \
      vim \
      wget && \
  # Some Config
    export TERM=xterm-256color && \
    export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get install -y --no-install-recommends tzdata && \
    ln -fs /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
  # Install Java 11 (8 is now deprecated as of Jan. 2019)
    add-apt-repository ppa:linuxuprising/java && \
    apt-get update -y && \
    echo oracle-java11-installer shared/accepted-oracle-license-v1-2 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y --no-install-recommends oracle-java11-installer && \
    apt-get install -y --no-install-recommends oracle-java11-set-default && \
  # FIX some annoying Ubuntu 16.04 warnings and errors
    # Annoying but benign: "W: mdadm: /etc/mdadm/mdadm.conf defines no arrays."
      mkdir -p /etc/mdadm && \
      touch /etc/mdadm/mdadm.conf && \
      echo "ARRAY <ignore> devices=/dev/sda" >> /etc/mdadm/mdadm.conf && \
  # LOCALE/LANGUAGE setup
    locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8 LC_MESSAGES=POSIX && dpkg-reconfigure locales && \
#
# Layer Cleanup
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  chown -R ubuntu:ubuntu /home/ubuntu/ && chown -R ubuntu:ubuntu /opt/ && chown -R ubuntu:ubuntu /tmp/
