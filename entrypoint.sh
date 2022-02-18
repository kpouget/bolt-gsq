#! /bin/bash

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


if ! bin/console bolt:list-users 2>/dev/null; then
    echo "No user configured. Create the database."

    bin/console doctrine:database:create
    bin/console doctrine:schema:create

    bin/console bolt:add-user --admin "$ADMIN_USERNAME" "$ADMIN_PASSWORD" "$ADMIN_EMAIL" "$ADMIN_NAME"
    bin/console doctrine:fixtures:load
else
    echo "User accounts already setup."
fi


if [[ "${BOLT_CONFIG_REPO:-}" ]]; then
    [[ -z "BOLT_CONFIG_REPO_REF" ]] && BOLT_CONFIG_REPO_REF=master

    rm -rf config
    git clone "$BOLT_CONFIG_REPO" -b "$BOLT_CONFIG_REPO_REF" --depth 1 config
    rm -rf config/.git
else
    echo "BOLT_CONFIG_REPO not defined."
fi


if [[ "${BOLT_THEME_REPO:-}" ]]; then
    [[ -z "BOLT_THEME_REPO_REF" ]] && BOLT_THEME_REPO_REF=master
    [[ -z "BOLT_THEME_NAME" ]] && BOLT_THEME_NAME="theme"

    dest=public/theme/$BOLT_THEME_NAME
    rm -rf "$dest"
    git clone "$BOLT_THEME_REPO" -b "$BOLT_THEME_REPO_REF" --depth 1 "$dest"
    rm -rf "$dest/.git"
else
    echo "BOLT_CONFIG_REPO not defined."
fi

if [[ "${SERVER_NAME:-}" ]]; then
    echo 'ServerName "'$SERVER_NAME'"' > /etc/httpd/conf.d/ServerName.conf
fi

echo "Done with the configuration."

php-fpm & httpd -D FOREGROUND
