
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_public_ip" "pip_agent" {
  name                = "pip-agent"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}


resource "azurerm_virtual_network" "agent_vnet" {
  name                = "agent-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
}


resource "azurerm_subnet" "server_subnet" {
  name                 = "subnet-server"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.agent_vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}


# resource "azurerm_public_ip" "vm_agent_pip" {
#   name                = "pip-jump"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

resource "azurerm_network_interface" "vm_server_nic" {
  name                = "nic-server"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-workload"
    subnet_id                     = azurerm_subnet.server_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_agent.id
  }
}



# resource "azurerm_network_security_group" "vm_server_nsg" {
#   name                = "nsg-server"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }


# resource "azurerm_network_interface_security_group_association" "vm_server_nsg_association" {
#   network_interface_id      = azurerm_network_interface.vm_server_nic.id
#   network_security_group_id = azurerm_network_security_group.vm_server_nsg.id
# }


resource "azurerm_windows_virtual_machine" "vm_server" {
  name                  = "server-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  computer_name         = "server"
  size                  = var.virtual_machine_size
  admin_username        = var.admin_username
  admin_password        = var.password
  network_interface_ids = [azurerm_network_interface.vm_server_nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "128"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}



resource "azurerm_virtual_machine_extension" "self-hsoted-agent" {
    name                 = var.agent-name
    virtual_machine_id   = azurerm_windows_virtual_machine.vm_server.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.9"

    

    protected_settings = <<SETTINGS
    {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.install_devops_agent_win.rendered)}')) | Out-File -filepath ADDS.ps1\" && powershell -ExecutionPolicy Unrestricted -File ADDS.ps1 -DEVOPSURL ${data.template_file.install_devops_agent_win.vars.DEVOPSURL} -DEVOPSPAT ${data.template_file.install_devops_agent_win.vars.DEVOPSPAT} -DEVOPSPOOL ${data.template_file.install_devops_agent_win.vars.DEVOPSPOOL}" 
    }
    SETTINGS
  
}


# resource "azurerm_virtual_machine_extension" "linux_mac" {
#   name                 = var.agent-name
#   virtual_machine_id   = azurerm_windows_virtual_machine.vm_server.id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.10"

#   settings = <<SETTINGS
#     {
#         "fileUris": [],
#         "commandToExecute": ${jsonencode(local.command_to_execute)}
#     }
# SETTINGS
# }

#Variable input for the ADDS.ps1 script
data "template_file" "install_devops_agent_win" {
    # for_each    = local.scripts_to_execute
    template    = "${file("windows-agent-install.ps1")}"
    vars = {
        DEVOPSURL     =   "${var.url}"   
        DEVOPSPAT     =   "${var.pat}"
        DEVOPSPOOL    =   "${var.pool}"   
        DEVOPSAGENT   =   "${var.agent-name}"
        }
}
# data "template_file" "install_devops_agent_linux_mac" {
#     # for_each    = local.scripts_to_execute
#     template = file("${path.module}/install-git-and-run-script.ps1")
#     vars = {
#         DEVOPSURL     =   "${var.url}"   
#         DEVOPSPAT     =   "${var.pat}"
#         DEVOPSPOOL    =   "${var.pool}"   
#         DEVOPSAGENT   =   "${var.agent-name}"
#         }
# }

