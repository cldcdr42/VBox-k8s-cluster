#!/bin/bash

# ========== CONFIG - start ========== #

vpn_address="192.168.0.0"
name="student42"

# MAKE SURE TO PUT BACKSLASH \ BEFORE $ SIGNS IN PASSWORDS
# BAD:   password="124$23"
# GOOD:  password="124\$23"
password="O\$dw"
filename="vpn_PPTP"

OS="xUbuntu_22.04"
VERSION="1.25"

# ========== CONFIG - end ========== #

echo "[1/10] Updating system packages..."
apt update && apt upgrade -y
echo "[1/10] Updationg system packages... Complete!"

# ==========

echo "[2/10] Installing pptp-linux..."
apt install pptp-linux
echo "[2/10] Intsalling pptp-linux... Complete!"

# ==========

echo "[3/10] Creating PPTP VPN config file..."

cat <<EOL > /etc/ppp/peers/"$filename"
pty "pptp $vpn_address --nolaunchpppd"
name $name
password $password

noauth
defaultroute
replacedefaultroute
EOL

echo "[3/10] Creating PPTP VPN config file... Complete!"

# ==========

echo "[4/10] Installing dependencies for CRI-O and k8s..."
apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
echo "[4/10] Installing dependencies for CRI-O and k8s... Complete!"

# ==========

echo "[5/10] Disabling SWAP mechanism..."

output_SWAP=$(swapon -s)

if [-z "$output_SWAP"]; then
    echo "[5/10] Disabling SWAP mechanism... SWAP is already OFF, moving on"
else
    swapoff -a						# turn off SWAP

    echo "Removing SWAP entries from /etc/fstab..."
    cp /etc/fstab /etc/fstab.bak			# make backup before removing SWAP entries

    sed -i '/swap/d' /etc/fstab				# Remove all lines containing SWAP from file
    #echo "Current /etc/fstab content:"
    #cat /etc/fstab

    echo "[5/10] Disabling SWAP mechanism... Complete!"
fi

# ==========

echo "[6/10] Loading Network modules..."

# Add network modules for k8s into konfig file
cat <<EOL > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOL

# Load network modules
modprobe overlay
modprobe br_netfilter

# Check if modules are properly loaded:
output_br_netfilter=$(lsmod | egrep "br_netfilter" | sed '1q;d' | awk '{print $3}')
output_overlay=$(lsmod | egrep "overlay" | awk '{print $3}')

if [ $output_br_netfilter==0 ] && [ $output_overlay==0 ]; then
    echo "br_netfilter and overlay are loaded"
    echo "[6/10] Loading Network modules... Complete!"
else
    if [ $output_br_netfilter!=0 ]; then
        echo "br_netfilter is not loaded, check problem manually"
    fi
    if [ $output_oberlay!=0 ]; then
        echo "overlay is not loaded, check problem manually"
    fi
    echo "[6/10] [WARNING] Some network modules are not properly loaded, check logs"
fi

# ==========

echo "[7/10] Configuring network parameters..."

# Set parameters in file
cat <<EOL > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOL

# Restart Core parameters
sysctl --system

# Disabling Uncompicated Firewall
systemctl stop ufw && systemctl disable ufw

echo "[7/10] Configuring network parameters... Complete!"

# ==========

echo "[8/10] Installing CRI-O..."

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

sudo apt-get update
sudo apt-get install cri-o cri-o-runc cri-tools -y

systemctl start crio && systemctl enable crio
#systemctl status crio

echo "[8/10] Installing CRI-O... Complete!"

# ==========

echo "[9/10] Installing k8s packages..."

apt update && apt install -y apt-transport-https ca-certificates curl gpg

if [ ! -d "/etc/apt/keyrings" ]; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
fi

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

apt update && apt install -y kubelet kubeadm kubectl && apt-mark hold kubelet kubeadm kubectl

echo "[9/10] Installing k8s packages... Complete!"

# ==========

echo "[10/10] Installation script is complete, reboot the system"
#reboot
