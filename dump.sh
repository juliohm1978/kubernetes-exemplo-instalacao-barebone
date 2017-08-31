apt-get install jq

rm -fr cluster-dump
mkdir cluster-dump

kubectl get --export -o=json nodes | \
jq '.items[] |
        del(.status,
        .metadata.uid,
        .metadata.selfLink,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .metadata.generation
    )' > ./cluster-dump/nodes.json

kubectl get --export -o=json ns | \
jq '.items[] |
        select(.metadata.name!="kube-system") |
        select(.metadata.name!="kube-public") |
        del(.status,
        .metadata.uid,
        .metadata.selfLink,
        .metadata.resourceVersion,
        .metadata.creationTimestamp,
        .metadata.generation
    )' > ./cluster-dump/ns.json

for ns in $(jq -r '.metadata.name' < ./cluster-dump/ns.json);do
    echo "Namespace: $ns"
    kubectl --namespace="${ns}" get --export -o=json serviceaccounts,clusterroles,roles,clusterrolebindings,rolebindings,storageclasses,resourcequotas,limits,networkpolicies,configmaps,pv,pvc,secrets,svc,deployments,statefulsets,replicationcontrollers,daemonset,jobs,ingress | \
    jq '.items[] |
        select(.type!="kubernetes.io/service-account-token") |
        del(
            .spec.clusterIP,
            .metadata.uid,
            .metadata.selfLink,
            .metadata.resourceVersion,
            .metadata.creationTimestamp,
            .metadata.generation,
            .status,
            .spec.template.spec.securityContext,
            .spec.template.spec.dnsPolicy,
            .spec.template.spec.terminationGracePeriodSeconds,
            .spec.template.spec.restartPolicy
        )' >> "./cluster-dump/cluster-dump.json"
done

