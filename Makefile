LOCAL_FONTS_DIR=$(HOME)/.local/share/fonts
LOCAL_GITHUB_REPOS_DIR=$(HOME)/repos/github.com

bootstrap:
	# set the local time to CET
	- sudo rm /etc/localtime
	sudo ln -s /usr/share/zoneinfo/CET /etc/localtime
	# resynchronize the package index files from their sources
	sudo apt-get update -y
	# install the newest versions of all packages currently installed
	sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -o DPkg::Options::=--force-confdef -y
	# install a display manager
	sudo apt-get install -y lightdm lightdm-gtk-greeter
	# install xfce
	sudo apt-get install -y xfce4 xfce4-terminal
	# permit anyone to start the GUI
	sudo sed -i 's/allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config
	# install "absolutely required" applications
	sudo apt-get install -y policykit-1-gnome synaptic
	sudo apt-get install -y firefox git

.PHONY: depends install-emacs-dependencies append-local-to-path whiskermenu

depends: install-emacs-dependencies

fix-sources-list:
	sudo sed -i -r 's/^# (deb-src http.* bionic main restricted.*)/\1/' /etc/apt/sources.list
	sudo apt-get update

EMACS_VERSION=26.1
EMACS_NAME=emacs-$(EMACS_VERSION)
EMACS_ARCHIVE=$(EMACS_NAME).tar.gz

emacs: install-emacs-build-dependencies $(HOME)/.local/bin/$(EMACS_NAME)

install-emacs-build-dependencies:
	sudo apt-get -y install autoconf automake libtool texinfo build-essential xorg-dev libgtk2.0-dev libjpeg-dev libncurses5-dev libdbus-1-dev libgif-dev libtiff-dev libm17n-dev libpng-dev librsvg2-dev libotf-dev libgnutls28-dev libxml2-dev

$(HOME)/.local/bin/$(EMACS_NAME): $(HOME)/external_software/$(EMACS_NAME) | $(HOME)/.local
	cd $< && ./configure --prefix=$(HOME)/.local && make && make install

$(HOME)/external_software/$(EMACS_NAME): $(HOME)/tmp/$(EMACS_ARCHIVE) | $(HOME)/external_software
	tar xvf $< -C $(HOME)/external_software

$(HOME)/tmp/$(EMACS_ARCHIVE): | $(HOME)/tmp
	cd $(HOME)/tmp && wget --timestamping http://ftp.snt.utwente.nl/pub/software/gnu/emacs/$(EMACS_ARCHIVE)

emacs-clean:
	- cd $(HOME)/external_software/$(EMACS_NAME) && make uninstall
	- rm -rf $(HOME)/external_software/$(EMACS_NAME)

spacemacs: install-spacemacs-dependencies $(HOME)/.emacs.d

install-spacemacs-dependencies:
	apt-get install -y fonts-powerline

$(HOME)/.emacs.d: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/syl20bnr/spacemacs.git

spacemacs-config: $(HOME)/.spacemacs $(LOCAL_GITHUB_REPOS_DIR)/oje

$(HOME)/.spacemacs: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config/.spacemacs
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config/.spacemacs: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/swinkels/spacemacs-config.git

$(LOCAL_GITHUB_REPOS_DIR)/oje: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/swinkels/oje.git

fonts: $(LOCAL_FONTS_DIR)/source-code-pro

$(LOCAL_FONTS_DIR)/source-code-pro: $(LOCAL_GITHUB_REPOS_DIR)/source-code-pro | $(LOCAL_FONTS_DIR)
	ln -s $< $@
	fc-cache -f -v $@

$(LOCAL_GITHUB_REPOS_DIR)/source-code-pro: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $< && git clone --branch release --depth 1 https://github.com/adobe-fonts/source-code-pro.git

python-dev: | $(HOME)/.local $(HOME)/tmp
	curl -fsSL https://bootstrap.pypa.io/get-pip.py > $(HOME)/tmp/get-pip.py
	python3 $(HOME)/tmp/get-pip.py --user
	$(HOME)/.local/bin/pip install --user --upgrade virtualenvwrapper

SOURCE_WRAPPER_MARKER=\$$HOME/.local/bin/virtualenvwrapper.sh
SOURCE_WRAPPER_LINES=source $(SOURCE_WRAPPER_MARKER)

install-virtualenvwrapper-in-zsh: $(HOME)/.zshrc $(HOME)/.virtualenvs
	if ! grep -q "$(SOURCE_WRAPPER_MARKER)" $<; then \
		echo >> $< ; \
		echo "# added by the provisioning script" >> $< ; \
		echo "export WORKON_HOME=\$$HOME/.virtualenvs" >> $< ; \
		echo "export VIRTUALENVWRAPPER_PYTHON=`which python3`" >> $< ; \
		echo "$(SOURCE_WRAPPER_LINES)" >> $< ; \
	fi

$(HOME)/.virtualenvs:
	mkdir $@

WRAPPER_MARKER=virtualenvwrapper

install-zsh-plugin-virtualenvwrapper: $(HOME)/.zshrc
	if ! grep -q "$(WRAPPER_MARKER)" $<; then \
		sed -i -r 's/(^plugins=\()(.*)$$/\1$(WRAPPER_MARKER) \2/' $(HOME)/.zshrc ; \
	fi

$(HOME)/.zshrc: $(HOME)/.zshrc.orig
	cp $< $@

$(HOME)/.zshrc.orig:
	if [ -s $(HOME)/.zshrc ]; then \
		cp $(HOME)/.zshrc $(HOME)/.zshrc.orig ; \
	else \
		touch $(HOME)/.zshrc.orig ; \
	fi

setup-zsh: install-zsh set-zsh-as-login-shell | $(HOME)/.oh-my-zsh

install-zsh:
	sudo apt-get install -y zsh

set-zsh-as-login-shell:
	@echo Set login shell of the current user to zsh. This requires you to enter
	@echo your password and a logout \& login.
	chsh -s $(shell which zsh)

$(HOME)/.oh-my-zsh: $(HOME)/tmp/install-oh-my-zsh.sh
	sh $<

$(HOME)/tmp/install-oh-my-zsh.sh: | $(HOME)/tmp
	curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh > $@
	sed -i '/^.*env zsh -l/d' $@

CAPS_TO_CTRL_COMMAND="setxkbmap -option compose:rctrl -option ctrl:nocaps"

set-caps-to-ctrl: $(HOME)/.xprofile
	if ! grep -q $(CAPS_TO_CTRL_COMMAND) $<; then echo $(CAPS_TO_CTRL_COMMAND) >> $<; fi

$(HOME)/.xprofile: $(HOME)/.xprofile.orig
	cp $< $@

$(HOME)/.xprofile.orig:
	if [ -s $(HOME)/.xprofile ]; then \
		cp $(HOME)/.xprofile $(HOME)/.xprofile.orig ; \
	else \
		touch $(HOME)/.xprofile.orig ; \
	fi

LOCAL_BIN=\$$HOME/.local/bin
LOCAL_DIR_MARKER="PATH=\"$(LOCAL_BIN)"
LOCAL_DIR_LINES=if [ -d \"$(LOCAL_BIN)\" ]; then export PATH=\"$(LOCAL_BIN):\$$PATH\"; fi

append-local-to-path: $(HOME)/.profile
	if ! grep -q $(LOCAL_DIR_MARKER) $<; then \
		echo "$(LOCAL_DIR_LINES)" >> $< ; \
	fi

$(HOME)/.profile: $(HOME)/.profile.orig
	echo "# This file is generated from $< by the" > $@
	echo "# provisioning script. If you modify this file, your modifications" >> $@
	echo "# can be undone during the next run of that script." >> $@
	echo >> $@
	cat $< >> $@
	echo >> $@

$(HOME)/.profile.orig:
	if [ -s $(HOME)/.profile ]; then \
		cp $(HOME)/.profile $(HOME)/.profile.orig ; \
	else \
		touch $(HOME)/.profile.orig ; \
	fi

x220-add-fullscreen-to-vm: /etc/X11/xorg.conf.d/40-x220.conf

/etc/X11/xorg.conf.d/40-x220.conf: 40-vm-on-x220.conf | /etc/X11/xorg.conf.d
	sudo cp 40-vm-on-x220.conf $@

/etc/X11/xorg.conf.d:
	sudo mkdir -p $@

desktop-look:
	sudo apt-get install arc-theme fonts-noto
	xfconf-query -c xfwm4 -p /general/theme -s "Arc-Dark"
	xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans Bold 9"
	xfconf-query -c xfwm4 -p /general/cycle_workspaces -s false
	xfconf-query -c xfwm4 -p /general/cycle_tabwin_mode -s 1
	xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark"
	xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans 9"
	xfconf-query -c xsettings -p /Xfce/LastCustomDPI -n -t string -s 101
	xfconf-query -c xsettings -p /Xft/Antialias -s 1
	xfconf-query -c xsettings -p /Xft/DPI -n -t int -s 101
	xfconf-query -c xsettings -p /Xft/Hinting -s 1
	xfconf-query -c xsettings -p /Xft/HintStyle -s "hintmedium"
	xfconf-query -c xsettings -p /Xft/RGBA -s "rgb"
	xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 24

install-community-wallpapers:
	sudo apt-get install xubuntu-community-wallpapers

whiskermenu:
	sudo apt-get install xfce4-whiskermenu-plugin

BROWSER_MARKER=WebBrowser=
BROWSER=firefox
TERMINAL_MARKER=TerminalEmulator=
TERMINAL=xfce4-terminal

set-preferred-applications: $(HOME)/.config/xfce4/helpers.rc
	if grep -q "$(BROWSER_MARKER)" $<; then \
		sed -i -r 's/(^$(BROWSER_MARKER))(.*)/\1$(BROWSER)/' $< ; \
	else \
		echo "$(BROWSER_MARKER)$(BROWSER)" >> $< ; \
	fi
	if grep -q "$(TERMINAL_MARKER)" $<; then \
		sed -i -r 's/(^$(TERMINAL_MARKER))(.*)/\1$(TERMINAL)/' $< ; \
	else \
		echo "$(TERMINAL_MARKER)$(TERMINAL)" >> $< ; \
	fi

$(HOME)/.config/xfce4/helpers.rc: $(HOME)/.config/xfce4/helpers.rc.orig
	echo "# This file is generated from $< by the" > $@
	echo "# provisioning script. If you modify this file, your modifications" >> $@
	echo "# can be undone during the next run of that script." >> $@
	echo >> $@
	cat $< >> $@
	echo >> $@

$(HOME)/.config/xfce4/helpers.rc.orig:
	if [ -s $(HOME)/.config/xfce4/helpers.rc ]; then \
		cp $(HOME)/.config/xfce4/helpers.rc $@ ; \
	else \
		touch $@ ; \
	fi

$(HOME)/.local $(LOCAL_FONTS_DIR) $(HOME)/tmp $(HOME)/external_software $(LOCAL_GITHUB_REPOS_DIR):
	mkdir -p $@

install-vagrant: $(HOME)/tmp/vagrant_2.2.2_x86_64.deb
	sudo dpkg -i $<
	vagrant plugin install vagrant-mutate
	vagrant plugin install vagrant-libvirt
	vagrant plugin install nokogiri

$(HOME)/tmp/vagrant_2.2.2_x86_64.deb:
	wget -P $(HOME)/tmp https://releases.hashicorp.com/vagrant/2.2.2/vagrant_2.2.2_x86_64.deb
