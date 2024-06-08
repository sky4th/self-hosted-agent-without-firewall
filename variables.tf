variable "resource_group_location" {
  type        = string
  description = "Location for all resources."
  default     = "uksouth"
}

variable "resource_group_name" {
  type        = string
  description = "Prefix for the Resource Group Name that's combined with a random id so name is unique in your Azure subcription."
  default     = "rg-self-hosted-agent"
}


variable "virtual_machine_size" {
  type        = string
  description = "Size of the virtual machine."
  default     = "Standard_D2_v3"
}

variable "admin_username" {
  type        = string
  description = "Value of the admin username."
  default     = "azureuser"
}

variable "url" {
    type        =   string
    description = "devops url"
    default = "https://dev.azure.com/{organization name}/"
}

variable "pat" {
    type        =   string
    default     = ""
}

variable "pool" {
    type        =   string
    description = "name of the agent"
    default     = "Default" 
}

variable "agent-name" {
    type        =   string
    description = "name of the agent"
    default     = "sky4th-agent" 
}

variable "password" {
    default = "sky4th@123456"
  
}