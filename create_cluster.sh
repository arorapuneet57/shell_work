# create machines.yaml for management cluster based on envvars.txt file
#pwd=$HOME
#docker run --rm   -v "$(pwd)":/out   -v "$(pwd)/envvars.txt":/envvars.txt:ro   gcr.io/cluster-api-provider-vsphere/ci/manifests:v0.4.2-beta.0-4-g64f7a3b6   -c management-cluster-test

# Create management cluster
cd $HOME/clusterapi
echo "here I go"
./clusterctl create cluster   -a ./out/management-cluster-test/addons.yaml   -c ./out/management-cluster-test/cluster.yaml   -m ./out/management-cluster-test/machines.yaml   -p ./out/management-cluster-test/provider-components.yaml   --kubeconfig-out ./out/management-cluster-test/kubeconfig   --provider vsphere   --bootstrap-type kind   -v 6
echo "here I go 2 time"
sleep 200

# create machines.yaml for workload cluster based on envvars.txt file
#docker run --rm -v "$(pwd)":/out -v "$(pwd)/envvars.txt":/envvars.txt:ro gcr.io/cluster-api-provider-vsphere/ci/manifests:v0.4.2-beta.0-4-g64f7a3b6 -c workload-cluster-test

# Create workload machines and create calico
export KUBECONFIG="$HOME/clusterapi/out/management-cluster-test/kubeconfig"
kubectl apply -f ./out/workload-cluster-test/cluster.yaml
kubectl apply -f ./out/workload-cluster-test/machines.yaml
kubectl apply -f ./out/workload-cluster-test/addons.yaml
sleep 600
kubectl get secret workload-cluster-test-kubeconfig -o=jsonpath='{.data.value}' | { base64 -d 2>/dev/null || base64 -D; } >./out/workload-cluster-test/kubeconfig
export KUBECONFIG="$HOME/clusterapi/out/workload-cluster-test/kubeconfig"
kubectl apply -f ./out/workload-cluster-test/addons.yaml
sleep 200


# delete the cluster using kubctl command
#kubectl delete -f ./out/workload-cluster-test/addons.yaml
#export KUBECONFIG="$HOME/clusterapi/out/management-cluster-test/kubeconfig"
#kubectl delete -f ./out/workload-cluster-test/cluster.yaml
#kubectl delete -f ./out/workload-cluster-test/machines.yaml
#kubectl delete -f ./out/management-cluster-test/addons.yaml
#kubectl delete -f ./out/management-cluster-test/machines.yaml
#kubectl delete -f ./out/management-cluster-test/cluster.yaml
#kind delete cluster --name=clusterapi
#kubectl get clusters
