######## Edit before running!

export MASTER_IP=<master node's private ip>
export PUBLIC_AGENT_IP=<public agent's public ip>

[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.12/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos &&
dcos cluster setup --insecure https://${MASTER_IP} &&
dcos

dcos package install --yes dcos-enterprise-cli
mkdir ~/mke && cd $_ 
dcos security org service-accounts keypair mke-priv.pem mke-pub.pem 
dcos security org service-accounts create -p ~/mke/mke-pub.pem -d 'MKE service account' kubernetes 
dcos security org service-accounts create -p ~/mke/mke-pub.pem -d 'MKE service account' kubernetes 
dcos security secrets create-sa-secret ~/mke/mke-priv.pem kubernetes kubernetes/sa
dcos security org users grant kubernetes dcos:mesos:master:reservation:role:kubernetes-role create 
dcos security org users grant kubernetes dcos:mesos:master:framework:role:kubernetes-role create 
dcos security org users grant kubernetes dcos:mesos:master:task:user:nobody create
cat <<EOF >mke-options.json
{
  "service": {
    "service_account": "kubernetes",
    "service_account_secret": "kubernetes/sa"
  }
}
EOF
dcos package install --yes --options=~/mke/mke-options.json kubernetes

mkdir -p ~/mke/k8s-one && cd $_
dcos security org service-accounts keypair kube1-priv.pem kube1-pub.pem 
dcos security org service-accounts create -p kube1-pub.pem -d 'k8s-one service account' k8s-one 
dcos security secrets create-sa-secret kube1-priv.pem k8s-one k8s-one/sa
dcos security org users grant k8s-one dcos:mesos:master:framework:role:k8s-one-role create 
dcos security org users grant k8s-one dcos:mesos:master:task:user:root create 
dcos security org users grant k8s-one dcos:mesos:agent:task:user:root create 
dcos security org users grant k8s-one dcos:mesos:master:reservation:role:k8s-one-role create 
dcos security org users grant k8s-one dcos:mesos:master:reservation:principal:k8s-one delete 
dcos security org users grant k8s-one dcos:mesos:master:volume:role:k8s-one-role create 
dcos security org users grant k8s-one dcos:mesos:master:volume:principal:k8s-one delete 
dcos security org users grant k8s-one dcos:secrets:default:/k8s-one/* full 
dcos security org users grant k8s-one dcos:secrets:list:default:/k8s-one read 
dcos security org users grant k8s-one dcos:adminrouter:ops:ca:rw full 
dcos security org users grant k8s-one dcos:adminrouter:ops:ca:ro full 
dcos security org users grant k8s-one dcos:mesos:master:framework:role:slave_public/k8s-one-role create 
dcos security org users grant k8s-one dcos:mesos:master:framework:role:slave_public/k8s-one-role read 
dcos security org users grant k8s-one dcos:mesos:master:reservation:role:slave_public/k8s-one-role create 
dcos security org users grant k8s-one dcos:mesos:master:volume:role:slave_public/k8s-one-role create 
dcos security org users grant k8s-one dcos:mesos:master:framework:role:slave_public read 
dcos security org users grant k8s-one dcos:mesos:agent:framework:role:slave_public read
cat <<EOF >k8s-one-options.json
{
  "service": {
    "name": "k8s-one",
    "service_account": "k8s-one",
    "service_account_secret": "k8s-one/sa"
  }
}
EOF
dcos kubernetes cluster create --options=k8s-one-options.json --yes

mkdir -p ~/mke/k8s-two && cd $_
dcos security org service-accounts keypair kube2-priv.pem kube2-pub.pem 
dcos security org service-accounts create -p kube2-pub.pem -d 'k8s-one service account' k8s-two 
dcos security secrets create-sa-secret kube2-priv.pem k8s-two k8s-two/sa
dcos security org users grant k8s-two dcos:mesos:master:framework:role:k8s-two-role create 
dcos security org users grant k8s-two dcos:mesos:master:task:user:root create 
dcos security org users grant k8s-two dcos:mesos:agent:task:user:root create 
dcos security org users grant k8s-two dcos:mesos:master:reservation:role:k8s-two-role create 
dcos security org users grant k8s-two dcos:mesos:master:reservation:principal:k8s-two delete 
dcos security org users grant k8s-two dcos:mesos:master:volume:role:k8s-two-role create 
dcos security org users grant k8s-two dcos:mesos:master:volume:principal:k8s-two delete
dcos security org users grant k8s-two dcos:secrets:default:/k8s-two/* full 
dcos security org users grant k8s-two dcos:secrets:list:default:/k8s-two read 
dcos security org users grant k8s-two dcos:adminrouter:ops:ca:rw full 
dcos security org users grant k8s-two dcos:adminrouter:ops:ca:ro full 
dcos security org users grant k8s-two dcos:mesos:master:framework:role:slave_public/k8s-two-role create 
dcos security org users grant k8s-two dcos:mesos:master:framework:role:slave_public/k8s-two-role read 
dcos security org users grant k8s-two dcos:mesos:master:reservation:role:slave_public/k8s-two-role create 
dcos security org users grant k8s-two dcos:mesos:master:volume:role:slave_public/k8s-two-role create 
dcos security org users grant k8s-two dcos:mesos:master:framework:role:slave_public read 
dcos security org users grant k8s-two dcos:mesos:agent:framework:role:slave_public read
cat <<EOF >k8s-two-options.json
{
  "service": {
    "name": "k8s-two",
    "service_account": "k8s-two",
    "service_account_secret": "k8s-two/sa"
  }
}
EOF
dcos kubernetes cluster create --options=k8s-two-options.json --yes

dcos package install --yes marathon-lb
cd ~/mke
cat <<EOF >marathon-lb-k8s-one.json
{
   "id": "/marathon-lb-k8s-one",
   "instances": 1,
   "cpus": 0.001,
   "mem": 16,
   "cmd": "tail -F /dev/null",
   "container": {
     "type": "MESOS"
   },
   "portDefinitions": [
     {
       "protocol": "tcp",
       "port": 0
     }
   ],
   "labels": {
     "HAPROXY_GROUP": "external",
     "HAPROXY_0_MODE": "http",
     "HAPROXY_0_PORT": "6443",
     "HAPROXY_0_SSL_CERT": "/etc/ssl/cert.pem",
     "HAPROXY_0_BACKEND_SERVER_OPTIONS": "  timeout connect 10s\n  timeout client 86400s\n  timeout server 86400s\n  timeout tunnel 86400s\n  server k8s-one apiserver.k8s-one.l4lb.thisdcos.directory:6443 ssl verify none\n"
   }
 }
EOF
dcos marathon app add ~/mke/marathon-lb-k8s-one.json
cat <<EOF >marathon-lb-k8s-two.json
{
   "id": "/marathon-lb-k8s-two",
   "instances": 1,
   "cpus": 0.001,
   "mem": 16,
   "cmd": "tail -F /dev/null",
   "container": {
     "type": "MESOS"
   },
   "portDefinitions": [
     {
       "protocol": "tcp",
       "port": 0
     }
   ],
   "labels": {
     "HAPROXY_GROUP": "external",
     "HAPROXY_0_MODE": "http",
     "HAPROXY_0_PORT": "6444",
     "HAPROXY_0_SSL_CERT": "/etc/ssl/cert.pem",
     "HAPROXY_0_BACKEND_SERVER_OPTIONS": "  timeout connect 10s\n  timeout client 86400s\n  timeout server 86400s\n  timeout tunnel 86400s\n  server k8s-two apiserver.k8s-two.l4lb.thisdcos.directory:6443 ssl verify none\n"
   }
 }
EOF
dcos marathon app add ~/mke/marathon-lb-k8s-two.json
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl 
chmod +x kubectl 
sudo mv kubectl /usr/local/bin/kubectl
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=k8s-one --cluster-name=k8s-one --apiserver-url=https://${PUBLIC_AGENT_IP}:6443
kubectl get nodes
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=k8s-two --cluster-name=k8s-two --apiserver-url=https://${PUBLIC_AGENT_IP}:6444
kubectl get nodes
kubectl config use-context k8s-one 
