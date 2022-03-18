DB_POD_NAME=$(oc get pods -lapp=db -oname)
BOLT_POD_NAME=$(oc get pods -lapp=website -oname)

DB_FILENAME=secrets/bolt_gsq.sql
POD_DATA_DIR=public/files

PASS=$(cat secrets/secrets.yaml | grep DATABASE_PASSWORD | awk '{printf $2 }')

oc rsh $DB_POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq" <<< "SET FOREIGN_KEY_CHECKS=0;$(cat "$DB_FILENAME" | grep 'ALTER TABLE' | sed 's/ALTER TABLE/DROP TABLE IF EXISTS/' | sed 's/$/;/');SET FOREIGN_KEY_CHECKS=1;"

oc rsh $DB_POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq" < "$DB_FILENAME"
oc rsh $DB_POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq -e 'SHOW tables;'"
oc rsh $DB_POD_NAME bash -c "mysql -u bolt-gsq -p$PASS bolt-gsq -e 'SELECT * FROM bolt_user;'"

oc rsh "$BOLT_POD_NAME" bash -c "cd $POD_DATA_DIR && git clone https://lab.0x972.info/gsq/files.git ."

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
