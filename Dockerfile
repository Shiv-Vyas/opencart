# Base image
FROM php:8.2.11-apache

# Arguments for optional custom OpenCart download
ARG DOWNLOAD_URL
ARG FOLDER

# Environment variables
ENV DIR_OPENCART='/var/www/html/'
ENV DIR_STORAGE='/storage/'
ENV DIR_CACHE=${DIR_STORAGE}'cache/'
ENV DIR_DOWNLOAD=${DIR_STORAGE}'download/'
ENV DIR_LOGS=${DIR_STORAGE}'logs/'
ENV DIR_SESSION=${DIR_STORAGE}'session/'
ENV DIR_UPLOAD=${DIR_STORAGE}'upload/'
ENV DIR_IMAGE=${DIR_OPENCART}'image/'

# Install required packages and PHP extensions
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    vim \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd zip mysqli opcache

# Enable Apache rewrite module
RUN a2enmod rewrite

# Create storage directories
RUN mkdir -p ${DIR_STORAGE} \
    && mkdir -p ${DIR_OPENCART}

# Download latest OpenCart if no DOWNLOAD_URL provided
RUN if [ -z "$DOWNLOAD_URL" ]; then \
        curl -Lo /tmp/opencart.zip $(curl -s https://api.github.com/repos/opencart/opencart/releases/latest \
        | grep "browser_download_url" | cut -d : -f 2,3 | tr -d '"'); \
    else \
        curl -Lo /tmp/opencart.zip ${DOWNLOAD_URL}; \
    fi

# Unzip OpenCart
RUN unzip /tmp/opencart.zip -d /tmp/opencart \
    && cp -r /tmp/opencart/upload/* ${DIR_OPENCART} \
    && rm -rf /tmp/opencart /tmp/opencart.zip

# Remove install folder after copy
RUN rm -rf ${DIR_OPENCART}install

# Move system storage to separate storage folder
RUN mv ${DIR_OPENCART}system/storage/* ${DIR_STORAGE}

# Set folder permissions
RUN chown -R www-data:www-data ${DIR_STORAGE} ${DIR_IMAGE} ${DIR_OPENCART} \
    && chmod -R 775 ${DIR_STORAGE} ${DIR_CACHE} ${DIR_SESSION} ${DIR_UPLOAD} ${DIR_DOWNLOAD} \
    && chmod -R 755 ${DIR_OPENCART} ${DIR_IMAGE}

# Optional: copy your custom config files if needed
# COPY configs ${DIR_OPENCART}
# COPY php.ini ${PHP_INI_DIR}/php.ini

# Expose port
EXPOSE 8080

# Start Apache