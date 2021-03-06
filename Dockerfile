# vim:set ft=dockerfile:

# Clutter interview assignment
FROM ubuntu:16.04
MAINTAINER mfwilson <mfwilson@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# setup ubuntu
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends build-essential software-properties-common \
    byobu curl git htop man unzip vim wget checkinstall mercurial openssh-client \
    libpq-dev dnsutils strace lsof net-tools ca-certificates libssl-dev libbz2-dev iputils-ping \
    libreadline-dev libsqlite3-dev python3 python3-dev python3-pip sudo postgresql-client apt-utils 

# install PG 10
RUN apt-get -y --purge remove postgresql postgresql-9.5 postgresql-client-9.5 postgresql-client postgresql-client-common postgresql-common postgresql-contrib-9.5
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install -y postgresql-10
RUN mkdir /var/run/postgresql/10-main.pg_stat_tmp
RUN chown postgres:postgres /var/run/postgresql/10-main.pg_stat_tmp

# install sqlpad
# RUN npm install sqlpad -g

# remove apt lists / cleanup
RUN rm -rf /var/lib/apt/lists/*

RUN echo 'postgres:password' | chpasswd
RUN usermod -aG sudo postgres

USER postgres

# setup pyenv virtualenv
ENV PYENV_ROOT /var/lib/postgresql/.pyenv
ENV PATH /var/lib/postgresql/.pyenv/shims:/var/lib/postgresql/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

# Install python 3.5.1 via pyenv
RUN pyenv install 3.5.1

ENV PYENV_VERSION="3.5.1"
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ADD requirements.txt /tmp/
RUN pip install --upgrade pip
RUN pip install -r /tmp/requirements.txt

# install nvm
ENV NVM_DIR="/var/lib/postgresql/.nvm"
ENV NODE_VERSION="8.9.3"
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN echo "[ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\" # This loads nvm" >> /var/lib/postgresql/.bashrc

RUN npm install sqlpad -g

EXPOSE 5432
EXPOSE 3000 

CMD ["/bin/bash"]
