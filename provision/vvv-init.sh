#!/usr/bin/env bash
# Provision WordPress

set -eo pipefail

vvv_success " * Dexerto site template provisioner ${VVV_SITE_NAME}"

# fetch the first host as the primary domain. If none is available, generate a default using the site name
DB_NAME=$(get_config_value 'db_name' "${VVV_SITE_NAME}")
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*]/}
DB_PREFIX=$(get_config_value 'db_prefix' 'wp_')
DOMAIN=$(get_primary_host "${VVV_SITE_NAME}".test)
PUBLIC_DIR=$(get_config_value 'public_dir' "public_html")
SITE_TITLE=$(get_config_value 'site_title' "Dexerto")
REPO=$(get_config_value 'dexerto_repo' 'git@github.com:Dexerto/dexerto-site.git')
WP_TYPE="subdirectory"

PUBLIC_DIR_PATH="${VVV_PATH_TO_SITE}"
if [ ! -z "${PUBLIC_DIR}" ]; then
  PUBLIC_DIR_PATH="${PUBLIC_DIR_PATH}/${PUBLIC_DIR}"
fi



# Make a database, if we don't already have one
setup_database() {
  vvv_success -e " * Creating database '${DB_NAME}' (if it's not already there)"
  mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`"
  vvv_success -e " * Granting the wp user priviledges to the '${DB_NAME}' database"
  mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO wp@localhost IDENTIFIED BY 'wp';"
  vvv_success -e " * DB operations done."
}

setup_nginx_folders() {
  vvv_success " * Setting up the log subfolder for Nginx logs"
  noroot mkdir -p "${VVV_PATH_TO_SITE}/log"
  noroot touch "${VVV_PATH_TO_SITE}/log/nginx-error.log"
  noroot touch "${VVV_PATH_TO_SITE}/log/nginx-access.log"
  vvv_success " * Creating the public folder at '${PUBLIC_DIR}' if it doesn't exist already"
  noroot mkdir -p "${PUBLIC_DIR_PATH}"
}

restore_db_backup() {
  vvv_success " * Found a database backup at ${1}. Restoring the site"
  noroot wp db import "${1}"
  vvv_success " * Installed database backup"
}

download_dexerto() {
  vvv_success 'Downloading Dexerto'

  git clone "${REPO}" "${PUBLIC_DIR_PATH}"
}

initial_config() {
  cd "${PUBLIC_DIR_PATH}"

  ENV_FILE=.env

  if [[ ! -f "${PUBLIC_DIR_PATH}/${ENV_FILE}" ]]; then
    vvv_success "Creating new .env file."
    noroot cp .env.dist .env
  else
    vvv_success "$ENV_FILE already exists."
  fi

  vvv_success 'Updating .env vars...'
  sed -i "s/DB_NAME=.*/DB_NAME=${DB_NAME}/" .env
  sed -i "s/DB_USER=.*/DB_USER=root/" .env
  sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=root/" .env
  sed -i "s/WP_HOME=.*/WP_HOME=https:\/\/${DOMAIN}/" .env
  sed -i "s/WP_MULTISITE_DOMAIN=.*/WP_MULTISITE_DOMAIN=${DOMAIN}/" .env

  vvv_success 'Setting up object-cache.php...'

  noroot cp wp-content/plugins/memcached/object-cache.php wp-content/object-cache.php
}

install_wordpress() {
  vvv_success 'Proceeding to install WordPress...'

  ADMIN_USER=$(get_config_value 'admin_user' "dexertoadmin")
  ADMIN_PASSWORD=$(get_config_value 'admin_password' "password")
  ADMIN_EMAIL=$(get_config_value 'admin_email' "webdev@dexerto.com")

  vvv_success " * Installing using wp core multisite-install --url=\"${DOMAIN}\" --title=\"${SITE_TITLE}\" --admin_name=\"${ADMIN_USER}\" --admin_email=\"${ADMIN_EMAIL}\" --admin_password=\"${ADMIN_PASSWORD}\""
  
  noroot wp core multisite-install --url="${DOMAIN}" --title="${SITE_TITLE}" --admin_name="${ADMIN_USER}" --admin_email="${ADMIN_EMAIL}" --admin_password="${ADMIN_PASSWORD}"
  noroot wp site create --slug=fr --title="Dexerto (FR)" --email="${ADMIN_EMAIL}"
  noroot wp language core install fr_FR --activate --url="${DOMAIN}/fr"
  noroot wp site create --slug=es --title="Dexerto (ES)" --email="${ADMIN_EMAIL}"
  noroot wp language core install es_ES --activate --url="${DOMAIN}/es"

  vvv_success 'Setting up fixtures...'

  noroot wp package install git@github.com:nlemoine/wp-cli-fixtures.git
  noroot wp fixtures delete
  noroot wp fixtures load --file=fixtures-us.yml --url="${DOMAIN}"
  noroot wp fixtures load --file=fixtures-fr.yml --url="${DOMAIN}/fr"
  noroot wp fixtures load --file=fixtures-es.yml --url="${DOMAIN}/es"
}

update_wpsettings() {
  noroot wp cache flush
  noroot wp option update home "https://${DOMAIN}"
  noroot wp option update siteurl "https://${DOMAIN}/wp"

  vvv_success 'Imposing site state...'

  noroot wp dictator impose site-state.yml
}

copy_nginx_configs() {
  vvv_success " * Copying the sites Nginx config template"
  if [ -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx-custom.conf" ]; then
    vvv_success " * A vvv-nginx-custom.conf file was found"
    noroot cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx-custom.conf" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
  else
    vvv_success " * Using the default vvv-nginx-default.conf, to customize, create a vvv-nginx-custom.conf"
    noroot cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx-default.conf" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
  fi
  
  vvv_success " * Applying public dir setting to Nginx config"
  noroot sed -i "s#{vvv_public_dir}#/${PUBLIC_DIR}#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

  LIVE_URL=$(get_config_value 'live_url' '')
  if [ ! -z "$LIVE_URL" ]; then
    vvv_success " * Adding support for Live URL redirects to NGINX of the website's media"
    # replace potential protocols, and remove trailing slashes
    LIVE_URL=$(echo "${LIVE_URL}" | sed 's|https://||' | sed 's|http://||'  | sed 's:/*$::')

    redirect_config=$((cat <<END_HEREDOC
if (!-e \$request_filename) {
  rewrite ^/[_0-9a-zA-Z-]+(/wp-content/uploads/.*) \$1;
}
if (!-e \$request_filename) {
  rewrite ^/wp-content/uploads/(.*)\$ \$scheme://${LIVE_URL}/wp-content/uploads/\$1 redirect;
}
END_HEREDOC

    ) |
    # pipe and escape new lines of the HEREDOC for usage in sed
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n\\1/g'
    )

    noroot sed -i -e "s|\(.*\){{LIVE_URL}}|\1${redirect_config}|" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
  else
    noroot sed -i "s#{{LIVE_URL}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
  fi
}

setup_wp_config_constants(){
  set +e
  noroot shyaml get-values-0 -q "sites.${VVV_SITE_NAME}.custom.wpconfig_constants" < "${VVV_CONFIG}" |
  while IFS='' read -r -d '' key &&
        IFS='' read -r -d '' value; do
      lower_value=$(echo "${value}" | awk '{print tolower($0)}')
      vvv_success " * Adding constant '${key}' with value '${value}' to wp-config.php"
      if [ "${lower_value}" == "true" ] || [ "${lower_value}" == "false" ] || [[ "${lower_value}" =~ ^[+-]?[0-9]*$ ]] || [[ "${lower_value}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
        noroot wp config set "${key}" "${value}" --raw
      else
        noroot wp config set "${key}" "${value}"
      fi
  done
  set -e
}

setup_cli() {
  rm -f "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "# auto-generated file" > "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "path: \"${PUBLIC_DIR}\"" >> "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "@vvv:" >> "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "  ssh: vagrant@${DOMAIN}" >> "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "  path: ${PUBLIC_DIR_PATH}" >> "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "@${VVV_SITE_NAME}:" >> "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "  ssh: vagrant@${DOMAIN}" >> "${VVV_PATH_TO_SITE}/wp-cli.yml"
  echo "  path: ${PUBLIC_DIR_PATH}" >> "${VVV_PATH_TO_SITE}/wp-cli.yml"
}

cd "${VVV_PATH_TO_SITE}"

setup_cli
setup_database
setup_nginx_folders

# If new install
if [[ ! -f "${PUBLIC_DIR_PATH}/wp/wp-load.php" ]]; then
  download_dexerto
fi

cd "${PUBLIC_DIR_PATH}"

vvv_info 'Running composer install...'

noroot composer install

# Config or update .env
initial_config

noroot wp core is-installed
if [ $? -ne 0 ]; then
    vvv_info " * WordPress is present but isn't installed to the database, checking for SQL dumps in wp-content/database.sql or the main backup folder."
    if [ -f "${PUBLIC_DIR_PATH}/wp-content/database.sql" ]; then
      vvv_info " * Importing SQL dump from wp-content/database.sql"
      restore_db_backup "${PUBLIC_DIR_PATH}/wp-content/database.sql"
    elif [ -f "/srv/database/backups/${VVV_SITE_NAME}.sql" ]; then
      vvv_info " * Importing SQL dump from /srv/database/backups/${VVV_SITE_NAME}.sql"
      restore_db_backup "/srv/database/backups/${VVV_SITE_NAME}.sql"
    else
      install_wordpress
    fi

    # Check if WordPress is installed
    noroot wp core is-installed
    wp_installed=$?
    if [ $wp_installed -eq 0 ]; then
      vvv_success "WordPress is installed successfully."
    else
      vvv_error "WordPress installation failed. Please check the script and try again."
      exit 1
    fi
fi

update_wpsettings

copy_nginx_configs
setup_wp_config_constants

vvv_success " * Dexerto Site Template provisioner script completed for ${VVV_SITE_NAME}"
