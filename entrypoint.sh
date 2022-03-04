#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

[[ -z "${ADMIN_USERNAME:-}" ]] && echo "ADMIN_USERNAME missing"
[[ -z "${ADMIN_NAME:-}" ]] && echo "ADMIN_NAME missing"
[[ -z "${ADMIN_PASSWORD:-}" ]] && echo "ADMIN_PASSWORD missing"
[[ -z "${ADMIN_EMAIL:-}" ]] && echo "ADMIN_EMAIL missing"

[[ -z "${APP_ENV:-}" ]] && echo "APP_ENV missing"
[[ -z "${APP_DEBUG:-}" ]] && echo "APP_DEBUG missing"
[[ -z "${APP_SECRET:-}" ]] && echo "APP_SECRET missing"

[[ -z "${DATABASE_USER:-}" ]] && echo "DATABASE_USER missing"
[[ -z "${DATABASE_PASSWORD:-}" ]] && echo "DATABASE_PASSWORD missing"
[[ -z "${DATABASE_NAME:-}" ]] && echo "DATABASE_NAME missing"
[[ -z "${DATABASE_DRIVER:-}" ]] && echo "DATABASE_DRIVER missing"

export DATABASE_URL=$DATABASE_DRIVER://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST/$DATABASE_NAME

sed -i 's/^\(APP_ENV\)=.*$/\1='$APP_ENV'/' .env

echo "APP_DEBUG=$APP_DEBUG" >> .env.${APP_ENV}.local
cat <<EOF > .env.${APP_ENV}.local
APP_DEBUG=${APP_DEBUG}
APP_SECRET=${APP_SECRET}

DATABASE_URL=${DATABASE_URL}
EOF


if ! bin/console bolt:list-users 2>/dev/null; then
    echo "No user configured. Create the database."

    bin/console doctrine:schema:create

    bin/console bolt:add-user --admin "$ADMIN_USERNAME" "$ADMIN_PASSWORD" "$ADMIN_EMAIL" "$ADMIN_NAME"
else
    echo "User accounts already setup."
fi

mkdir -p config
config_count="$(find config -mindepth 1 -maxdepth 1 | wc -l)"
if [[ "$config_count" == 0 ]]; then
    echo "Config directory is empty."

    if [[ "${BOLT_CONFIG_REPO:-}" ]]; then
        [[ -z "BOLT_CONFIG_REPO_REF" ]] && BOLT_CONFIG_REPO_REF=master

        (cd config; git clone "$BOLT_CONFIG_REPO" -b "$BOLT_CONFIG_REPO_REF" .)

    else
        echo "BOLT_CONFIG_REPO not defined."
    fi
else
    echo "Config directory is already populated."
fi

[[ -z "BOLT_THEME_NAME" ]] && BOLT_THEME_NAME="theme"
theme_dir=public/theme/$BOLT_THEME_NAME
mkdir -p "$theme_dir"
theme_count="$(find "${theme_dir}" -mindepth 1 -maxdepth 1 | wc -l)"
if [[ "$theme_count" == 0 ]]; then
    echo "Theme directory is empty."
    if [[ "${BOLT_THEME_REPO:-}" ]]; then
        [[ -z "BOLT_THEME_REPO_REF" ]] && BOLT_THEME_REPO_REF=master

        (cd "$dest"; git clone "$BOLT_THEME_REPO" -b "$BOLT_THEME_REPO_REF" .)
    else
        echo "BOLT_CONFIG_REPO not defined."
    fi
else
    echo "Theme directory is already populated."
fi

if [[ "${SERVER_NAME:-}" ]]; then
    echo 'ServerName "'$SERVER_NAME'"' > /etc/httpd/conf.d/ServerName.conf
fi

echo "Done with the configuration."

php-fpm & httpd -D FOREGROUND
