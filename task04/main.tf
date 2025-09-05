#############################################
# Resource Group
#############################################
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}

#############################################
# Networking: VNet & Subnet
#############################################
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "frontend" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_frontend_prefix]
}

#############################################
# Public IP (Static) + DNS label
#############################################
resource "azurerm_public_ip" "pip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = var.public_ip_allocation_method # "Static"
  sku               = "Standard"
  domain_name_label = var.dns_label

  tags = var.tags
}

#############################################
# Network Security Group + Rules
#############################################
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

# SSH rule (22/tcp) from Internet
resource "azurerm_network_security_rule" "ssh" {
  name                        = var.nsg_rule_ssh_name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.ssh_port)
  source_address_prefix       = var.allow_ssh_source
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# HTTP rule (80/tcp) from Internet
resource "azurerm_network_security_rule" "http" {
  name                        = var.nsg_rule_http_name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.http_port)
  source_address_prefix       = var.allow_http_source
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#############################################
# Network Interface (NIC) + NSG Association
#############################################
resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.nic_name}-ipconfig"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#############################################
# Linux Virtual Machine (Ubuntu 24.04 LTS)
#############################################
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.vm_password

  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = var.vm_os_publisher
    offer     = var.vm_os_offer
    sku       = var.vm_os_sku
    version   = var.vm_os_version
  }

  tags = var.tags

  # Nginx kurulumu: remote-exec (SSH)
  # NSG kuralları ve NIC-NSG association tamamlanmadan SSH denemesin diye depends_on ekledik.
  depends_on = [
    azurerm_network_interface_security_group_association.nic_nsg_assoc,
    azurerm_network_security_rule.ssh,
    azurerm_network_security_rule.http
  ]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pip.ip_address
      user        = var.admin_username
      password    = var.vm_password
      port        = var.ssh_port
      script_path = "/tmp/terraform_remote_exec.sh"
      timeout     = "15m"
    }

    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl restart nginx",
      # Doğrulama için ana sayfaya küçük bir imza ekleyelim (opsiyonel)
      "echo 'EPAM Task04 - Nginx is running via Terraform 🚀' | sudo tee /var/www/html/index.nginx-debian.html"
    ]
  }
}

