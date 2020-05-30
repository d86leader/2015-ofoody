FROM debian:jessie
MAINTAINER Vladislav A. Retivykh <firolunis@riseup.net>

RUN apt-get update \
    && apt-get install -y nginx uwsgi uwsgi-plugin-psgi \
    && echo "\ndaemon off;" >> /etc/nginx/nginx.conf

RUN apt-get install -y libdbi-perl libdbd-mysql-perl

RUN useradd -M -d /home/ofoody ofoody
ADD --chown=ofoody:ofoody . /home/ofoody
RUN cp /home/ofoody/conf/ofoody.conf /etc/nginx/sites-enabled/ofoody.conf

CMD /usr/bin/uwsgi -y /home/ofoody/conf/ofoody.yaml && nginx
