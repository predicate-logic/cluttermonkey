# vim:set ft=dockerfile:

# GListen Clutter assignment
FROM ubuntu:16.04
MAINTAINER mfwilson <mfwilson@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Setup Ubuntu (https://github.com/dockerfile/ubuntu/blob/master/Dockerfile)
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends build-essential software-properties-common \
    byobu curl git htop man unzip vim wget checkinstall mercurial openssh-client \
    libpq-dev dnsutils strace lsof net-tools ca-certificates libssl-dev libbz2-dev iputils-ping \
    libreadline-dev libsqlite3-dev python3 python3-dev python3-pip sudo postgresql-client

# remove apt lists / cleanup
RUN rm -rf /var/lib/apt/lists/*

# setup pyenv virtualenv
ENV PYENV_ROOT /home/root/.pyenv
ENV PATH /home/root/.pyenv/shims:/home/root/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

# Install python 3.5.1 via pyenv
RUN pyenv install 3.5.1

ENV PYENV_VERSION="3.5.1"
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ADD get/requirements.txt /tmp/
RUN pip install --upgrade pip
RUN pip install -r /tmp/requirements.txt

CMD ["/bin/bash"] 
