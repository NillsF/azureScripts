variable "prefix" {
  default = "kill-me"
}

variable "timeout" {
  default = "15 minutes"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West US 2"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_public_ip" "test" {
  name                = "${var.prefix}-pip"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"

}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "killme"
    admin_username = "nilfranadmin"
    custom_data = <<-EOF
        #!/bin/bash
        sudo apt-get install at -y
        echo "response=\$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s)" > killme.sh
        echo "access_token=\$(echo \$response | python -c 'import sys, json; print (json.load(sys.stdin)[\"access_token\"])')" >> killme.sh
        echo "curl -X DELETE -H \"Authorization: Bearer \$access_token\" -H \"Content-Type: application/json\" https://management.azure.com/${azurerm_resource_group.main.id}?api-version=2019-05-10" >> killme.sh
        at now + ${var.timeout} -f killme.sh
        EOF
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path = "/home/nilfranadmin/.ssh/authorized_keys"
        key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAslS5LnoCJlj8OE4VncUK2iP6YhVT/RmeNkvP3VTd/GbiZd384wrD0rzr3MwEgMm4ZkjUQno54x+bpRhIFDha4Kj89cs7LwuPHZSkXLF+aVydxy2nu464TmflnhVVW71wLE9E3bCUxmh5+IZ3sJ8is2XQMuC1IHiIoEMFc+buMTG+kVc3f+VaJ5ZT+bFPjqs816YBPTSZRmUjzfwRcLIRXvlVxlFsMckhSTa7xCCxunsGKITOnqmlk/vIWr/bKfev6RD+qV8DFquM0zxquwcSv5ERXE384m6ESJ/YJ4IN5P14CDWT3pdZtwM1jOaL/zPyMHbamk5iTPLfuPao740plQ=="
    }
 
  }

  identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "test" {
  scope                = "${azurerm_resource_group.main.id}"
  role_definition_name = "Contributor"
  principal_id         = "${lookup(azurerm_virtual_machine.main.identity[0], "principal_id")}"
}
