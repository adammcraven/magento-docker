#!/bin/bash
set -e

echo "==> START: download-mageneto.sh"

echo "==> Using \$MAGENTO_PUB_KEY='$MAGENTO_PUB_KEY'"
echo "==> Using \$MAGENTO_PRIV_KEY='$MAGENTO_PRIV_KEY'" 
/usr/local/bin/composer create-project --repository-url=https://${MAGENTO_PUB_KEY}:${MAGENTO_PRIV_KEY}@repo.magento.com/ magento/project-community-edition /src

echo "==> END: download-mageneto.sh"