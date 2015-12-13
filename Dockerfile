FROM php:7.0-fpm

MAINTAINER Adam Craven <adam@ChannelAdam.com>

WORKDIR /src

#
# PHP
#

# Install pre-requisite base packages
RUN apt-get update && \
    apt-get install -y \
      libfreetype6-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libmcrypt-dev \
      libpng12-dev \
      libxslt1-dev \
      git \
      vim \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

# PHP Config Files
COPY php.ini /usr/local/etc/php/
COPY php-fpm.conf /usr/local/etc/

# Permissions needed to run proper filesystem permissions when using 'Dinghy' on OS X
RUN usermod -u 501 www-data


#
# Magento
#

# Install the minimally required PHP extensions to install and run Magento 2
RUN docker-php-ext-install \
  gd \
  intl \
  mbstring \
  mcrypt \
  pdo_mysql \
  xsl \
  zip

# http://devdocs.magento.com/guides/v2.0/install-gde/prereq/integrator_install.html
# https://getcomposer.org/download/
COPY download-magento.sh /
RUN chmod +x download-magento.sh && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    ./download-magento.sh && \
    chmod +x /src/bin/magento 

# TODO: set permissions too


# Entry point
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh 
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["run"]



#TODO: *****************
#VOLUME /magento
#WORKDIR /magento
#RUN rm -rf /var/www/html && ln -s /magento/pub /var/www/html
