# -*- eval: (outline-minor-mode); outline-regexp: "# [*]+"; -*-

# * Main variables

export STOW_DIR=$(HOME)/.local/stow

LOCAL_FONTS_DIR=$(HOME)/.local/share/fonts
LOCAL_GITHUB_REPOS_DIR=$(HOME)/repos/github.com
GIT_REPOS_DIR=$(HOME)/repos/git

# the following line to find the directory of this Makefile is from here:
# https://stackoverflow.com/a/23324703
MAKEFILE_DIR=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

PACKAGE_DIR=$(MAKEFILE_DIR)/packages

# * Default target

.PHONY: default-target

default-target:
	$(error Please specify an explicit target)

# * Provisioning targets

.PHONY: nunhems

nunhems: PROVISIONING_ENV=Nunhems
nunhems: stow restic git keychain ripgrep tmux yadm $(HOME)/.emacs.d spacemacs-config
	# The following packages should be available: $^

# * Application installation & configuration

# ** restic

.PHONY: restic

RESTIC_VERSION=0.12.0
RESTIC_PACKAGE=restic_$(RESTIC_VERSION)_linux_amd64

restic: ~/.local/bin/restic

~/.local/bin/restic: $(PACKAGE_DIR)/$(RESTIC_PACKAGE)
	# Link the restic binary to a directory in PATH
	ln -s $< $@

$(PACKAGE_DIR)/$(RESTIC_PACKAGE): | $(PACKAGE_DIR)/$(RESTIC_PACKAGE).bz2
	# Uncompress restic archive
	cd $(PACKAGE_DIR) && bzip2 --decompress $(PACKAGE_DIR)/$(RESTIC_PACKAGE).bz2 && chmod 700 $(RESTIC_PACKAGE)

$(PACKAGE_DIR)/$(RESTIC_PACKAGE).bz2:
	# Download restic version $(RESTIC_VERSION) to the packages directory
	wget --directory-prefix=$(PACKAGE_DIR) https://github.com/restic/restic/releases/download/v$(RESTIC_VERSION)/$(RESTIC_PACKAGE).bz2

# ** git

.PHONY: git

GIT_VERSION=2.30.1

git: curl-devel ~/.local/bin/git

# you need to compile git with curl-devel present, otherwise it cannot use the
# "remote helper for https": https://stackoverflow.com/a/13018777
~/.local/bin/git: export CPPFLAGS=-I$(HOME)/.local/include/
~/.local/bin/git: export LDFLAGS=-L$(HOME)/.local/lib/
~/.local/bin/git: $(PACKAGE_DIR)/git-$(GIT_VERSION)
	cd $< && autoconf && ./configure --prefix=$(HOME)/.local && make && make install

$(PACKAGE_DIR)/git-$(GIT_VERSION): $(PACKAGE_DIR)/v$(GIT_VERSION).tar.gz
	tar xvzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/v$(GIT_VERSION).tar.gz:
	wget --directory-prefix=$(PACKAGE_DIR) https://github.com/git/git/archive/v$(GIT_VERSION).tar.gz

# ** curl-devel

.PHONY: curl-devel

CURL_VERSION=7.75.0

curl-devel: ~/.local/bin/curl

~/.local/bin/curl: $(STOW_DIR)/curl
	# Install curl using stow
	stow curl

$(STOW_DIR)/curl: $(PACKAGE_DIR)/curl-$(CURL_VERSION)
	# Build curl from source and install to stow directory
	cd $< && ./configure --prefix=$(STOW_DIR)/curl && make && make install

$(PACKAGE_DIR)/curl-$(CURL_VERSION): $(PACKAGE_DIR)/curl-$(CURL_VERSION).tar.gz
	# Uncompress curl source package
	tar xvzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/curl-$(CURL_VERSION).tar.gz:
	# Download curl source package to the packages directory
	wget --timestamping --directory-prefix=$(PACKAGE_DIR) https://curl.se/download/curl-$(CURL_VERSION).tar.gz

# ** keychain

.PHONY: keychain

KEYCHAIN_VERSION=2.8.5
KEYCHAIN_PACKAGE_DIR=keychain-$(KEYCHAIN_VERSION)

EVAL_KEYCHAIN_COMMAND="eval \`keychain --eval --agents ssh id_rsa\`"

keychain: ~/.local/bin/keychain

~/.local/bin/keychain: $(PACKAGE_DIR)/$(KEYCHAIN_PACKAGE_DIR)/keychain
	# Link the ripgrep binary to a directory in PATH
	ln -s $< $@
	# Let bash profile evaluate keychain
	@if ! grep -q $(EVAL_KEYCHAIN_COMMAND) $(HOME)/.bash_profile; then \
		echo >> $(HOME)/.bash_profile ; \
		echo "$(EVAL_KEYCHAIN_COMMAND)" >> $(HOME)/.bash_profile ; \
	fi

$(PACKAGE_DIR)/$(KEYCHAIN_PACKAGE_DIR)/keychain: | $(PACKAGE_DIR)/$(KEYCHAIN_VERSION).tar.gz
	# Uncompress keychain archive
	cd $(PACKAGE_DIR) && tar xvzf $(KEYCHAIN_VERSION).tar.gz && chmod 700 $(KEYCHAIN_PACKAGE_DIR)/keychain

$(PACKAGE_DIR)/$(KEYCHAIN_VERSION).tar.gz:
	# Download keychain version $(KEYCHAIN_VERSION) to the packages directory
	cd $(PACKAGE_DIR) && wget https://github.com/funtoo/keychain/archive/$(KEYCHAIN_VERSION).tar.gz

# ** ripgrep

.PHONY: ripgrep

RIP_GREP_VERSION=12.1.1
RIP_GREP_PACKAGE=ripgrep-$(RIP_GREP_VERSION)-x86_64-unknown-linux-musl

ripgrep: ~/.local/bin/rg

~/.local/bin/rg: $(PACKAGE_DIR)/$(RIP_GREP_PACKAGE)/rg
	# Link the ripgrep binary to a directory in PATH
	ln -s $< $@

$(PACKAGE_DIR)/$(RIP_GREP_PACKAGE)/rg: | $(PACKAGE_DIR)/$(RIP_GREP_PACKAGE).tar.gz
	# Uncompress ripgrep archive
	cd $(PACKAGE_DIR) && tar xvzf $(RIP_GREP_PACKAGE).tar.gz

$(PACKAGE_DIR)/$(RIP_GREP_PACKAGE).tar.gz:
	# Download ripgrep version $(RIP_GREP_VERSION) to the packages directory
	cd $(PACKAGE_DIR) && wget https://github.com/BurntSushi/ripgrep/releases/download/$(RIP_GREP_VERSION)/$(RIP_GREP_PACKAGE).tar.gz

# ** stow

.PHONY: stow

STOW_VERSION=2.3.1
STOW_ARCHIVE_DIR=stow-$(STOW_VERSION)
STOW_ARCHIVE=$(STOW_ARCHIVE_DIR).tar.gz

stow: ~/.local/bin/stow

~/.local/bin/stow: $(PACKAGE_DIR)/$(STOW_ARCHIVE_DIR)/bin/stow
	# Install stow
	cd $(PACKAGE_DIR)/$(STOW_ARCHIVE_DIR) && make install

$(PACKAGE_DIR)/$(STOW_ARCHIVE_DIR)/bin/stow: $(PACKAGE_DIR)/$(STOW_ARCHIVE_DIR)
	# Build stow from source
	cd $< && ./configure --prefix=$(HOME)/.local && make

$(PACKAGE_DIR)/$(STOW_ARCHIVE_DIR): $(PACKAGE_DIR)/$(STOW_ARCHIVE)
	# Uncompress stow source package
	tar xvzf $< --directory $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(STOW_ARCHIVE):
	# Download stow source package to the packages directory
	wget --timestamping --directory-prefix=$(PACKAGE_DIR) https://ftp.gnu.org/gnu/stow/$(STOW_ARCHIVE)

# ** tmux

.PHONY: tmux

TMUX_VERSION=3.1b
TMUX_APP_IMAGE=tmux-$(TMUX_VERSION)-x86_64.AppImage

tmux: ~/.local/bin/tmux

~/.local/bin/tmux: $(PACKAGE_DIR)/$(TMUX_APP_IMAGE)
	# Link the tmux AppImage to a directory in PATH
	ln -s $< $@

$(PACKAGE_DIR)/$(TMUX_APP_IMAGE): | $(PACKAGE_DIR)
	# Download tmux version $(TMUX_VERSION) to the packages directory
	cd $(PACKAGE_DIR) && wget https://github.com/tmux/tmux/releases/download/$(TMUX_VERSION)/$(TMUX_APP_IMAGE) && chmod 700 $(TMUX_APP_IMAGE)

$(PACKAGE_DIR):
	# Create the directory to store packages
	- mkdir -p $(PACKAGE_DIR)

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
	sudo apt-get install -y browser-plugin-freshplayer-pepperflash firefox
	sudo apt-get install -y git
	sudo apt-get install -y tree

.PHONY: depends install-emacs-dependencies append-local-to-path whiskermenu

depends: install-emacs-dependencies

fix-sources-list:
	sudo sed -i -r 's/^# (deb-src http.* bionic main restricted.*)/\1/' /etc/apt/sources.list
	sudo apt-get update

EMACS_VERSION=26.3
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
	sudo apt-get install -y fonts-powerline

$(HOME)/.emacs.d: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs: | $(LOCAL_GITHUB_REPOS_DIR)
	# Uncompress existing spacemacs installation
	tar xvzf $(PACKAGE_DIR)/spacemacs.tgz -C $(LOCAL_GITHUB_REPOS_DIR)
	# Remove existing links to private packages
	rm $@/private/journal
	rm $@/private/spacemacs-config

spacemacs-clean:
	rm -rf $(LOCAL_GITHUB_REPOS_DIR)/spacemacs
	rm $(HOME)/.emacs.d

spacemacs-config: $(HOME)/.spacemacs $(HOME)/.emacs.d/private/spacemacs-config $(HOME)/.emacs.d/private/journal $(LOCAL_GITHUB_REPOS_DIR)/oje

$(HOME)/.spacemacs: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config/.spacemacs
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config/.spacemacs: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config

$(HOME)/.emacs.d/private/spacemacs-config: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config: | $(LOCAL_GITHUB_REPOS_DIR)
	# Clone my spacemacs config to the packages directory
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/swinkels/spacemacs-config.git
	# Checkout the commit that matches the spacemacs installation
	cd $@ && git checkout 9cc0d00

$(HOME)/.emacs.d/private/journal: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs-journal
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs-journal: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/borgnix/spacemacs-journal.git

$(LOCAL_GITHUB_REPOS_DIR)/oje: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/swinkels/oje.git

fonts: $(LOCAL_FONTS_DIR)/source-code-pro

$(LOCAL_FONTS_DIR)/source-code-pro: $(LOCAL_GITHUB_REPOS_DIR)/source-code-pro | $(LOCAL_FONTS_DIR)
	- rm $@
	ln -s $< $@
	fc-cache -f -v $@

$(LOCAL_GITHUB_REPOS_DIR)/source-code-pro: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $< && git clone --branch release --depth 1 https://github.com/adobe-fonts/source-code-pro.git

fonts-clean:
	- rm $(LOCAL_FONTS_DIR)/source-code-pro
	- rm -rf $(LOCAL_GITHUB_REPOS_DIR)/source-code-pro
	# regenerate the font config cache after the removal of Source Code Pro
	rm -rf ~/.cache/fontconfig
	fc-cache -f -v

CLANG_NAME=clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04
CLANG_ARCHIVE=$(CLANG_NAME).tar.xz

ccls: $(HOME)/.local/bin/ccls

$(HOME)/.local/bin/ccls: $(LOCAL_GITHUB_REPOS_DIR)/ccls/Release/ccls
	ln -s $<

$(LOCAL_GITHUB_REPOS_DIR)/ccls/Release/ccls: | $(LOCAL_GITHUB_REPOS_DIR)/ccls
	cd $(LOCAL_GITHUB_REPOS_DIR)/ccls && cmake -H. -BRelease -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$(HOME)/external_software/$(CLANG_NAME)
	cd $(LOCAL_GITHUB_REPOS_DIR)/ccls && cmake --build Release

$(LOCAL_GITHUB_REPOS_DIR)/ccls: | $(HOME)/external_software/$(CLANG_NAME)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone --depth=1 --recursive https://github.com/MaskRay/ccls

$(HOME)/external_software/$(CLANG_NAME): $(HOME)/tmp/$(CLANG_ARCHIVE) | $(HOME)/external_software
	tar xvf $< -C $(HOME)/external_software
	touch $@ # so the target (directory) is newer than the archive

$(HOME)/tmp/$(CLANG_ARCHIVE): | $(HOME)/tmp
	cd $(HOME)/tmp && wget --timestamping http://releases.llvm.org/8.0.0/$(CLANG_ARCHIVE)

.PHONY: yadm yadm-install yadm-config

YADM_VERSION=2.4.0

yadm: yadm-install yadm-config | ~/.config/yadm/repo.git

yadm-install: ~/.local/bin/yadm

~/.local/bin/yadm: | $(PACKAGE_DIR)/yadm
	# Link the yadm script to a directory in PATH
	ln -s $(PACKAGE_DIR)/yadm/yadm $@

yadm-config:
ifeq ($(PROVISIONING_ENV), Nunhems)
	# Configure yadm for use at $(PROVISIONING_ENV)
	yadm gitconfig user.name "Pieter Swinkels"
	yadm gitconfig user.email swinkels.pieter@yahoo.com
	yadm config local.class $(PROVISIONING_ENV)
else
	@true
endif

$(PACKAGE_DIR)/yadm: | $(PACKAGE_DIR)
	# Clone yadm version $(YADM_VERSION) to the packages directory
	cd $(PACKAGE_DIR) && git clone --branch $(YADM_VERSION) https://github.com/TheLocehiliosan/yadm.git

~/.config/yadm/repo.git:
	# Let yadm clone my personal set of dotfiles
	yadm clone https://github.com/swinkels/yadm-dotfiles.git

# * Backup

RESTIC_BACKUP_REPO=$(HOME)/backup/restic/$(shell hostname)

.PHONY: backup

backup: $(RESTIC_BACKUP_REPO)
ifeq ($(PROVISIONING_ENV), Nunhems)
	# Let restic create a backup
	restic -r $(RESTIC_BACKUP_REPO) backup $(HOME)/repos/git/provisioning $(HOME)/repos/github.com/spacemacs $(HOME)/.ssh $(HOME)/.git-credentials
else
	# No backup rules defined for the current provisioning environment
endif

$(RESTIC_BACKUP_REPO):
	$(error Unable to create backup: there is no restic backup repository at $@)

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
	xfconf-query -c xfwm4 -p /general/theme -n -t string -s "Arc-Dark"
	xfconf-query -c xfwm4 -p /general/title_font -n -t string -s "Noto Sans Bold 9"
	xfconf-query -c xfwm4 -p /general/cycle_workspaces -n -t bool -s false
	xfconf-query -c xfwm4 -p /general/cycle_tabwin_mode -n -t int -s 1
	xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark"
	xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans 9"
	xfconf-query -c xsettings -p /Xfce/LastCustomDPI -n -t string -s 101
	xfconf-query -c xsettings -p /Xft/Antialias -s 1
	xfconf-query -c xsettings -p /Xft/DPI -n -t int -s 101
	xfconf-query -c xsettings -p /Xft/Hinting -s 1
	xfconf-query -c xsettings -p /Xft/HintStyle -s "hintmedium"
	xfconf-query -c xsettings -p /Xft/RGBA -s "rgb"
	xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 24

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
