#yum install -y yum-utils device-mapper-persistent-data lvm2
tdnf install docker -y
systemctl start docker
systemctl enable docker
tdnf install git -y
mkdir -p /NetApp/scripts
git clone https://github.com/kpapreck/test-plan
