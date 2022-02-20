oc apply -f namespace.yaml
for i in deployment.yaml issuer-letsencrypt-live.yaml serviceaccount.yaml clusterrole.yaml; 
  do oc apply -f $i 
done
oc create clusterrolebinding openshift-acme --clusterrole=openshift-acme --serviceaccount=openshift-acme:openshift-acme --dry-run=client -o yaml | oc apply -f -
