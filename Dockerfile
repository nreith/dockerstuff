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

####################################################################################
# ML SERVER 9.3.0 Install
####################################################################################
# ML Server paths for python, R, pip and conda to work
ENV LD_LIBRARY_PATH /opt/microsoft/mlserver/9.3.0/runtime/R/lib:$LD_LIBRARY_PATH
ENV PATH $PATH:/opt/microsoft/mlserver/9.3.0/runtime/python/bin/
ENV PATH $PATH:/opt/microsoft/mlserver/9.3.0/runtime/R/bin/
#
RUN \
#
  # Optionally, if your system does not have the https apt transport option
    apt-get clean && apt-get update && \
    cd /tmp && apt-get install -y --no-install-recommends apt-transport-https && \
  # Add the **azure-cli** repo to your apt sources list
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list && \
  # Set the location of the package repo the "prod" directory containing the distribution.
  # This example specifies 16.04. Replace with 14.04 if you want that version
    wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb && \
  # Register the repo
    dpkg -i packages-microsoft-prod.deb && \
  # Verify whether the "microsoft-prod.list" configuration file exists
    ls -la /etc/apt/sources.list.d/ && \
  # Add the Microsoft public signing key for Secure APT
  # NOTE: get MS key from Ubuntu keyserver, since ms is giving issues with network/proxy
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 && \
  # Update packages on your system
    apt-get update -y && \
  # Install the server
    apt-get install -y  --no-install-recommends -f microsoft-mlserver-all-9.3.0 && \
  # Activate the server
    /opt/microsoft/mlserver/9.3.0/bin/R/activate.sh && \
  # List installed packages as a verification step
    apt list --installed | grep microsoft && \
  # Choose a package name and obtain verbose version information
    dpkg --status microsoft-mlserver-packages-r-9.3.0 && \
    dpkg --status microsoft-mlserver-packages-py-9.3.0 && \
  # PATHS
    echo 'export LD_LIBRARY_PATH=/opt/microsoft/mlserver/9.3.0/runtime/R/lib:$LD_LIBRARY_PATH' >> /home/ubuntu/.bashrc \ 
	  R CMD javareconf && \
    echo 'export PATH="$PATH:/opt/microsoft/mlserver/9.3.0/runtime/python/bin/"' >> /home/ubuntu/.bashrc && \
    echo 'export PATH="$PATH:/opt/microsoft/mlserver/9.3.0/runtime/R/bin/"' >> /home/ubuntu/.bashrc && \
  # Make ML Server Python the Default Python
    echo 'alias python=mlserver-python' >> /home/ubuntu/.bashrc && \
    echo 'alias python3=mlserver-python' >> /home/ubuntu/.bashrc && \
    echo 'alias R=Revo64' >> /home/ubuntu/.bashrc && \
    source /home/ubuntu/.bashrc && \
    cd /opt/microsoft/mlserver/9.3.0/runtime/python/bin && \
#
# Layer Cleanup
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  chown -R ubuntu:ubuntu /home/ubuntu/ && chown -R ubuntu:ubuntu /opt/ && chown -R ubuntu:ubuntu /tmp/


####################################################################################
# DB DRIVERS
####################################################################################
RUN \
#
    apt-get clean -y && apt-get update -y && \
#
# MS SQL SERVER Drivers
#######################
#
    cd /tmp && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
  # Get Ubuntu 16.04 version of repo
    # Not necessary, because alread defined
    # curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
    apt-get update -y && \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql17 && \
  # optional: for bcp and sqlcmd
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends mssql-tools && \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/ubuntu/.bashrc && \
    source /home/ubuntu/.bashrc && \
  # optional: for unixODBC development headers
    apt-get install -y --no-install-recommends unixodbc-dev && \
  # Don't think we need these below
  # Create links to the static library names the MSSQL driver depends on
    # ln -s libcrypto.so.1.0.0 /lib/x86_64-linux-gnu/libcrypto.so.10 && \
    # ln -s libssl.so.1.0.0 /lib/x86_64-linux-gnu/libssl.so.10 && \
    # ln -s libodbcinst.so.2 /usr/lib/x86_64-linux-gnu/libodbcinst.so.1 && \
#
# Teradata ODBC Drivers
#######################
    mkdir /opt/terajdbc && cd /tmp && \
    wget https://s3-us-west-2.amazonaws.com/cs-dell/teradata/terajdbc4.jar -O /opt/terajdbc/terajdbc4.jar && \
    wget https://s3-us-west-2.amazonaws.com/cs-dell/teradata/tdgssconfig.jar -O /opt/terajdbc/tdgssconfig.jar && \
    wget https://s3.amazonaws.com/domino-dell-packages/tdodbc1620__ubuntu_indep.16.20.00.18-1.tar.gz && \
    tar -xf tdodbc1620__ubuntu_indep.16.20.00.18-1.tar.gz && \
    # Install libstdc++6 package
    apt-get -f install -y --no-install-recommends lib32stdc++6 lib32gcc1 libc6-i386 && \
    # Install Terdata driver  
    cd /tmp/tdodbc1620 && dpkg -i tdodbc1620-16.20.00.18-1.noarch.deb && \
    # Since unixODBC was installed earlier and is being used to manage
    # connections with SQL Server, the necessary ODBC entry for Teradata needs
    # to be added to the file /etc/odbcinst.ini.
    # Copy version of file from my S3 bucket that has necessary entry
    wget https://s3.amazonaws.com/dominofiles/odbcinst.ini -O /etc/odbcinst.ini && \
#
# Oracle DB Drivers
#######################
  # Drivers for Linux
    mkdir -p /opt/oracle && \
    wget https://s3-us-west-2.amazonaws.com/domino-deployment/2016/02/22/instantclient-basic-linux.x64-12.1.0.2.0.zip -O /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip && \
    wget https://s3-us-west-2.amazonaws.com/domino-deployment/2016/02/22/instantclient-sdk-linux.x64-12.1.0.2.0.zip -O /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip && \
    apt-get install -y --no-install-recommends libaio1 && \
    mkdir -p /opt/oracle/instantclient_12_1 && \
    cd /opt/oracle && \
    unzip instantclient-basic-linux.x64-12.1.0.2.0.zip && \
    unzip instantclient-sdk-linux.x64-12.1.0.2.0.zip && \
    cd /opt/oracle/instantclient_12_1 && \
    # ln -s libclntsh.so.12.1 libclntsh.so && \
    ln -s libocci.so.12.1 libocci.so && \
    echo 'export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1:\${LD_LIBRARY_PATH:-}' >> /home/ubuntu/.domino-defaults && \
    echo 'export PATH=/opt/oracle/instantclient_12_1:\${PATH:-}' >> /home/ubuntu/.domino-defaults && \   
    echo 'export PATH=/opt/oracle/instantclient_12_1:${PATH:-}' >> /home/ubuntu/.bashrc && \
    echo 'export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1:${LD_LIBRARY_PATH:-}' >> /home/ubuntu/.bashrc && \
  # PyOracle
    pip install cx_Oracle && \
  # Using conda for ROracle as it gives version trouble from CRAN and MRAN
    conda install -c eumetsat roracle && \
#
# PostgreSQL client
###################
    echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" > /etc/apt/sources.list.d/postgres.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && apt-get install -y postgresql-10 postgresql-client-10 postgresql-contrib-10 && \
#
# Layer Cleanup
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  chown -R ubuntu:ubuntu /home/ubuntu/ && chown -R ubuntu:ubuntu /opt/ && chown -R ubuntu:ubuntu /tmp/

USER ubuntu
CMD /bin/bash
