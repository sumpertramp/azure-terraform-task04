#######################################
# variables.tf  (Task 04 - Linux VM + Nginx)
#######################################

# ---------------------------
# Zorunlu İsimler
# ---------------------------
variable "rg_name" {
  type        = string
  description = "Resource Group Name (cmaz-vf06h1cc-mod4-rg)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_\\.()]{1,90}$", var.rg_name))
    error_message = "rg_name yalnızca harf, rakam, -, _, ., () içerebilir ve 90 karakteri aşmamalıdır."
  }
}

variable "vnet_name" {
  type        = string
  description = "VNet name (cmaz-vf06h1cc-mod4-vnet)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_\\.]{1,64}$", var.vnet_name))
    error_message = "vnet_name yalnızca harf, rakam, -, _, . içerebilir ve 64 karakteri aşmamalıdır."
  }
}

variable "subnet_name" {
  type        = string
  description = "Subnet Name (frontend)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_\\.]{1,80}$", var.subnet_name))
    error_message = "subnet_name yalnızca harf, rakam, -, _, . içerebilir ve 80 karakteri aşmamalıdır."
  }
}

variable "nic_name" {
  type        = string
  description = "Network Interface adı (cmaz-vf06h1cc-mod4-nic)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_\\.]{1,80}$", var.nic_name))
    error_message = "nic_name yalnızca harf, rakam, -, _, . içerebilir ve 80 karakteri aşmamalıdır."
  }
}

variable "nsg_name" {
  type        = string
  description = "Network Security Group adı (cmaz-vf06h1cc-mod4-nsg)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_\\.]{1,80}$", var.nsg_name))
    error_message = "nsg_name yalnızca harf, rakam, -, _, . içerebilir ve 80 karakteri aşmamalıdır."
  }
}

variable "nsg_rule_http_name" {
  type        = string
  description = "NSG inbound HTTP rule name (AllowHTTP)"
  default     = "AllowHTTP"
}

variable "nsg_rule_ssh_name" {
  type        = string
  description = "NSG inbound SSH rule name (AllowSSH)"
  default     = "AllowSSH"
}

variable "public_ip_name" {
  type        = string
  description = "Public IP adı (cmaz-vf06h1cc-mod4-pip)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_\\.]{1,80}$", var.public_ip_name))
    error_message = "public_ip_name yalnızca harf, rakam, -, _, . içerebilir ve 80 karakteri aşmamalıdır."
  }
}

variable "dns_label" {
  type        = string
  description = "DNS name label for public IP (cmaz-vf06h1cc-mod4-nginx)"
  # Azure DNS label kuralları: 1-63, küçük harf, rakam, -, harfle başlamalı, harf/rakam ile bitmeli
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.dns_label))
    error_message = "dns_label 1-63 uzunlukta, küçük harf/rakam/- içermeli; harfle başlamalı ve harf/rakam ile bitmelidir."
  }
}

variable "vm_name" {
  type        = string
  description = "VM name (cmaz-vf06h1cc-mod4-vm)"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.vm_name))
    error_message = "vm_name yalnızca harf, rakam, -, _ içerebilir ve 64 karakteri aşmamalıdır."
  }
}

# ---------------------------
# Konum
# ---------------------------
variable "location" {
  type        = string
  description = "Azure location (e.g. eastus)"
  default     = "eastus2"
}

# ---------------------------
# Ağ ve CIDR'lar
# ---------------------------
variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space list (örn. [\"10.40.0.0/16\"])"
  validation {
    condition     = length(var.vnet_address_space) > 0 && alltrue([for c in var.vnet_address_space : can(cidrhost(c, 0))])
    error_message = "vnet_address_space en az bir geçerli CIDR içermelidir."
  }
}

variable "subnet_frontend_prefix" {
  type        = string
  description = "Frontend subnet CIDR (örn. 10.40.1.0/24)"
  validation {
    condition     = can(cidrhost(var.subnet_frontend_prefix, 0))
    error_message = "subnet_frontend_prefix geçerli bir CIDR olmalıdır (örn. 10.40.1.0/24)."
  }
}

# ---------------------------
# VM Ayarları
# ---------------------------
variable "vm_size" {
  type        = string
  description = "VM SKU (örn. Standard_F2s_v2)"
  default     = "Standard_F2s_v2"
}

variable "admin_username" {
  type        = string
  description = "VM yerel yönetici kullanıcı adı (örn. azureuser)"
  default     = "azureuser"
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.admin_username))
    error_message = "admin_username küçük harfle başlamalı; küçük harf, rakam, -, _ ve opsiyonel sonek $ içerebilir."
  }
}

# DİKKAT: Şifreyi tfvars'a koymayın; apply sırasında TF_VAR_vm_admin_password ile verin.
variable "vm_admin_password" {
  type        = string
  description = "VM local admin password (Azure Linux password policy ile uyumlu)."
  sensitive   = true
  validation {
    condition = (
      length(var.vm_admin_password) >= 12 &&
      can(regex("[A-Z]", var.vm_admin_password)) &&
      can(regex("[a-z]", var.vm_admin_password)) &&
      can(regex("[0-9]", var.vm_admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.vm_admin_password))
    )
    error_message = "Parola en az 12 karakter ve en az 1 büyük harf, 1 küçük harf, 1 rakam ve 1 özel karakter içermelidir."
  }
}

# ---------------------------
# OS Image (Ubuntu 24.04 LTS)
# ---------------------------
variable "vm_os_publisher" {
  type        = string
  description = "Image publisher (Canonical)"
  default     = "Canonical"
}

variable "vm_os_offer" {
  type        = string
  description = "Image offer (0001-com-ubuntu-server-noble)"
  default     = "ubuntu-24_04-lts"
}

variable "vm_os_sku" {
  type        = string
  description = "Image SKU (24_04-lts-gen2)"
  default     = "server"
}

variable "vm_os_version" {
  type        = string
  description = "Image version (latest önerilir)"
  default     = "latest"
}

variable "vm_image_label" {
  type        = string
  description = "Bilgilendirme etiketi: ubuntu-24_04-lts"
  default     = "ubuntu-24_04-lts"
}

# ---------------------------
# Public IP ve NSG
# ---------------------------
variable "public_ip_allocation_method" {
  type        = string
  description = "Public IP allocation method (Static/Dynamic). Görev gereği Static."
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "public_ip_allocation_method 'Static' veya 'Dynamic' olmalıdır."
  }
}

variable "allow_http_source" {
  type        = string
  description = "HTTP için izin verilen kaynak CIDR (0.0.0.0/0 - Internet)"
  default     = "0.0.0.0/0"
  validation {
    condition     = can(cidrhost(var.allow_http_source, 0))
    error_message = "allow_http_source geçerli bir CIDR olmalıdır (örn. 0.0.0.0/0)."
  }
}

variable "allow_ssh_source" {
  type        = string
  description = "SSH için izin verilen kaynak CIDR (0.0.0.0/0 - Internet)"
  default     = "0.0.0.0/0"
  validation {
    condition     = can(cidrhost(var.allow_ssh_source, 0))
    error_message = "allow_ssh_source geçerli bir CIDR olmalıdır (örn. 0.0.0.0/0)."
  }
}

variable "http_port" {
  type        = number
  description = "HTTP portu"
  default     = 80
  validation {
    condition     = var.http_port > 0 && var.http_port < 65536
    error_message = "http_port 1-65535 aralığında olmalıdır."
  }
}

variable "ssh_port" {
  type        = number
  description = "SSH portu"
  default     = 22
  validation {
    condition     = var.ssh_port > 0 && var.ssh_port < 65536
    error_message = "ssh_port 1-65535 aralığında olmalıdır."
  }
}

# ---------------------------
# Tag'ler
# ---------------------------
variable "tags" {
  type        = map(string)
  description = "Kaynaklara uygulanacak tag'ler (Creator zorunlu)."
  validation {
    condition     = contains(keys(var.tags), "Creator") && length(var.tags["Creator"]) > 0
    error_message = "tags haritasında 'Creator' anahtarı zorunludur ve boş olamaz."
  }
}
