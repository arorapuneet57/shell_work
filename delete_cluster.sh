export PATH="/home/vagrant/bin:/home/vagrant/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/go/bin:/snap/bin"
source /etc/environment
CLUSTER_API_PATH="/home/vagrant/clusterapi"
check_if_kind_cluster_exists()
{
   c="$(kind get clusters)"
   if [ "$c" != "" ]; then 
       kind delete cluster --name=clsuterapi
       exit
   else 
       return 1
   fi
}

check_if_kind_cluster_exists
if [ "$?" == 1 ]; then
   kubectl delete -f "$CLUSTER_API_PATH"/out/workload-cluster-test/addons.yaml
   export KUBECONFIG="$HOME/clusterapi/out/management-cluster-test/kubeconfig"
   kubectl delete -f "$CLUSTER_API_PATH"/out/workload-cluster-test/cluster.yaml
   kubectl delete -f "$CLUSTER_API_PATH"/out/workload-cluster-test/machines.yaml
   kubectl delete -f "$CLUSTER_API_PATH"/out/management-cluster-test/addons.yaml
   kubectl delete -f "$CLUSTER_API_PATH"/out/management-cluster-test/machines.yaml
   kubectl delete -f "$CLUSTER_API_PATH"/out/management-cluster-test/cluster.yaml
fi
