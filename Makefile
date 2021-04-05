# -*- eval: (outline-minor-mode); outline-regexp: "# [*]+"; -*-

# * Main variables

ifeq ($(STOW_DIR),)
export STOW_DIR=$(HOME)/.local/stow
endif

LOCAL_FONTS_DIR=$(HOME)/.local/share/fonts
LOCAL_GITHUB_REPOS_DIR=$(HOME)/repos/github.com
GIT_REPOS_DIR=$(HOME)/repos/git

# the following line to find the directory of this Makefile is from here:
# https://stackoverflow.com/a/23324703
MAKEFILE_DIR=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

PACKAGE_DIR=$(MAKEFILE_DIR)/packages

WGET_OPTIONS=--timestamping --directory-prefix=$(PACKAGE_DIR)

# * Default target

# If you don't specify a target on the command-line, this Makefile falls back to
# target ~default-target~. That target only leads to the target that is determined
# by the value of environment variable ~PROVISIONING_ENV~, see the code below for
# the actual mapping from value to target.

# If the environment variable is undefined or specifies a provisioning environment
# that is not recognized, the actual target is ~no-target~. That target lets
# ~make~ abort with the error message to specify an explicit target.

.PHONY: default-target no-target

ifeq ($(PROVISIONING_ENV), Nunhems)
TARGET=nunhems
else
TARGET=no-target
endif

default-target: $(TARGET)

no-target:
	$(error Please specify an explicit target)

# * Provisioning targets

.PHONY: nunhems

# Some targets have to run before others. Currently (target) ~stow~ runs first
# as stow is used to install most of the other packages. ~git~ runs second as
# git is used to retrieve the software for other targets. ~yadm~ runs third as
# yadm provides configurations for other software: with those configurations
# already in place, that software can start fully configured.

nunhems: stow git yadm keychain zsh fzf restic ripgrep tmux $(HOME)/.emacs.d spacemacs-config
	# The following packages should be available: $^

# * Application installation & configuration

# ** emacs

EMACS_VERSION=27.1
EMACS_ARCHIVE_DIR=emacs-$(EMACS_VERSION)
EMACS_ARCHIVE=$(EMACS_ARCHIVE_DIR).tar.gz

ifeq ($(PROVISIONING_ENV), Nunhems)
EMACS_EXTRA_CONFIGURE_OPTIONS= \
  --with-gif=ifavailable \
  --with-gnutls=ifavailable \
  --with-jpeg=ifavailable \
  --with-png=ifavailable \
  --with-tiff=ifavailable \
  --with-x-toolkit=no \
  --with-xpm=ifavailable
endif

emacs: ~/.local/bin/emacs

~/.local/bin/emacs: $(STOW_DIR)/$(EMACS_ARCHIVE_DIR)/bin/emacs
	# Install Emacs using Stow
	stow $(EMACS_ARCHIVE_DIR) && touch $@

$(STOW_DIR)/$(EMACS_ARCHIVE_DIR)/bin/emacs: $(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR)/src/emacs
	# Install Emacs to Stow directory
	cd $(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR) && make install

$(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR)/src/emacs: | $(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR)
	# Build Emacs from source
	cd $| && ./configure $(EMACS_EXTRA_CONFIGURE_OPTIONS) --prefix=$(STOW_DIR)/$(EMACS_ARCHIVE_DIR) && make

$(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR): $(PACKAGE_DIR)/$(EMACS_ARCHIVE)
	# Uncompress Emacs source package
	tar xzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(EMACS_ARCHIVE):
	# Download Emacs source package to the packages directory
	wget $(WGET_OPTIONS) http://ftp.snt.utwente.nl/pub/software/gnu/emacs/$(EMACS_ARCHIVE)

# ** git

.PHONY: git

GIT_VERSION=2.30.1

git: curl ~/.local/bin/git

# You need to compile git with curl-devel present, otherwise it cannot use the
# "remote helper for https" (https://stackoverflow.com/a/13018777) To install
# curl-devel from source, you compile and install the curl source package.
~/.local/bin/git: export CPPFLAGS=-I$(HOME)/.local/include/
~/.local/bin/git: export LDFLAGS=-L$(HOME)/.local/lib/
~/.local/bin/git: $(PACKAGE_DIR)/git-$(GIT_VERSION)
	cd $< && autoconf && ./configure --prefix=$(HOME)/.local && make && make install

$(PACKAGE_DIR)/git-$(GIT_VERSION): $(PACKAGE_DIR)/v$(GIT_VERSION).tar.gz
	tar xvzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/v$(GIT_VERSION).tar.gz:
	wget $(WGET_OPTIONS) https://github.com/git/git/archive/v$(GIT_VERSION).tar.gz

# ** cmake

.PHONY: cmake

CMAKE_VERSION=3.20.0
CMAKE_ARCHIVE_DIR=cmake-$(CMAKE_VERSION)
CMAKE_ARCHIVE=$(CMAKE_ARCHIVE_DIR).tar.gz

cmake: ~/.local/bin/cmake

~/.local/bin/cmake: $(STOW_DIR)/$(CMAKE_ARCHIVE_DIR)/bin/cmake
	# Install cmake using Stow
	stow $(CMAKE_ARCHIVE_DIR) && touch $@

$(STOW_DIR)/$(CMAKE_ARCHIVE_DIR)/bin/cmake: $(PACKAGE_DIR)/$(CMAKE_ARCHIVE_DIR)/bin/cmake
	# Install cmake to Stow directory
	cd $(PACKAGE_DIR)/$(CMAKE_ARCHIVE_DIR) && make install

$(PACKAGE_DIR)/$(CMAKE_ARCHIVE_DIR)/bin/cmake: | $(PACKAGE_DIR)/$(CMAKE_ARCHIVE_DIR)
	# Build cmake from source
	cd $| && ./configure --prefix=$(STOW_DIR)/$(CMAKE_ARCHIVE_DIR) && make

$(PACKAGE_DIR)/$(CMAKE_ARCHIVE_DIR): $(PACKAGE_DIR)/$(CMAKE_ARCHIVE)
	# Uncompress cmake source package
	tar xzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(CMAKE_ARCHIVE):
	# Download cmake source package to the packages directory
	wget $(WGET_OPTIONS) https://github.com/Kitware/CMake/releases/download/v$(CMAKE_VERSION)/$(CMAKE_ARCHIVE)

# ** curl

.PHONY: curl

CURL_VERSION=7.75.0
CURL_ARCHIVE_DIR=curl-$(CURL_VERSION)
CURL_ARCHIVE=$(CURL_ARCHIVE_DIR).tar.gz

curl: ~/.local/bin/curl

~/.local/bin/curl: $(STOW_DIR)/$(CURL_ARCHIVE_DIR)/bin
	# Install curl using Stow
	stow $(CURL_ARCHIVE_DIR) && touch $@

$(STOW_DIR)/$(CURL_ARCHIVE_DIR)/bin: $(PACKAGE_DIR)/$(CURL_ARCHIVE_DIR)/src/curl
	# Install curl to Stow directory
	cd $(PACKAGE_DIR)/$(CURL_ARCHIVE_DIR) && make install

$(PACKAGE_DIR)/$(CURL_ARCHIVE_DIR)/src/curl: | $(PACKAGE_DIR)/$(CURL_ARCHIVE_DIR)
	# Build curl from source
	cd $| && ./configure --prefix=$(STOW_DIR)/$(CURL_ARCHIVE_DIR) && make

$(PACKAGE_DIR)/$(CURL_ARCHIVE_DIR): $(PACKAGE_DIR)/$(CURL_ARCHIVE)
	# Uncompress curl source package
	tar xzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(CURL_ARCHIVE):
	# Download curl source package to the packages directory
	wget $(WGET_OPTIONS) https://curl.se/download/$(CURL_ARCHIVE)

# ** fzf

.PHONY: fzf

# We let the main target depend on the ~fzf.tmux~ script instead of the ~fzf~
# binary. Because the binary has its build date as its creation date, it will
# always be older than the files it depends on. So would we use the ~fzf~ binary
# as a target, it would always be rebuild. The script doesn't have this issue as
# its created at installation.

fzf: ~/.fzf/bin/fzf-tmux

~/.fzf/bin/fzf-tmux: | ~/.fzf/install
	# Install fzf using its install script
	cd ~/.fzf && ./install --key-bindings --completion --no-bash --no-update-rc

~/.fzf/install:
	# Clone fzf to its installation directory
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

# ** keychain

.PHONY: keychain

KEYCHAIN_VERSION=2.8.5
KEYCHAIN_PACKAGE_DIR=keychain-$(KEYCHAIN_VERSION)

EVAL_KEYCHAIN_COMMAND="eval \`keychain --eval --agents ssh id_rsa\`"

keychain: ~/.local/bin/keychain

~/.local/bin/keychain: $(PACKAGE_DIR)/$(KEYCHAIN_PACKAGE_DIR)/keychain
	# Link the ripgrep binary to a directory in PATH
	ln -s $< $@

$(PACKAGE_DIR)/$(KEYCHAIN_PACKAGE_DIR)/keychain: | $(PACKAGE_DIR)/$(KEYCHAIN_VERSION).tar.gz
	# Uncompress keychain archive
	cd $(PACKAGE_DIR) && tar xvzf $(KEYCHAIN_VERSION).tar.gz && chmod 700 $(KEYCHAIN_PACKAGE_DIR)/keychain

$(PACKAGE_DIR)/$(KEYCHAIN_VERSION).tar.gz:
	# Download keychain version $(KEYCHAIN_VERSION) to the packages directory
	wget $(WGET_OPTIONS) https://github.com/funtoo/keychain/archive/$(KEYCHAIN_VERSION).tar.gz

# ** libtool

.PHONY: libtool

LIBTOOL_VERSION=2.4.6
LIBTOOL_ARCHIVE_DIR=libtool-$(LIBTOOL_VERSION)
LIBTOOL_ARCHIVE=$(LIBTOOL_ARCHIVE_DIR).tar.gz

libtool: ~/.local/bin/libtool

~/.local/bin/libtool: $(STOW_DIR)/$(LIBTOOL_ARCHIVE_DIR)/bin/libtool
	# Install libtool using Stow
	stow $(LIBTOOL_ARCHIVE_DIR) && touch $@

$(STOW_DIR)/$(LIBTOOL_ARCHIVE_DIR)/bin/libtool: $(PACKAGE_DIR)/$(LIBTOOL_ARCHIVE_DIR)/libtool
	# Install libtool to Stow directory
	cd $(PACKAGE_DIR)/$(LIBTOOL_ARCHIVE_DIR) && make install

$(PACKAGE_DIR)/$(LIBTOOL_ARCHIVE_DIR)/libtool: | $(PACKAGE_DIR)/$(LIBTOOL_ARCHIVE_DIR)
	# Build libtool from source
	cd $| && ./configure --prefix=$(STOW_DIR)/$(LIBTOOL_ARCHIVE_DIR) && make

$(PACKAGE_DIR)/$(LIBTOOL_ARCHIVE_DIR): $(PACKAGE_DIR)/$(LIBTOOL_ARCHIVE)
	# Uncompress libtool source package
	tar xzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(LIBTOOL_ARCHIVE):
	# Download libtool source package to the packages directory
	wget $(WGET_OPTIONS) http://ftp.jaist.ac.jp/pub/GNU/libtool/$(LIBTOOL_ARCHIVE)

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
	wget $(WGET_OPTIONS) https://github.com/restic/restic/releases/download/v$(RESTIC_VERSION)/$(RESTIC_PACKAGE).bz2

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
	wget $(WGET_OPTIONS) https://github.com/BurntSushi/ripgrep/releases/download/$(RIP_GREP_VERSION)/$(RIP_GREP_PACKAGE).tar.gz

# ** spacemacs

.PHONY: spacemacs

SPACEMACS_COMMIT=679040f
SPACEMACS_STOW_DIR=$(GIT_REPOS_DIR)/spacemacs-production

# spacemacs uses emacs-libterm, which needs cmake and libtool to build some of its
# dependencies during installation.

spacemacs: cmake libtool install-spacemacs-dependencies $(HOME)/.emacs.d

$(HOME)/.emacs.d: | $(GIT_REPOS_DIR)/spacemacs-production/.emacs.d $(GIT_REPOS_DIR)/spacemacs-production/.spacemacs.d
	# Install spacemacs using Stow
	stow --dir=$(GIT_REPOS_DIR) --target=$(HOME) spacemacs-production

spacemacs-unstow:
	# Uninstall spacemacs using Stow
	stow --delete --dir=$(GIT_REPOS_DIR) --target=$(HOME) spacemacs-production

$(SPACEMACS_STOW_DIR)/.emacs.d:
	# Clone spacemacs to its Stow directory
	git clone https://github.com/syl20bnr/spacemacs $@
	# Checkout the develop branch at the correct commit
	cd $@ && git reset --hard $(SPACEMACS_COMMIT)

$(SPACEMACS_STOW_DIR)/.spacemacs.d:
	# Clone my spacemacs config to its Stow directory
	git clone git@github.com:swinkels/spacemacs-config.git $@

install-spacemacs-dependencies:
	# sudo apt-get install -y fonts-powerline

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
	wget $(WGET_OPTIONS) https://ftp.gnu.org/gnu/stow/$(STOW_ARCHIVE)

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
	wget $(WGET_OPTIONS) https://github.com/tmux/tmux/releases/download/$(TMUX_VERSION)/$(TMUX_APP_IMAGE) && chmod 700 $(TMUX_APP_IMAGE)

$(PACKAGE_DIR):
	# Create the directory to store packages
	- mkdir -p $(PACKAGE_DIR)

# ** zsh

.PHONY: zsh oh-my-zsh

ZSH_VERSION=5.8
ZSH_ARCHIVE_DIR=zsh-$(ZSH_VERSION)
ZSH_ARCHIVE=$(ZSH_ARCHIVE_DIR).tar.xz

# The following variable contains the commands to start zsh from the bash
# profile. This is a workaround if you cannot use ~chsh~ to set the shell
# (https://unix.stackexchange.com/a/136424).

# How to define (and use) a multiline variable in a Makefile is from
# https://stackoverflow.com/a/649462.
define EXEC_LOCAL_ZSH
export SHELL=~/.local/bin/zsh
[ -z "$$ZSH_VERSION" ] && exec "$$SHELL" -l

endef
BASH_PROFILE=$(HOME)/.bash_profile

export EXEC_LOCAL_ZSH
zsh: zsh-install oh-my-zsh

# How to prefix an existing file is from
# https://www.cyberciti.biz/faq/bash-prepend-text-lines-to-file/.
zsh-install: ~/.local/bin/zsh
	@if ! grep -q "export SHELL=~/.local/bin/zsh" $(BASH_PROFILE) ; then \
		echo -e "$$EXEC_LOCAL_ZSH\n`cat $(BASH_PROFILE)`" > $(BASH_PROFILE) ; \
	fi
	# zsh is installed

~/.local/bin/zsh: $(STOW_DIR)/$(ZSH_ARCHIVE_DIR)/bin
	# Install zsh using Stow
	stow $(ZSH_ARCHIVE_DIR) && touch $@

$(STOW_DIR)/$(ZSH_ARCHIVE_DIR)/bin: $(PACKAGE_DIR)/$(ZSH_ARCHIVE_DIR)/Src/zsh
	# Install zsh to Stow directory
	cd $(PACKAGE_DIR)/$(ZSH_ARCHIVE_DIR) && make install

$(PACKAGE_DIR)/$(ZSH_ARCHIVE_DIR)/Src/zsh: | $(PACKAGE_DIR)/$(ZSH_ARCHIVE_DIR)
	# Build zsh from source
	cd $| && ./configure --prefix=$(STOW_DIR)/$(ZSH_ARCHIVE_DIR) && make

$(PACKAGE_DIR)/$(ZSH_ARCHIVE_DIR): $(PACKAGE_DIR)/$(ZSH_ARCHIVE)
	# Uncompress zsh source package
	tar xJf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(ZSH_ARCHIVE):
	# Download zsh source package to the packages directory
	wget $(WGET_OPTIONS) https://www.zsh.org/pub/$(ZSH_ARCHIVE)

oh-my-zsh: $(HOME)/.oh-my-zsh
	# oh-my-zsh is installed

$(HOME)/.oh-my-zsh: ${PACKAGE_DIR}/oh-my-zsh/install.sh
	# Install oh-my-zsh using its installation script
	cd ${PACKAGE_DIR}/oh-my-zsh && CHSH=NO RUNZSH=NO ./install.sh

${PACKAGE_DIR}/oh-my-zsh/install.sh: | ${PACKAGE_DIR}/oh-my-zsh
	# Download oh-my-zsh installation script to the packages subdirectory
	cd $| && wget --timestamping https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh && chmod 700 install.sh

${PACKAGE_DIR}/oh-my-zsh:
	# Create subdirectory for oh-my-zsh installation script
	mkdir -p ${PACKAGE_DIR}/oh-my-zsh

# * Miscellaneous

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

# * Spacemacs installation tarball

.PHONY: create-spacemacs-installation-tarball

HOST_SPEC=$(shell hostname)
EMACS_SPEC=emacs-$(shell emacs --version | head -n 1 | grep --only-matching "[[:digit:]]\+[.][^ ]\+")
SPACEMACS_REPO_SPEC=spacemacs-$(shell ./repo-spec.sh $(LOCAL_GITHUB_REPOS_DIR)/spacemacs)
SPACEMACS_CONFIG_REPO_SPEC=spacemacs-config-$(shell ./repo-spec.sh $(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config)
TIMESTAMP=$(shell date +"%Y%m%d-%H%M%S")

SPACEMACS_INSTALL_ARCHIVE=$(HOST_SPEC)-$(EMACS_SPEC)-$(SPACEMACS_REPO_SPEC)-$(SPACEMACS_CONFIG_REPO_SPEC)-$(TIMESTAMP).tgz

create-spacemacs-installation-tarball:
	tar cvzf $(PACKAGE_DIR)/$(SPACEMACS_INSTALL_ARCHIVE) -C $(LOCAL_GITHUB_REPOS_DIR) spacemacs/ spacemacs-config/
