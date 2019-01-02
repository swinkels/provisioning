# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "bento/ubuntu-18.04"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network", bridge: "wlan0"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
 
    # Customize the amount of memory on the VM:
    vb.memory = "4096"

    # Customize the amount of video memory:
    vb.customize ["modifyvm", :id, "--vram", "128"]

    config.vm.provision "shell", inline: "sudo apt-get update"
    # Install virtualbox additions
    config.vm.provision "shell", inline: "sudo apt-get install -y virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    # Set the local time to CET
    sudo rm /etc/localtime && ln -s /usr/share/zoneinfo/CET /etc/localtime
    # Install a display manager (for some reason or another, TeamViewer requires one)
    sudo apt-get install -y lightdm lightdm-gtk-greeter
    # Install xfce
    sudo apt-get install -y xfce4 xfce4-whiskermenu-plugin
    # Permit anyone to start the GUI
    sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config
    # install misc applications
    sudo apt-get install -y firefox git zsh xfce4-terminal
  SHELL

  config.vm.provision "file", source: "~/.ssh/throwaway", destination: "/home/vagrant/.ssh/id_rsa"
  config.vm.provision "file", source: "~/.ssh/throwaway.pub", destination: "/home/vagrant/.ssh/id_rsa.pub"

end
