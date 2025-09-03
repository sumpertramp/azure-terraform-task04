# ===============================
# Task 04 - terraform.tfvars
# ===============================

# Zorunlu isimler (Task parameters)
rg_name             = "cmaz-vf06h1cc-mod4-rg"
vnet_name           = "cmaz-vf06h1cc-mod4-vnet"
subnet_name         = "frontend"
nic_name            = "cmaz-vf06h1cc-mod4-nic"
nsg_name            = "cmaz-vf06h1cc-mod4-nsg"
nsg_rule_http_name  = "AllowHTTP"
nsg_rule_ssh_name   = "AllowSSH"
public_ip_name      = "cmaz-vf06h1cc-mod4-pip"
dns_label           = "cmaz-vf06h1cc-mod4-nginx"
vm_name             = "cmaz-vf06h1cc-mod4-vm"

# Bölge
location = "eastus"

# VNet ve Subnet CIDR'ları (diğer modüllerle çakışmasın)
vnet_address_space     = ["10.40.0.0/16"]
subnet_frontend_prefix = "10.40.1.0/24"

# VM ayarları
vm_size        = "Standard_F2s_v2"
admin_username = "azureuser"
# DİKKAT: Şifreyi burada tutma!
# vm_admin_password = "<strong-Password-Here>"

# OS Image (Ubuntu 24.04 LTS)
vm_os_publisher = "Canonical"
vm_os_offer     = "ubuntu-24_04-lts"
vm_os_sku       = "server" 
vm_os_version   = "latest"
# (İsteğe bağlı etiket) Görev parametresindeki ad
vm_image_label  = "ubuntu-24_04-lts"

# Public IP
public_ip_allocation_method = "Static"

# NSG kuralları – İnternet’e açık (görev gereği)
allow_http_source = "0.0.0.0/0"
allow_ssh_source  = "0.0.0.0/0"
http_port         = 80
ssh_port          = 22

# Zorunlu Tag
tags = {
  Creator = "sumeyye_unal@epam.com"
}
