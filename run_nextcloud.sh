#! /bin/bash

mkdir -p /home/kevin/vayrac/gsq/website-bolt/data/nextcloud/{html,data,db}
(cat ../secrets/secrets-configmap.yaml; echo ---; cat config.yaml; echo ---; cat deployment-nextcloud.yaml; echo ---; cat service-nextcloud.yaml) | podman play kube -
