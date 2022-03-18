DB_FILENAME=../secrets/bolt_gsq.sql
DATA_DIR=../../data/bolt/files
POD_NAME=website-pod-0-db

PASS=$(cat secrets/secrets.yaml | grep DATABASE_PASSWORD | awk '{printf $2 }')

podman exec -i $POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq" <<< "SET FOREIGN_KEY_CHECKS=0;$(cat "$DB_FILENAME" | grep 'ALTER TABLE' | sed 's/ALTER TABLE/DROP TABLE IF EXISTS/' | sed 's/$/;/');SET FOREIGN_KEY_CHECKS=1;"

podman exec -i $POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq" < "$DB_FILENAME"
podman exec $POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq -e 'SHOW tables;'"
podman exec $POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq -e 'SELECT * FROM bolt_user;'"


if [ ! -d "$(ls $DATA_DIR)" ]; then
  echo "WARNING: data directory doesn't exist"

elif [ -z "$(ls $DATA_DIR)" ]; then
  (cd "$DATA_DIR"; git clone https://lab.0x972.info/gsq/files.git .)

else
  echo "INFO: data directory not empty, not cloning the repo."
fi

exit
# login:pass:Firstname Lastname:mail@addr.ess

while read line; do
  user=$(echo "$line" | cut -d: -f1)
  pass=$(echo "$line" | cut -d: -f2)
  name=$(echo "$line" | cut -d: -f3)
  mail=$(echo "$line" | cut -d: -f4)
  bin/console bolt:delete-user "$user"
  bin/console bolt:add-user --admin "$user" "$pass" "$mail" "$name"
done < users
