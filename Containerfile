FROM registry.access.redhat.com/ubi8/php-74:1-47

# https://packagist.org/packages/bolt/project
ENV BOLT_PROJECT_VERSION 2.3.10


CMD bash /entrypoint.sh

USER 0

RUN curl -sS https://getcomposer.org/installer | php  && \
    mv -v composer.phar /usr/local/bin/composer && \
    composer create-project bolt/project app-src ${BOLT_PROJECT_VERSION}

WORKDIR /opt/app-root/src/app-src

RUN rm /etc/httpd/conf.d/ssl.conf \
 && echo 'DocumentRoot "/opt/app-root/src/app-src/public"' > /etc/httpd/conf.d/DocumentRoot.conf \
 && touch .env.prod.local


RUN mkdir /run/php-fpm \
  && chgrp -R 0 /var/log/httpd /var/run/httpd /run/php-fpm .env* \
  && chmod -R g=u /var/log/httpd /var/run/httpd /run/php-fpm .env*


EXPOSE 80

#USER 1001

COPY entrypoint.sh /entrypoint.sh
