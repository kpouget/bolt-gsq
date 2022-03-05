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

prepare_dir() {
    name=$1; shift
    dir=$1; shift
    repo=$1; shift
    ref=$1


    mkdir -p "$dir"
    count="$(find "$dir" -mindepth 1 -maxdepth 1 | wc -l)"
    if [[ "$count" == 0 ]]; then
    echo "$name directory is empty."

    if [[ "${repo}" ]]; then
        [[ -z "${ref}" ]] && ref=master

        (cd "$dir"; git clone "$repo" -b "$ref" .)

    else
        echo "$name repository is not defined."
    fi
else
    echo "$name directory is already populated."
    (cd "$dir"; git show --quiet 2>/dev/null || true)
fi

prepare_dir App app "${BOLT_APP_REPO:-}" "${BOLT_APP_REPO_REF:-}"
prepare_dir Config config "${BOLT_CONFIG_REPO:-}" "${BOLT_CONFIG_REPO_REF:-}"
prepare_dir Theme "public/theme/${BOLT_THEME_NAME:-theme}" "${BOLT_THEME_REPO:-}" "${BOLT_THEME_REPO_REF:-}"

if ! bin/console bolt:list-users 2>/dev/null; then
    echo "No user configured. Create the database."

    bin/console doctrine:schema:create

    bin/console bolt:add-user --admin "$ADMIN_USERNAME" "$ADMIN_PASSWORD" "$ADMIN_EMAIL" "$ADMIN_NAME"
else
    echo "User accounts already setup."
fi

if [[ "${SERVER_NAME:-}" ]]; then
    echo 'ServerName "'$SERVER_NAME'"' > /etc/httpd/conf.d/ServerName.conf
fi

echo "Done with the configuration."

php-fpm &

exec httpd -D FOREGROUND
