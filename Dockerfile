# =============================================================================
# HELPDESK - Dockerfile (Academy Deployment Format)
# =============================================================================
FROM php:8.4-fpm

# -----------------------------------------------------------------------------
# System dependencies for Laravel + PostgreSQL + Redis
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    curl \
    unzip \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    postgresql-client \
    && update-ca-certificates \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_pgsql \
        pgsql \
        zip \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        intl \
        opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Redis extension
# -----------------------------------------------------------------------------
RUN mkdir -p /usr/src/php/ext/redis \
    && curl -fsSL https://github.com/phpredis/phpredis/archive/refs/tags/6.3.0.tar.gz \
       | tar xz -C /usr/src/php/ext/redis --strip-components=1 \
    && docker-php-ext-install redis

# -----------------------------------------------------------------------------
# Composer (stable)
# -----------------------------------------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1

# -----------------------------------------------------------------------------
# PHP Configuration
# -----------------------------------------------------------------------------
RUN echo '\
post_max_size = 100M\n\
upload_max_filesize = 100M\n\
' > /usr/local/etc/php/conf.d/helpdesk.ini

# -----------------------------------------------------------------------------
# Application
# -----------------------------------------------------------------------------
WORKDIR /var/www
COPY . .

# -----------------------------------------------------------------------------
# Storage directories & permissions
# -----------------------------------------------------------------------------
RUN mkdir -p \
    storage/logs \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/app/public \
    bootstrap/cache \
    && chown -R www-data:www-data /var/www \
    && chmod -R 775 storage bootstrap/cache

# -----------------------------------------------------------------------------
# Entrypoint
# -----------------------------------------------------------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
