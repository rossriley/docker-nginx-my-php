FROM        ubuntu:14.04
MAINTAINER  Ross Riley "riley.ross@gmail.com"

# Install nginx
ENV HOME /root
RUN apt-get update
RUN apt-get install -y nginx
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN locale-gen en_US.UTF-8 && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale
RUN dpkg-reconfigure locales


# Install Mysql
VOLUME ["/data/mysql"]
RUN apt-get update
RUN apt-get -y install php5-mysql

# We start it here to allow the default directory to seed with the db setup
RUN chown -R mysql:mysql /data/

# Install PHP5 and modules along with composer binary
RUN apt-get install -y curl git
RUN apt-get -y install php5-fpm php5-pgsql php-apc php5-mcrypt php5-curl php5-gd php5-json php5-cli
RUN sed -i -e "s/short_open_tag = Off/short_open_tag = On/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size = 8M/post_max_size = 20M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 20M/g" /etc/php5/fpm/php.ini
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Configure nginx for PHP websites
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini
RUN echo "max_input_vars = 10000;" >> /etc/php5/fpm/php.ini
RUN echo "date.timezone = Europe/London;" >> etc/php5/fpm/php.ini

# Setup supervisor
RUN apt-get install -y supervisor
ADD supervisor/nginx.conf /etc/supervisor/conf.d/
ADD supervisor/php.conf /etc/supervisor/conf.d/
ADD supervisor/postgresql.conf /etc/supervisor/conf.d/
ADD supervisor/user.conf /etc/supervisor/conf.d/
ADD supervisor/mysql-start.sh /etc/supervisor/conf.d/mysql-start.sh
RUN chmod +x /etc/supervisor/conf.d/mysql-start.sh

# Disallow key checking
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config


# Adds the default server to nginx config
ADD config/nginx.conf /etc/nginx/sites-available/default

# Internal Port Expose
EXPOSE 80 443

ADD ./ /var/www/
CMD ["/usr/bin/supervisord", "-n"]
