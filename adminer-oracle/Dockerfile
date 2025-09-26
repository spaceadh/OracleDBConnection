FROM adminer:4.8.1

USER root

# Install Oracle dependencies
RUN set -x \
    && apk add --no-cache libaio libnsl libc6-compat \
    && apk add --no-cache --virtual .build-deps wget unzip

# Download Oracle Instant Client
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1921000/instantclient-basic-linux.x64-19.21.0.0.0dbru.zip \
    && wget https://download.oracle.com/otn_software/linux/instantclient/1921000/instantclient-sdk-linux.x64-19.21.0.0.0dbru.zip \
    && unzip instantclient-basic-linux.x64-19.21.0.0.0dbru.zip \
    && unzip instantclient-sdk-linux.x64-19.21.0.0.0dbru.zip \
    && mv instantclient_19_21 /usr/lib/oracle \
    && rm -f instantclient-*.zip

# Set Oracle environment
ENV LD_LIBRARY_PATH="/usr/lib/oracle:$LD_LIBRARY_PATH"
ENV ORACLE_HOME="/usr/lib/oracle"

# Install PHP Oracle extensions
RUN apk add --no-cache php81-pdo_oci php81-oci8 \
    && apk del .build-deps

USER adminer