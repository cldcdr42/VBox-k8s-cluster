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
apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common
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
    echo "Current /etc/fstab content:"
    cat /etc/fstab
    
    echo "[5/?] Disabling SWAP mechanism... Complete!"
fi

# ==========