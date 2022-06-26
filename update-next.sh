#! /bin/bash

set -x

./run_website-next.sh --down
sudo rm -rf /data/website-next/db/
mkdir /data/website-next/db/
sudo rm -rf /data/website-next/bolt/files/
mkdir /data/website-next/bolt/files/

sudo cp -rp /data/website/db/ /data/website-next/
sudo cp -rp /data/website/bolt/files/ /data/website-next/bolt/

./run_website-next.sh
podman logs -f website-next-pod-0-cnt
