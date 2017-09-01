
for pvname in $(kubectl get pv -o json | jq '.items[].metadata.name' | sed 's/"//g'); do
  pvc=$(kubectl get pv $pvname -o json | jq '.spec.claimRef.name' | sed 's/"//g')
  pvcns=$(kubectl get pv $pvname -o json | jq '.spec.claimRef.namespace' | sed 's/"//g')
  pvcid=$(kubectl get pvc -n $pvcns $pvc -o json | jq '.metadata.uid' | sed 's/"//g')

  echo "$pvname > $pvcns/$pvc/$pvcid"

  kubectl patch pv $pvname -p "{\"spec\": {\"claimRef\": {\"uid\": \"$pvcid\"}}}"

done
