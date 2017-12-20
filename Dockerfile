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
    libpq-dev dnsutils strace lsof net-tools ca-certificates libssl-dev libbz2-dev \
    libreadline-dev libsqlite3-dev python3 python3-dev python3-pip sudo

# install PG 10
RUN apt-get --purge remove postgresql postgresql-9.5 postgresql-client-9.5 postgresql-client-common  postgresql-common postgresql-contrib-9.5
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install -y postgresql-10
RUN mkdir /var/run/postgresql/10-main.pg_stat_tmp
RUN chown postgres:postgres /var/run/postgresql/10-main.pg_stat_tmp
RUN cat /etc/postgresql/10/main/pg_hba.conf

# remove apt lists / cleanup
RUN rm -rf /var/lib/apt/lists/*

# # setup pyenv virtualenv
# ENV PYENV_ROOT /home/root/.pyenv
# ENV PATH /home/root/.pyenv/shims:/home/root/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
# 
# # Install python 3.5.1 via pyenv
# RUN pyenv install 3.5.1
# 
# ENV PYENV_VERSION="3.5.1"
# ENV LC_ALL=C.UTF-8
# ENV LANG=C.UTF-8
# ADD glisten/stock_requirements.txt /home/root/
# ADD glisten/requirements.txt /home/root/
# RUN pip install --upgrade pip
# RUN pip install -r /home/root/stock_requirements.txt
# RUN pip install -r /home/root/requirements.txt

USER postgres
EXPOSE 5432
RUN echo "host  all  all 172.0.0.0/8 trust" >>  /etc/postgresql/10/main/pg_hba.conf
CMD ["/usr/lib/postgresql/10/bin/postgres", "-D", "/var/lib/postgresql/10/main", "-c", "ssl=off", "-c", "listen_addresses=*", "-c", "config_file=/etc/postgresql/10/main/postgresql.conf", "-c", "log_connections=yes"] 
