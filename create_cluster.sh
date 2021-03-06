#!/bin/bash
pwd=$HOME
export PATH="/home/vagrant/bin:/home/vagrant/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/go/bin:/snap/bin"
source /etc/environment
OUTPUT_PATH="/home/vagrant/output.txt"
OUTPUT_PATH1="/home/vagrant/output1.txt"
CLUSTER_API_PATH="/home/vagrant/clusterapi"
SCRIPT_PATH="/home/vagrant/clusterapi/clusterctl"
cd $HOME/clusterapi
# create machines.yaml for management cluster based on envvars.txt file
docker run --rm   -v "$CLUSTER_API_PATH":/out  -v "$CLUSTER_API_PATH/envvars.txt":/envvars.txt:ro gcr.io/cluster-api-provider-vsphere/ci/manifests:v0.4.2-beta.0-4-g64f7a3b6   -c management-cluster-test -f
sleep 20
if [ -e $HOME/dhcp_disabled ]; then 
   cp $HOME/machine_non_dhcp.yaml $CLUSTER_API_PATH/out/management-cluster-test/machines.yaml
fi

sed -i 's/gcr.io\/cluster-api-provider-vsphere\/ci\/manager:v0.4.2-beta.0-4-g64f7a3b6/akutz\/capv-0.4-no-cri-socket:latest/' $CLUSTER_API_PATH/out/management-cluster-test/provider-components.yaml
# Create management cluster
eval '"$SCRIPT_PATH" create cluster   -a "$CLUSTER_API_PATH"/out/management-cluster-test/addons.yaml   -c "$CLUSTER_API_PATH"/out/management-cluster-test/cluster.yaml   -m "$CLUSTER_API_PATH"/out/management-cluster-test/machines.yaml   -p "$CLUSTER_API_PATH"/out/management-cluster-test/provider-components.yaml   --kubeconfig-out "$CLUSTER_API_PATH"/out/management-cluster-test/kubeconfig   --provider vsphere   --bootstrap-type kind   -v 6 2> "$OUTPUT_PATH1"'

sleep 200

cd $HOME/clusterapi
# create machines.yaml for workload cluster based on envvars.txt file
docker run --rm -v "$(pwd)":/out -v "$(pwd)/envvars.txt":/envvars.txt:ro gcr.io/cluster-api-provider-vsphere/ci/manifests:v0.4.2-beta.0-4-g64f7a3b6 -c workload-cluster-test -f
if [ -e $HOME/dhcp_disabled ]; then         
   cp $HOME/worker_machine_non_dhcp.yaml $CLUSTER_API_PATH/out/workload-cluster-test/machines.yaml
fi
sleep 20
# Create workload machines and create calico
export KUBECONFIG="$HOME/clusterapi/out/management-cluster-test/kubeconfig"
kubectl apply -f "$CLUSTER_API_PATH"/out/workload-cluster-test/cluster.yaml
kubectl apply -f "$CLUSTER_API_PATH"/out/workload-cluster-test/machines.yaml
kubectl apply -f "$CLUSTER_API_PATH"/out/workload-cluster-test/addons.yaml
#echo "controller applied " 2>> "$OUTPUT_PATH"
sleep 1000
kubectl get secret workload-cluster-test-kubeconfig -o=jsonpath='{.data.value}' | { base64 -d 2>/dev/null || base64 -D; } >"$CLUSTER_API_PATH"/out/workload-cluster-test/kubeconfig
sleep 5
export KUBECONFIG="$HOME/clusterapi/out/workload-cluster-test/kubeconfig"
kubectl apply -f "$CLUSTER_API_PATH"/out/workload-cluster-test/addons.yaml

rm -rf $HOME/dhcp_disabled
