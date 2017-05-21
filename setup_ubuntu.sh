#!/bin/bash

# Knowing the HOST_GOPATH, set up the gopath in the Guest.
# Not that this setup assumes that the HOST_GOPATH will be in the
# /Users directory tree in the host machine. The Vagrantfile sets up
# the /Users directory as a synced_folder. So the HOST_GOPATH that is under
# /Users will be visible in the Vagrant vm.
function setup_gopath() {
   local hostGopath=$1
   local guestGopath=$2
   echo "Creating a GOPATH in ${guestGopath} local to the VM..."
   # Create a gopath and symlink in the src directory. (Since we don't want to
   # share bin/ and pkg/ since they are platform dependent.)
   mkdir -p ${guestGopath}/bin ${guestGopath}/pkg
   ln -sf ${hostGopath}/src ${guestGopath}/src
   chown -R ubuntu:ubuntu ${guestGopath}
   echo "Completed GOPATH setup"
}

# There are several go install and go get's to be executed.
# Kubernetes and go development may require these.
function install_go_packages() {

   echo "Installing go packages"

   # kubernetes asks for this while building.
   # FixMe: Should we execute the following command also as vagrant or not ?
   CGO_ENABLED=0 go install -a -installsuffix cgo std

   # Install godep
   sudo -u ubuntu -E go get github.com/tools/godep
   sudo -u ubuntu -E go install github.com/tools/godep

   # Kubernetes compilation requires this
   sudo -u ubuntu -E go get -u github.com/jteeuwen/go-bindata/go-bindata

   echo "Completed install_go_packages"
}

# Install system utils
sudo apt-get update
sudo apt-get install -y gcc make socat git

# Install docker
sudo apt-get -qq install -y apt-transport-https ca-certificates
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
sudo touch /etc/apt/sources.list.d/docker.list
sudo chown -R ubuntu:ubuntu /etc/apt/sources.list.d/docker.list
sudo echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
sudo apt-get -qq update
sudo apt-get -qq install -y linux-image-extra-$(uname -r)
sudo apt-get -qq install -y docker-engine rsync make

# Install etcd
sudo curl -L https://github.com/coreos/etcd/releases/download/v3.0.17/etcd-v3.0.17-linux-amd64.tar.gz -o etcd-v3.0.17-linux-amd64.tar.gz && sudo tar xzvf etcd-v3.0.17-linux-amd64.tar.gz && sudo /bin/cp -f etcd-v3.0.17-linux-amd64/{etcd,etcdctl} /usr/bin && sudo rm -rf etcd-v3.0.17-linux-amd64*

# Install go
sudo curl -sL https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz | sudo tar -C /usr/local -zxf
HOST_GOPATH='/Users/alok87/code/go-workspace'
GUEST_GOPATH=/home/ubuntu/gopath
setup_gopath "${HOST_GOPATH}" "${GUEST_GOPATH}"
# The rest of the script installed some gobinaries. So the GOPATH needs to be known
# from this point on .
export GOPATH=${GUEST_GOPATH}
export PATH=$PATH:$GOPATH/bin:/usr/local/bin:/usr/local/go/bin/
# sudo ln -s /usr/local/go/bin/go go
install_go_packages

chown ubuntu.ubuntu /Users


