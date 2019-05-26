# k3snode
image for k3s(lightweight k8s) node

1.You can use this image by run: dokcer run --privileged -e K3S_KUBECONFIG_OUTPUT=/kubeconfigfilewithabsolutepath -e K3S_KUBECONFIG_MODE=666 -v temporary_dir:/wheretoputkubeconfigfile -p 6443:6443 cliu2/k3snode:version docker kill -s SIGUSR1 container_id or container_name

2.Afer the container is starting, run nohup /bin/k3s server & to initilize the container as one master && agent

3.To deploy one deployment run: k3s kubectl run nginx --image=nginx --expose=true --hostport=8082 --port=80 then you can access the nginx by typing "ip:hostport" on other nodes. Notice that docke should expose the port 8082 to the host, here for example should add '-p 8082:8082‘ to docker run command
