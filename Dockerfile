FROM ubuntu:18.04
# Set the root password
RUN echo "root:tt" | chpasswd

# Install packages for building ruby
RUN apt-get update && apt-get install -y \
    autoconf \
    bison \
    build-essential \
    libpq-dev \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm5 \
    libgdbm-dev \
    libsqlite3-dev \
    nodejs
# Needed to install websphere RPMs
RUN apt-get update && apt-get install -y alien

# Useful for development
RUN apt-get install -y \
    git       \
    procps    \
    sudo      \
    unzip     \
    vim       \
    wget

# Setup locale
RUN apt-get install -y locales
RUN dpkg-reconfigure locales && \
  echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen && \
  /usr/sbin/update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN apt-get clean

# Change timezone to Pacific
RUN ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime

# Set application name
ENV APPLICATION=uscis_application_status_checker
ENV APPLICATION_USER=rails

# Add a ruby user (use jenkins server uid/gid)
RUN useradd -d /home/${APPLICATION_USER} -s /bin/bash -m ${APPLICATION_USER} -u 501
RUN echo "${APPLICATION_USER}:trust123" | chpasswd

# DEV IMAGES ONLY!!!
RUN echo "${APPLICATION_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# DEV IMAGES ONLY!!!

# Install nginx
RUN apt-get update && apt-get install -y nginx

# Configure app installation paths
RUN mkdir /opt/$APPLICATION
RUN chown -R ${APPLICATION_USER}:${APPLICATION_USER} /opt

USER $APPLICATION_USER

# Install rbenv and ruby-build
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Add rbenv to the bashrc and profile
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile

RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

# Install ruby and bundler
RUN bash -l -c "rbenv install 2.6.3"
RUN bash -l -c "rbenv global 2.6.3"

RUN bash -l -c "gem install bundler --force -v 2.0.2"

# Download application
RUN mkdir /opt/$APPLICATION/current
WORKDIR /opt/$APPLICATION/current
ADD . ./

EXPOSE 443
EXPOSE 3000
