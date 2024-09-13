# Update the system
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y

# Create a new user and add to sudo group
# sudo adduser newuser
sudo usermod -aG sudo david

# Install K3s
curl -sfL https://get.k3s.io | sh -

# Ensure K3s has access to all disk space
# Assuming you want to use a specific directory for K3s data, e.g., /var/lib/rancher/k3s
# Make sure the directory exists and has the correct permissions
sudo mkdir -p /var/lib/rancher/k3s
sudo chown -R root:root /var/lib/rancher/k3s

# Optionally, you can mount additional disk space to /var/lib/rancher/k3s if needed
# For example, if you have an additional disk at /dev/sdb1
lsblk
sudo fdisk -l
sudo mkfs.ext4 /dev/sda1
sudo mount /dev/sdb1 /var/lib/rancher/k3s
echo '/dev/sda1 /var/lib/rancher/k3s ext4 defaults 0 0' | sudo tee -a /etc/fstab

df -h /var/lib/rancher/k3s
mount | grep /var/lib/rancher/k3s


# Verify K3s installation
sudo k3s kubectl get nodes

# Retrieve kubeconfig file


# sudo cp /etc/rancher/k3s/k3s.yaml /home/newuser/.kube/config
# sudo chown newuser:newuser /home/newuser/.kube/config

# Print instructions for using the kubeconfig file
echo "To use kubectl with your K3s cluster, run the following command:"

sudo cat /etc/rancher/k3s/k3s.yaml
## copy to local machine or dotfiles
echo "export KUBECONFIG=~/.kube/config"