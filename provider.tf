provider "zedcloud" {
    zedcloud_url = "https://zedcontrol.zededa.net" #### Pick the cluster where you will be executing these commands against.
  # Configuration options
    zedcloud_token = "<your_zedcloud_token>"
}




#provider "proxmox" {
#  endpoint      = "https://192.168.1.10:8006"
#  username = "root@pam"
#  password = "Miquinhas.40"  
      
#  insecure = true # Set to true if using self-signed certificates
#}