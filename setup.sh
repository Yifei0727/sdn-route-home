#!/usr/bin/env bash

sudo apt update && sudo apt upgrade -y && sudo apt autoremove --purge -y && sudo apt autoclean -y
sudo apt install -y libpam-google-authenticator ufw supervisor dnsmasq zerotier-one docker.io

curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
zerotier-cli join 0e97d9fcc1125072
zerotier-cli orbit 0e97d9fcc1 0e97d9fcc1

google-authenticator -t -f -d -w 3 -e 10 -r 3 -R 30

# 将ssh 服务默认 22 修改为 22505
sed -i '/^\s*Port\s\+22\s*$/s/^\s*#*/#/' /etc/ssh/sshd_config
sed -i '/^\s*#\s*Port\s\+22\s*$/a Port 22505' /etc/ssh/sshd_config
cp -ar daemon /
cp -ar etc /
#
systemctl restart ssh.service
systemctl enable dnsmasq.service
systemctl start dnsmasq.service
systemctl enable ufw.service
systemctl start ufw.service

echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAynPsgxb9us6N3m+ZYylYHp+y/Ci10Dxcj+Mx9FtSGALerEsSTA/9lm/j6JQyP3lxc4G12HIGgUJFbGRL4t1AvFXw5LmWfCnrahq1qnG1/ASEQRgkwPPaZmrnDG7o6mdcENrC20A85zQgHXQy2WkvFWQfJD6CsbMv9N4/17OxWvxYQmA0uI1ZrGlGsCqYSJT4c6DvTvtZLTyp44aHWB4ou4ZRLTZGcNmeI4u1u2MEnI1a1oEK6e9RTC6+zejJLLH4rLw2WurtTkVdhZrbQl3aHXeWbNhDqQuYzPh4qEccz9CQ37mUYXjuWHkygq0rXaMFNxE6tMq85cJLNS1iYY1npw== rsa 2048-091822' >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys