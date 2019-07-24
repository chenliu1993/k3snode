# k3snode
image for k3s(lightweight k8s) node

1.To pull this image if you don't want to build locally, run 'docker pull cliu2/k3snode'

2.You can use this image by run: docker run --privileged -e K3S_KUBECONFIG_OUTPUT=/kubeconfigfilewithabsolutepath -e K3S_KUBECONFIG_MODE=666 -v temporary_dir:/wheretoputkubeconfigfile -p 6443:6443 cliu2/k3snode:version 

like:
docker run --privileged -e K3S_KUBECONFIG_OUTPUT=/home/cliu2/Documents/docker/src/tmp/output/kubeconfig.yaml -e K3S_KUBECONFIG_MODE=666 -v /home/cliu2/Documents/docker/src/tmp/tmp:/var/lib/rancher/k3s -p 6444:6443 -d cliu2/k3snode:v0.4

3.Afer the container is starting, run nohup /bin/k3s server & to initilize the container as one master && agent

4.To deploy one deployment run: k3s kubectl run nginx --image=nginx --expose=true --hostport=8082 --port=80 then you can access the nginx by typing "ip:hostport" on other nodes. Notice that docke should expose the port 8082 to the host, here for example should add '-p 8082:8082‘ to docker run command

Notice: while initlize node container, there are some errors output which do not affect the process. Next move to reduce the errors.
