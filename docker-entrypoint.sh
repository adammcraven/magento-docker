#!/bin/bash
set -e

composer_self_update() {
  echo "==> Performing composer self update"
  /usr/local/bin/composer self-update
}

setup_deploy_sample_data() {
  echo "==> BEGIN: setup_deploy_sample_data()"

  /magento/bin/magento sampledata:deploy

  #echo "==> Ignore the above error (bug in Magento), fixing with 'composer update'..."
  #composer update

  USE_SAMPLE_DATA=true

  echo "==> END: setup_deploy_sample_data()"
}

setup_configure() {
  echo "==> BEGIN: setup_configure()"

#  if [ -f /magento/app/etc/config.php ] || [ -f /magento/app/etc/env.php ]; then
#    echo "==> Already configured. Either app/etc/config.php or app/etc/env.php exist, please remove both files to continue setup."
#    exit -1
#  fi

  if [ "$USE_SAMPLE_DATA" = true ]; then
    USE_SAMPLE_DATA_STRING="--use-sample-data"
  else
    USE_SAMPLE_DATA_STRING=""
  fi

  echo "==> Running Magento 2 setup script..."
  /magento/bin/magento setup:install \
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
    --backend-frontname=$BACKEND_FRONTNAME \
    --language=$LANGUAGE \
    --currency=$CURRENCY \
    --timezone=$TIMEZONE \
    --use-rewrites=$USE_REWRITES \
    --use-secure=$USE_SECURE \
    --base-url-secure=$BASE_URL_SECURE \
    --session-save=$SESSION_SAVE \
    $USE_SAMPLE_DATA_STRING

  echo "==> END: setup_configure()"
}

create_composer_auth_file() {
  echo "==> BEGIN: create_composer_auth_file()"
    
  mkdir -p "$HOME/.composer"
  composerConf="$HOME/.composer/auth.json"
  rm -f $composerConf

  echo "==> Creating the Composer auth json file"
  echo "==> Using MAGENTO_PUB_KEY='$MAGENTO_PUB_KEY'"
  echo "==> Using MAGENTO_PRIV_KEY='$MAGENTO_PRIV_KEY'" 
  echo "==> Using GITHUB_ACCESS_TOKEN='$GITHUB_ACCESS_TOKEN'" 
 
  ( cat <<EOM
{
  "http-basic": {
      "repo.magento.com": {
          "username": "$MAGENTO_PUB_KEY",
          "password": "$MAGENTO_PRIV_KEY"
      }
  }
EOM
  ) >> $composerConf

  if [ $GITHUB_ACCESS_TOKEN ]; then
    echo ", \"github-oauth\": { \"github.com\": \"$GITHUB_ACCESS_TOKEN\" }" >> $composerConf
  fi
 
  echo "}" >> $composerConf

  echo "==> END: create_composer_auth_file()"
}

setup_update() {
  echo "==> BEGIN: setup_update()"
  create_composer_auth_file
  
  composer_self_update
  
  echo "==> Performing update"
  composer update
  
  echo "==> END: setup_update()"
}

indexer_reindex() {
  echo "==> BEGIN: indexer_reindex()"
  echo "==> Reindexing all indexes..."
  /magento/bin/magento indexer:reindex  
  echo "==> END: indexer_reindex()"
}

run_phpfpm() {
  echo "==> BEGIN: run()"
  echo "==> Running php-fpm"
  php-fpm &
  pid="$!"
  echo "==> php-fpm pid: $pid"
  echo "==> php-fpm is running..."
  wait "$pid"
  echo "==> php-fpm has ended"  
  echo "==> END: run()"
}


#############################################
################## Start ####################
#############################################
echo
echo "######################################################"
echo "==> BEGIN: docker-entrypoint.sh, with parameters: '$@'"

if [ "$1" = "setup:deploy-sample-data" ]; then
  setup_deploy_sample_data

elif [ "$1" = "setup:configure" ]; then
  setup_configure

elif [ "$1" = "setup:update" ]; then
  setup_update

elif [ "$1" = "indexer:reindex" ]; then
  indexer_reindex

elif [ "$1" = "run" ]; then
  run_phpfpm

else
  echo "==> ERROR: Unknown command '$1'"
  exit -1
fi

echo "==> END: docker-entrypoint.sh"
