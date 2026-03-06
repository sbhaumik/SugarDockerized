FROM php:8.2.2-cli

RUN apt-get update \
    && apt-get install -y \
    sudo \
    vim \
    unzip \
    libpng-dev \
    libgmp-dev \
    libzip-dev \
    libc-client-dev \
    libkrb5-dev \
    libldap2-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libxml2-dev \
    git \
    curl \
    apt-transport-https \
    gnupg \
    unixodbc-dev \
    --no-install-recommends

RUN apt-get clean \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN adduser sugar --disabled-password --disabled-login --gecos "" \
    && echo "sugar ALL=NOPASSWD: ALL" > /etc/sudoers.d/sugar

# Install Zscaler certificates if available
COPY certificates/ /tmp/certificates/
RUN if [ -d "/tmp/certificates" ] && [ "$(ls -A /tmp/certificates/*.crt 2>/dev/null || true)" ]; then \
        echo "Installing Zscaler certificates..."; \
        cp /tmp/certificates/*.crt /usr/local/share/ca-certificates/ 2>/dev/null || true; \
        update-ca-certificates || echo "Certificate update failed, continuing..."; \
    else \
        echo "No Zscaler certificates found, skipping certificate installation..."; \
    fi

# Install Microsoft ODBC Driver for SQL Server
RUN apt-get update \
    && apt-get install -y ca-certificates \
    && curl -k https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] https://packages.microsoft.com/debian/11/prod/ bullseye main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && (ACCEPT_EULA=Y apt-get install -y msodbcsql17 || echo "Microsoft ODBC driver installation failed, continuing...") \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "<?php \$_SERVER['SERVER_SOFTWARE'] = 'SugarDockerized';" > /usr/local/php/prepend.php

RUN docker-php-ext-install bcmath \
    && docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg \ 
    && docker-php-ext-install gd \
    && docker-php-ext-install gmp \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-install zip \
    && docker-php-ext-install ldap \
    && docker-php-ext-install ldap \
    && docker-php-ext-install pdo \
    && (pecl install sqlsrv || echo "sqlsrv installation failed, continuing...") \
    && (pecl install pdo_sqlsrv || echo "pdo_sqlsrv installation failed, continuing...") \
    && (docker-php-ext-enable sqlsrv || echo "sqlsrv extension enable failed, continuing...") \
    && (docker-php-ext-enable pdo_sqlsrv || echo "pdo_sqlsrv extension enable failed, continuing...") \
    && (pecl install xdebug || echo "xdebug installation failed, continuing...") \
    && (pecl install redis || echo "redis installation failed, continuing...") \
    && (docker-php-ext-enable redis || echo "redis extension enable failed, continuing...") \
    && docker-php-ext-install soap

RUN docker-php-ext-install -j$(nproc) gd

# disable by default, it can be enabled locally
#COPY images/php/82/cron/config/php/mods-available/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY images/php/82/cron/config/php/docker.ini /usr/local/etc/php/conf.d/docker.ini
COPY images/php/82/cron/config/php/mods-available/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY images/php/82/cron/config/php/opcache-blacklist /usr/local/etc/php/opcache-blacklist

RUN git config --global http.sslverify false \
    && git clone https://github.com/tideways/php-xhprof-extension.git tideways \
    && cd tideways \
    && /usr/local/bin/phpize \
    && ./configure --with-php-config=/usr/local/bin/php-config \
    && make \
    && make install

COPY images/php/82/cron/config/php/mods-available/tideways.ini /usr/local/etc/php/conf.d/tideways.ini

RUN git clone https://github.com/longxinH/xhprof.git xhprof \
    && cd xhprof/extension/ \
    && /usr/local/bin/phpize \
    && ./configure --with-php-config=/usr/local/bin/php-config \
    && make \
    && make install

COPY images/php/82/cron/config/php/mods-available/xhprof.ini /usr/local/etc/php/conf.d/xhprof.ini

# Important to enable providers
RUN sed -i 's/^# providers = provider_sect/providers = provider_sect/' /etc/ssl/openssl.cnf 

# Append the custom OpenSSL configuration to the existing openssl.cnf
RUN echo '[provider_sect]' >> /etc/ssl/openssl.cnf && \
    echo 'default = default_sect' >> /etc/ssl/openssl.cnf && \
    echo 'legacy = legacy_sect' >> /etc/ssl/openssl.cnf && \
    echo '[default_sect]' >> /etc/ssl/openssl.cnf && \
    echo 'activate = 1' >> /etc/ssl/openssl.cnf && \
    echo '[legacy_sect]' >> /etc/ssl/openssl.cnf && \
    echo 'activate = 1' >> /etc/ssl/openssl.cnf

# Install composer by downloading the phar directly
RUN curl -k -o /usr/local/bin/composer https://getcomposer.org/download/2.5.8/composer.phar && \
    chmod +x /usr/local/bin/composer

COPY images/php/82/cron/apps/sugarcron /usr/local/bin/sugarcron
RUN chmod +x /usr/local/bin/sugarcron

WORKDIR "/var/www/html/sugar"
USER sugar

CMD ["/usr/local/bin/sugarcron"]
