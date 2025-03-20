FROM php:5.6-apache


# Install necessary extensions
RUN docker-php-ext-install -j "$(nproc)" mysqli pdo_mysql opcache

# Configure PHP settings for Cloud Run (or similar environments)
RUN { \
    echo "; Cloud Run enforces memory & timeouts"; \
    echo "memory_limit = -1"; \
    echo "max_execution_time = 0"; \
    echo "; File upload at Cloud Run network limit"; \
    echo "upload_max_filesize = 32M"; \
    echo "post_max_size = 32M"; \
    echo "; Configure Opcache for Containers"; \
    echo "opcache.enable = On"; \
    echo "opcache.validate_timestamps = Off"; \
    echo "; Configure Opcache Memory (Application-specific)"; \
    echo "opcache.memory_consumption = 32"; \
  } > "$PHP_INI_DIR/conf.d/cloud-run.ini"

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . .

# Set default port
ENV PORT=8080

# Change Apache configuration to use the defined port
RUN sed -i "s/80/${PORT}/g" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Create uploads directory and set permissions.
# We are keeping the 777 for now, as this was the original configuration.
# A warning will be printed to let the user know that this is a security risk.
#RUN mkdir -p uploads && chmod 777 uploads
RUN chmod 777 /var/www/html/upload.php 

# Use the production php.ini
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Expose the port
EXPOSE ${PORT}

# Print a warning about the use of chmod 777 and php5.6
RUN echo "WARNING: Using 'chmod 777 uploads/' is a major security risk. Consider using 'chmod 755' or more restrictive permissions." && \
    echo "WARNING: PHP 5.6 is extremely old and unsupported. It has severe security vulnerabilities. Upgrade to a supported version."
