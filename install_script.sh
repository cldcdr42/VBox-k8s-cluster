#!/bin/bash

# ========== CONFIG ========== #

vpn_address="192.168.0.0"
name="THE NAME"
password="THE PASS"

filename="vpn_Test"

debug=1

# ========== CONFIG ========== #

#if ["ip_address" == "192.168.0.0"]; then
#    echo "ip address is the same"
#else
#    echo "ip address is different!!!"
#fi

#if [debug == 0]; then
#    echo "degug is 0"
#else
#    echo "debug is not 0"
#fi

#echo $name
#echo $password

# ==========

echo "[1/?] Updating system packages..."
apt update && apt upgrade -y
echo "[1/?] Updationg system packages... Complete!"

# ==========

echo "[2/?] Installing pptp-linux..."
apt install pptp-linux
echo "[2/?] Intsalling pptp-linux... Complete!"

# ==========

echo "[3/?] Creating PPTP VPN config file..."

cat <<EOL > /etc/ppp/peers/"$filename"
pty "pptp $vpn_address --nolaunchpppd"
name $name
password $password

noauth
defaultroute
replacedefaultroute
EOL

echo "[3/?] Creating PPTP VPN config file... Complete!"

# ==========

echo "[4/?] Installing dependencies for CRI-O and k8s..."
apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
echo "[4/?] Installing dependencies for CRI-O and k8s... Complete!"

# ==========

echo "[5/?] Disabling SWAP mechanism..."

output_SWAP=$(swapon -s)

if [-z "$output_SWAP"]; then
    echo "[5/?] Disabling SWAP mechanism... SWAP is already OFF, moving on"
else
    swapoff -a						# turn off SWAP

    echo "Removing SWAP entries from /etc/fstab..."
    cp /etc/fstab /etc/fstab.bak			# make backup before removing SWAP entries

    sed -i '/swap/d' /etc/fstab				# Remove all lines containing SWAP from file
    #echo "Current /etc/fstab content:"
    #cat /etc/fstab

    echo "[5/?] Disabling SWAP mechanism... Complete!"
fi

# ==========

echo "[6/?] Loading Network modules..."

# Add network modules for k8s into konfig file
cat <<EOL /etc/modules-load.d/k8s.conf
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
    echo "[6/?] Loading Network modules... Complete!"
else
    if [ $output_br_netfilter!=0 ]; then
        echo "br_netfilter is not loaded, check problem manually"
    fi
    if [ $output_oberlay!=0 ]; then
        echo "overlay is not loaded, check problem manually"
    fi
    echo "[6/?] [WARNING] Some network modules are not properly loaded, check logs"
fi

# ==========

echo "[7/?] Configuring network parameters..."

# Set parameters in file
cat <<EOL /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOL

# Restart Core parameters
sysctl --system

# Disabling Uncompicated Firewall
systemctl stop ufw && systemctl disable ufw

echo "[7/?] Configuring network parameters... Complete!"

# ========== FINAL

# reboot