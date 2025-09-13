#!/usr/bin/env bash

: "${GITHUB_USER_REPO:=yifei0727}"
export GITHUB_USER_REPO

sudo apt update && sudo apt upgrade -y && sudo apt autoremove --purge -y && sudo apt autoclean -y
sudo apt install -y libpam-google-authenticator ufw supervisor dnsmasq zerotier-one docker.io jq curl

function install_ssh_keys() {
  mkdir -p   ~/.ssh/
  chmod 0700 ~/.ssh
  chmod 0600 ~/.ssh/authorized_keys
  curl -s https://api.github.com/users/${GITHUB_USER_REPO}/keys | jq -r '.[] | .key' | \
  while read -r key; do
      if ! grep -qF "${key}" ~/.ssh/authorized_keys; then
          echo "${key}" >> ~/.ssh/authorized_keys
          echo "Added key: ${key}"
      else
          echo "Key already exists: ${key}"
      fi
  done
}

function install_zerotier() {
  curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
  zerotier-cli join 0e97d9fcc1125072
  zerotier-cli orbit 0e97d9fcc1 0e97d9fcc1
}

function setup_2fa() {
  google-authenticator -t -f -d -w 3 -e 10 -r 3 -R 30
}

function update_hostname() {
  HOSTNAME="$(ip link | grep zt | awk -F ':' '{print $2}' | xargs -n1 ifconfig | grep 'inet ' | awk '{print $2}' | awk -F. '{printf "%02d-%02d-%02d-%02d", $1, $2, $3, $4}')"
  hostnamectl set-hostname $HOSTNAME
  echo "\n127.0.0.1 $HOSTNAME" >> /etc/hosts
}

install_ssh_keys
install_zerotier
setup_2fa
update_hostname

# 将ssh 服务默认 22 修改为 22505
sed -i '/^\s*Port\s\+22\s*$/s/^\s*#*/#/' /etc/ssh/sshd_config
sed -i '/^\s*#\s*Port\s\+22\s*$/a Port 22505' /etc/ssh/sshd_config
cp -ar etc /
# 获取本地出口网卡
out_net_interface=$(ip route | grep "default via" | awk '{print $5}')
# 替换 before.rules 中的 eth0 为实际网卡名
sed -i "s/-o eth0/-o $out_net_interface/g" /etc/ufw/before.rules
#
systemctl restart ssh.service
systemctl enable dnsmasq.service
systemctl start dnsmasq.service
systemctl enable ufw.service
systemctl start ufw.service

docker login ghcr.io
docker pull ghcr.io/${GITHUB_USER_REPO}/ss-overkcp
docker run --name kcptun_ss \
  -e SSS_PASSWORD=u18681@weixin \
  -p 5940:5940/udp  \
  -d \
  ghcr.io/${GITHUB_USER_REPO}/ss-overkcp