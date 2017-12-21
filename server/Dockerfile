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

# install PG 10
RUN apt-get -y --purge remove postgresql postgresql-9.5 postgresql-client-9.5 postgresql-client postgresql-client-common postgresql-common postgresql-contrib-9.5
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install -y postgresql-10
RUN mkdir /var/run/postgresql/10-main.pg_stat_tmp
RUN chown postgres:postgres /var/run/postgresql/10-main.pg_stat_tmp

# remove apt lists / cleanup
RUN rm -rf /var/lib/apt/lists/*

USER postgres

EXPOSE 5432

# open up PG to accept all connections
RUN echo "host  all  all 172.0.0.0/8 trust" >>  /etc/postgresql/10/main/pg_hba.conf

# start PG server
CMD ["/bin/bash"]
#CMD ["/usr/lib/postgresql/10/bin/postgres", "-D", "/var/lib/postgresql/10/main", "-c", "listen_addresses=*", "-c", "config_file=/etc/postgresql/10/main/postgresql.conf", "-c", "log_connections=yes", "-c", "log_statement=ddl"] 
