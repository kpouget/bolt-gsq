#! /bin/bash

for d in $(cat deployment-bolt.yaml | grep 'hostpath' -A1 | grep -v hostpath | grep path | cut -d: -f2);
do
    mkdir $d -p
done

(cat ../secrets/secrets-configmap.yaml; echo ---; cat config.yaml; echo ---; cat deployment-bolt.yaml) | podman play kube - "$@"
