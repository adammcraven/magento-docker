#!/bin/sh
set -e

setup_install_magento() {
  echo "==> BEGIN: setup_install_magento()"
  
  echo "==> Performing composer self update"
  /usr/local/bin/composer self-update
  
  echo "==> Performing composer create project"
  /usr/local/bin/composer create-project --repository-url=https://${MAGENTO_PUB_KEY}:${MAGENTO_PRIV_KEY}@repo.magento.com/ magento/project-community-edition /src
  
  chmod +x /src/bin/magento
  
  if [ "$USE_SAMPLE_DATA" = true ]; then
    echo "==> Installing composer dependencies..."
    /src/bin/magento sampledata:deploy
  
    echo "==> Ignore the above error (bug in Magento), fixing with 'composer update'..."
    composer update
  
    USE_SAMPLE_DATA_STRING="--use-sample-data"
  else
    USE_SAMPLE_DATA_STRING=""
  fi
  
  if [ -f /src/app/etc/config.php ] || [ -f /src/app/etc/env.php ]; then
    echo "==> Already installed? Either app/etc/config.php or app/etc/env.php exist, please remove both files to continue setup."
    exit
  fi
  
  echo "==> Running Magento 2 setup script..."
  /src/bin/magento setup:install \
    --db-host=$DB_HOST \
    --db-name=$DB_NAME \
    --db-user=$DB_USER \
    --db-password=$DB_PASSWORD \
    --base-url=$BASE_URL \
    --admin-firstname=$ADMIN_FIRSTNAME \
    --admin-lastname=$ADMIN_LASTNAME \
    --admin-email=$ADMIN_EMAIL \
    --admin-user=$ADMIN_USER \
    --admin-password=$ADMIN_PASSWORD \
    $USE_SAMPLE_DATA_STRING
  
  echo "==> Reindexing all indexes..."
  /src/bin/magento indexer:reindex

  echo "==> END: setup_install_magento()"
}




#############################################
################## Start ####################
#############################################

echo "==> BEGIN: docker-entrypoint.sh, with parameters: '$@'"

if [ "$SETUP_INSTALL" = "true" ]; then
  setup_install_magento
fi

echo "==> END: docker-entrypoint.sh"
