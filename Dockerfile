FROM ubuntu:trusty
MAINTAINER mooxavier <mooxavier [at] gmail . com>

ENV DEBIAN_FRONTEND noninteractive

# Install packages for ubuntu 14.04 LTS
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get -y install wget pwgen language-pack-en mysql-server
RUN apt-get clean

# Make sure fore EN locale
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL scripts
ADD start-mysql.sh /start-mysql.sh
RUN chmod 755 /*.sh

# Exposed ENV
ENV MYSQL_USER admin
ENV MYSQL_PASS **Random**

# Add VOLUMEs to allow backup of config and databases
VOLUME ["/etc/mysql", "/var/lib/mysql"]

EXPOSE 3306
CMD ["/start-mysql.sh"]
