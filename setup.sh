#!/usr/bin/env bash

: "${GITHUB_USER_REPO:=yifei0727}"
export GITHUB_USER_REPO

sudo apt update && sudo apt upgrade -y && sudo apt autoremove --purge -y && sudo apt autoclean -y
sudo apt install -y libpam-google-authenticator ufw zerotier-one jq curl docker.io docker-compose-v2

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
  # /etc/pam.d/sshd
  # auth	required	pam_google_authenticator.so nullok
  # # @include common-auth
  sed  -r '/^@include[[:space:]]+common-auth/ {
        /pam_google_authenticator.so/! {
            i \
'"auth required pam_google_authenticator.so nullok"'
        }
    }
    /^[[:space:]]*@include[[:space:]]+common-auth/ {
        /^[^#]/ s/^/#/
    }
' /etc/pam.d/sshd
}

function update_hostname() {
  HOSTNAME="$(ip link | grep zt | awk -F ':' '{print $2}' | xargs -n1 ifconfig | grep 'inet ' | awk '{print $2}' | awk -F. '{printf "%02d-%02d-%02d-%02d", $1, $2, $3, $4}')"
  hostnamectl set-hostname $HOSTNAME
  sed -i -E "/^(127\.0\.0\.1|::1)[[:space:]]/ { /$HOSTNAME/! s/$/ $HOSTNAME/ }" /etc/hosts
}

function prepare_env() {
  cat >/etc/profile.d/node-env.sh <<EOF
export ZT_HOST=\$(ip link | grep zt | awk -F ':' '{print \$2}' | xargs ifconfig | grep 'inet 10.'| awk '{print \$2}')
EOF
 chmod +x /etc/profile.d/node-env.sh
}

modify_sysctl_config() {
    CONFIG_FILE="$1"
    local key_value="$2"
    if [[ -z "$1" || -z "$2" ]];then
      echo "usage [configFile] [property]"
      return 1
    fi

    local config_key=$(echo "$key_value" | cut -d'=' -f1) # net.ipv4.ip_forward
    local config_value=$(echo "$key_value" | cut -d'=' -f2) # 1

    echo -e "\n--- ⚙️ 处理配置项: ${key_value} ---"

    # 1. 检查未被注释的配置是否存在
    # 使用 -E 启用扩展正则，匹配可选的行首空格，后跟完整的 key=value
    if grep -qE "^[[:space:]]*${key_value}[[:space:]]*$" "$CONFIG_FILE"; then
        echo "✅ ${key_value} 已经存在且未被注释，无需修改。"

    # 2. 检查被注释的配置是否存在
    # 匹配可选的行首空格，后跟 #，后跟可选的任何字符，后跟完整的 key=value
    elif grep -qE "^[[:space:]]*#.*${key_value}[[:space:]]*$" "$CONFIG_FILE"; then
        echo "⚠️ 发现被注释的 ${key_value}，正在取消注释..."
        # sed: 找到匹配的行，执行 s 命令（替换）：将行首可选空格和 # 替换为空
        sed -i "/^[[:space:]]*#.*${key_value}[[:space:]]*$/s/^[[:space:]]*#//" "$CONFIG_FILE"
        echo "✅ 已取消注释。"

    # 3. 以上均不存在，则在文件末尾添加
    else
        echo "➕ 未发现 ${key_value}，正在文件末尾添加..."
        echo "${key_value}" >> "$CONFIG_FILE"
        echo "✅ 已添加。"
    fi
}


function init_ufw() {
  # /etc/default/ufw
  # DEFAULT_FORWARD_POLICY="ACCEPT"
  # /etc/ufw/sysctl.conf
  # Uncomment this to allow this host to route packets between interfaces
  #net/ipv4/ip_forward=1
  #net/ipv6/conf/default/forwarding=1
  #net/ipv6/conf/all/forwarding=1
  modify_sysctl_config /etc/default/ufw 'DEFAULT_FORWARD_POLICY="ACCEPT"'
  modify_sysctl_config /etc/ufw/sysctl.conf 'net/ipv4/ip_forward=1'
  modify_sysctl_config /etc/ufw/sysctl.conf 'net/ipv6/conf/default/forwarding=1'
  modify_sysctl_config /etc/ufw/sysctl.conf 'net/ipv6/conf/all/forwarding=1'

for ethname in $(ip link | grep zt | awk -F ':' '{print $2}')
do
  cat >>/etc/ufw/before.rules <<EOF
#
*mangle
:PREROUTING ACCEPT [0:0]
-A PREROUTING -i $ethname -j MARK --set-mark 0x10
COMMIT
EOF
  ufw allow in on $ethname
done

cat >>/etc/ufw/before.rules <<EOF
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -m mark --mark 0x10 -o eth0 -j MASQUERADE
COMMIT
EOF

cat >/etc/ufw/applications.d/zerotier <<EOF
[ZeroTier]
title=Zerotier Edge
description=zerotier node
ports=9993/tcp|9993/udp
EOF

cat >/etc/ufw/applications.d/kcptun <<EOF
[KcpTun]
title=kcp over udp
description=kcp tun server
ports=5940/udp
EOF

SSH_ALLOW="22505/tcp|22505/udp"
sed -i "s#^\(ports=\).*#\1$SSH_ALLOW#g" /etc/ufw/applications.d/openssh-server
}

install_ssh_keys
install_zerotier

# wait for user confirmation that ZeroTier interface has an IP address
while true; do
  read -r -p "Confirm ZeroTier interface has an IP assigned? (y/yes to continue or exit abort): " ans
  case "${ans,,}" in
    y|yes) break ;;
    exit) echo "Aborting. Assign IP and re-run."; exit 1 ;;
    *) echo "Please enter y/yes to continue or n/no to abort." ;;
  esac
done

prepare_env
update_hostname
setup_2fa

# 将ssh 服务默认 22 修改为 22505
sed -i '/^\s*Port\s\+22\s*$/s/^\s*#*/#/' /etc/ssh/sshd_config
sed -i '/^\s*#\s*Port\s\+22\s*$/a Port 22505' /etc/ssh/sshd_config
# 获取本地出口网卡
out_net_interface=$(ip route | grep "default via" | awk '{print $5}')
# 替换 before.rules 中的 eth0 为实际网卡名
sed -i "s/-o eth0/-o $out_net_interface/g" /etc/ufw/before.rules
#
systemctl restart ssh.service
systemctl enable ufw.service
systemctl start ufw.service
