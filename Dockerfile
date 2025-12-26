# syntax=docker/dockerfile-upstream:master
FROM rockylinux:9.3 AS cache1
ENV X_VER="11.0.2"
ENV X_TRG_DIR="/opt/xdmod-${X_VER}"
ENV X_SRC_DIR="/opt/xdmod-source"
RUN dnf install -y epel-release
RUN /usr/bin/crb enable
#RUN dnf module -y reset php
#RUN dnf module -y enable php:7.4
RUN dnf install -y php make libzip-devel php-pear php-devel mariadb-server mariadb
RUN dnf install -y php-fpm caddy supervisor sendmail php-mysqlnd
#RUN dnf install -y mod_ssl
RUN dnf module -y install nodejs:18 
FROM cache1 AS stage1

#FROM cache1 AS devel1
#RUN dnf install -y git
#RUN git clone https://github.com/ubccr/xdmod.git ${X_SRC_DIR}
#RUN dnf install -y php-pecl-mongodb
#RUN source]# cd ..
#RUN mkdir ${X_TRG_DIR}
#RUN ln -s ${X_SRC_DIR}/background_scripts/ ${X_TRG_DIR}/lib
#RUN ln -s ${X_SRC_DIR}/bin/ ${X_TRG_DIR}/bin
#RUN ln -s ${X_SRC_DIR}/configuration/ ${X_TRG_DIR}/etc
##RUN composer install --ignore-platform-req=ext-mongodb


RUN groupadd -r xdmod
RUN useradd -r -M -c "Open XDMoD" -g xdmod -d /opt/xdmod-11.0.2/lib -s /sbin/nologin xdmod
#VOLUME ["/var/www", "/var/log/httpd", "/etc/httpd/conf.d/"]

FROM stage1 as install1
ENV X_LOG_DIR="/var/log/xdmod/"
RUN mkdir ${X_LOG_DIR} 
RUN mkdir /run/php-fpm
#RUN chown apache:apache /run/php-fpm
RUN chmod 770 ${X_LOG_DIR} 
RUN chown apache:xdmod ${X_LOG_DIR} 
RUN --mount=type=bind,source=./xdmod-${X_VER},target=${X_SRC_DIR} \
	${X_SRC_DIR}/install --prefix=${X_TRG_DIR} --httpdconfdir "/etc/httpd/conf.d/" --logdir="${X_LOG_DIR}"
#ARG MARIADB_MYSQL_SOCKET_DIRECTORY='/var/run/mysqld'
#RUN mkdir -p $MARIADB_MYSQL_SOCKET_DIRECTORY && \
#    chown root:mysql $MARIADB_MYSQL_SOCKET_DIRECTORY && \
#    chmod 774 $MARIADB_MYSQL_SOCKET_DIRECTORY

#RUN cp ${X_TRG_DIR}/share/templates/apache.conf /etc/httpd/conf.d/xdmod.conf
RUN cp ${X_TRG_DIR}/share/templates/xdmod.caddyfile  /etc/caddy/Caddyfile.d/xdmod.caddyfile
RUN cp ${X_TRG_DIR}/share/templates/xdmod-supervisord.ini /etc/supervisord.d/
RUN cp ${X_TRG_DIR}/share/templates/xdmod-fpm.conf /etc/php-fpm.d/www.conf
RUN cp ${X_TRG_DIR}/share/templates/xdmod-my.cnf /etc/my.cnf.d/mariadb-server.cnf
RUN  mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
# caddy run --config /etc/caddy/Caddyfile
#ln -s /opt/xdmod-source/templates/xdmod.caddyfile /etc/caddy/Caddyfile.d/xdmod.caddyfile
#RUN chmod 440 /opt/xdmod-11.0.2/etc/portal_settings.ini
#RUN chown apache:xdmod /opt/xdmod-11.0.2/etc/portal_settings.ini
# usermod -a -G xdmod jdoe
#RUN chmod 770 /opt/xdmod-11.0.2/logs
#RUN chown apache:xdmod /opt/xdmod-11.0.2/logs
#RUN touch /opt/xdmod-11.0.2/logs/exceptions.log
#RUN chmod 660 /opt/xdmod-11.0.2/logs/exceptions.log
#RUN chown apache:xdmod /opt/xdmod-11.0.2/logs/exceptions.log
#RUN touch /opt/xdmod-11.0.2/logs/query.log
#RUN chmod 660 /opt/xdmod-11.0.2/logs/query.log
#RUN chown apache:xdmod /opt/xdmod-11.0.2/logs/query.log
RUN chown apache:xdmod /var/log/php-fpm/

#USER apache
WORKDIR ${X_TRG_DIR}
EXPOSE 80/tcp
#ENTRYPOINT httpd
#ENTRYPOINT caddy run --config /etc/caddy/Caddyfile
RUN echo "supervisord  -c /etc/supervisord.conf" >> /root/.bash_history
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
#RUN openssl genrsa -out /etc/pki/tls/certs/localhost.crt 2048
#RUN openssl req -new -key server.key -out server.csr
