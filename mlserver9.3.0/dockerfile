
# Image Name:
# mlserver9.3.0-py3.5
#############################################################################################
# Ubuntu-16.04  + Minimal Version of Microsoft Machine Learning Server 9.3.0 (Python 3.5 only)

# Ubuntu BASE - phase 1
#############################################################################################

FROM ubuntu:16.04 AS ubuntup1

LABEL maintaners="Nick Reith <nreith@gmail.com>"
SHELL ["/bin/bash", "-c"]
USER root
ENV \
  TERM="xterm" \
  TZ="US/Central" \
  DEBIAN_FRONTEND="noninteractive"

RUN cat /etc/os-release && \
# Installing apt-utils first to avoid error message
  apt-get clean && apt-get update && \
  apt-get install -y apt-utils --no-install-recommends && \
#
# Commonly installed packages
  apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    sudo \
    dialog `useful user dialogs` \
    file `recognizes filetype` \
    git \
    gnupg `for pgp keys` \
    iputils-ping `network testing` \
    tzdata \
    locales `internationalization` \
    nano `easy text editor` \
    net-tools `ifconfig, etc.` \
    openssh-server \
    rsync `to sync for git/azure workflow` \
    software-properties-common `necessary` \
    openjdk-8-jre \ 
    unzip \
    vim `only 1mb` \
    wget \
    zip && \
    # Trying to slim down a bit
    # python-software-properties \ 
    # bash-completion \
    # fonts-texgyre \
#
# Timezone / Locale stuff
  ln -fs /usr/share/zoneinfo/America/Chicago /etc/localtime && \
  dpkg-reconfigure --frontend noninteractive tzdata && \
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG="en_US.UTF-8" LC_MESSAGES="POSIX" && \
  dpkg-reconfigure --frontend noninteractive locales && \
#
# Add Users
  groupadd -g 12574 ubuntu && \
  useradd -u 12574 -g 12574 -m -N -s /bin/bash ubuntu && \
#
# Ensure Ubuntu user owns everything in its home directory
  chown -R ubuntu:ubuntu /home/ubuntu/ && \
# Layer Cleanup
  apt-get clean && apt-get autoclean && apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# ML SERVER + DB DRIVERS FOR MS SQL AND TERADATA phase 2
#############################################################################################

FROM ubuntup1 AS mlserverp2

ENV PATH="/opt/microsoft/mlserver/9.3.0/runtime/python/bin:$PATH"

# ML SERVER 9.3.0
#############################################################################################
RUN \
# Set the location of the package repo the "prod" directory containing the distribution.
  cd /tmp && wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb && \
# Register the repo
  dpkg -i packages-microsoft-prod.deb && \
# Verify whether the "microsoft-prod.list" configuration file exists
  ls -la /etc/apt/sources.list.d/ && \
# Install ML Server Python Components, minus optional pre-trained models
# and web/compute node or server admin stuff
  apt-get -y update && \
  apt-get install -y azure-cli \
    microsoft-mlserver-python-9.3.0 \
    microsoft-mlserver-packages-py-9.3.0 && \
    echo "export PATH=\"/opt/microsoft/mlserver/9.3.0/runtime/python/bin:$PATH\"" >> /home/ubuntu/.bashrc && \
    echo "conda config --add channels conda-forge" >> /home/ubuntu/.bashrc && \
# Capture pip freeze and conda list of current packages before anything changes
  echo "# pip freeze of original versions\n" > /opt/microsoft/mlserver/.pipfreeze_original && \
  pip freeze >> /opt/microsoft/mlserver/.pipfreeze_original && \
  echo "# conda list of original versions\n" > /opt/microsoft/mlserver/.condalist_original && \
  conda list >> /opt/microsoft/mlserver/.condalist_original && \
# Remove (obviously) unnecessary packages from Microsoft's install nightmare.
  conda remove \
    astropy \
    blaze \
    bokeh \
    conda-build \
    curl \
    cython \
    dask \
    flask \
    flask-cors \
    h5py \
    hdf5 \
    networkx \
    numba \
    plotly \
    pyqt \
    pytables \
    qt \
    qtawesome \
    qtconsole \
    qtpy \
    redis \
    redis-py \
    scikit-image \
    setuptools \
    sphinx \
    spyder \
    sympy && \
  conda clean -tipsy && \
# This python version is old enough that recent conda builds of setuptools aren't available.
  pip install setuptools && \
# Turn off anonymous telemtry for MS ML Server
  mlserver-python -c 'import revoscalepy; revoscalepy.rx_privacy_control(False)' && \
#
# MS SQL Server ODBC Drivers
  cd /tmp && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
  curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/microsoft-prod.list && \
  apt-get update -y && \
  ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql17 && \
# optional: for bcp and sqlcmd && \
  # ACCEPT_EULA=Y apt-get install -y --no-install-recommends mssql-tools
  # echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /home/$USER/.bashrc
#
  echo '[ODBC Driver 17 for SQL Server]' >> /etc/odbcinst.ini && \
  echo 'Description=Microsoft ODBC Driver 17 for SQL Server' >> /etc/odbcinst.ini && \
  echo 'Driver=/opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.2.so.0.1' >> /etc/odbcinst.ini && \
  echo 'Threading=1' >> /etc/odbcinst.ini && \
  echo 'UsageCount=1' >> /etc/odbcinst.ini && \
  echo '' >> /etc/odbcinst.ini && \
#
# Teradata ODBC Drivers
  echo 'cd /tmp' >> /etc/odbcinst.ini && \
  echo 'wget https://stuff-for-devops.s3.amazonaws.com/dbdrivers/tdodbc1620__linux_indep.16.20.00.68-1.tar.gz' >> /etc/odbcinst.ini && \
  echo 'tar -xf tdodbc1620__ubuntu_indep.16.20.00.18-1.tar.gz' >> /etc/odbcinst.ini && \
  echo 'apt-get -f install -y --no-install-recommends lib32stdc++6 lib32gcc1 libc6-i386' >> /etc/odbcinst.ini && \
  echo 'cd /tmp/tdodbc1620 && dpkg -i tdodbc1620-16.20.00.18-1.noarch.deb' >> /etc/odbcinst.ini && \
  echo '#' >> /etc/odbcinst.ini && \
  echo '[Teradata ODBC Driver 16.20]' >> /etc/odbcinst.ini && \
  echo 'Description=Teradata Database ODBC Driver 16.20' >> /etc/odbcinst.ini && \
  echo 'Driver=/opt/teradata/client/ODBC_64/lib/tdataodbc_sb64.so' >> /etc/odbcinst.ini && \
  echo '# Note: Currently, Data Direct Driver Manager does not support Connection Pooling feature.' >> /etc/odbcinst.ini && \
#
# Ensure user permissions on certain folders to allow conda/pip installs
  chown -R ubuntu:ubuntu /opt/microsoft/mlserver/9.3.0/runtime/python/ && \
#
# Layer Cleanup
  apt-get clean && apt-get autoclean && apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
