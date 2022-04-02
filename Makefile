# -*- eval: (outline-minor-mode); outline-regexp: "# [*]+"; -*-

# * Includes

include Makefile.shared
include $(MAKEFILE_PATH)/packages/Makefile.packages

# * Default target

# If you don't specify a target on the command-line, this Makefile falls back to
# target ~no-target~. That target lets ~make~ abort with the error message to
# specify an explicit target.

.PHONY: no-target

no-target:
	$(error Please specify an explicit target)

# * Provisioning targets

.PHONY: nunhems

# Some targets have to run before others. Currently (target) ~stow~ runs first
# as stow is used to install most of the other packages. ~git~ runs second as
# git is used to retrieve the software for other targets. ~yadm~ runs third as
# yadm provides configurations for other software: with those configurations
# already in place, that software can start fully configured.

# The machines at Nunhems cannot reach elpa so on these machines, you cannot
# install spacemacs from scratch using target ~spacemacs~. To work around that,
# targets ~$(HOME)/.emacs.d~ and ~$(HOME)/.spacemacs.d~ install an existing
# installation that was transferred from another machine.

nunhems: stow git yadm keychain zsh fzf restic ripgrep tmux pipx $(HOME)/.emacs.d $(HOME)/.spacemacs.d pyls

	# The following packages should be available: $^

# * Application installation & configuration

.PHONY: $(AVAILABLE_PACKAGES) $(AVAILABLE_PACKAGES:%=%-uninstall)

$(PACKAGE_DEPENDENCIES)

$(AVAILABLE_PACKAGES): %:
	$(MAKE) -f Makefile.build --no-print-directory $@

$(AVAILABLE_PACKAGES:%=%-uninstall): %:
	$(MAKE) -f Makefile.build --no-print-directory $@

# ** emacs

.PHONY: emacs

# Emacs 27.x (and newer) has "natively compiled" support for handling JSON data.
# This means that it can handle JSON via the much quicker C library ~jansson~
# instead of Elisp. Especially the communication from and to language servers
# should see a performance boost. Target ~jansson~ downloads, builds and
# installs that C library.

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

emacs: jansson ~/.local/bin/emacs

~/.local/bin/emacs: $(STOW_DIR)/$(EMACS_ARCHIVE_DIR)/bin/emacs
	# Install Emacs using Stow
	[ -L $@ ] && [ -e $@ ] || stow $(EMACS_ARCHIVE_DIR)

$(STOW_DIR)/$(EMACS_ARCHIVE_DIR)/bin/emacs: $(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR)/src/emacs
	# Install Emacs to Stow directory
	cd $(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR) && make install

# ~configure~ looks at the path of environment variable ~PKG_CONFIG_PATH~ to
# determine whether ~jansson~ is installed. As we installed ~jansson~ locally,
# we set it accordingly.
$(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR)/src/emacs: export PKG_CONFIG_PATH=$(HOME)/.local/lib/pkgconfig
$(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR)/src/emacs: | $(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR)
	# Build Emacs from source
	cd $| && ./configure $(CONFIGURE_OPTIONS) $(EMACS_EXTRA_CONFIGURE_OPTIONS) --prefix=$(STOW_DIR)/$(EMACS_ARCHIVE_DIR) # && make

$(PACKAGE_DIR)/$(EMACS_ARCHIVE_DIR): $(PACKAGE_DIR)/$(EMACS_ARCHIVE)
	# Uncompress Emacs source package
	tar xzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(EMACS_ARCHIVE):
	# Download Emacs source package to the packages directory
	wget $(WGET_OPTIONS) http://ftp.snt.utwente.nl/pub/software/gnu/emacs/$(EMACS_ARCHIVE)

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

# ** graphviz

.PHONY: graphviz

GRAPHVIZ_VERSION=2.49.1
GRAPHVIZ_ARCHIVE_DIR=graphviz-$(GRAPHVIZ_VERSION)
GRAPHVIZ_ARCHIVE=$(GRAPHVIZ_ARCHIVE_DIR).tar.gz

graphviz: ~/.local/bin/graphviz

~/.local/bin/graphviz: $(STOW_DIR)/$(GRAPHVIZ_ARCHIVE_DIR)/bin
	# Install graphviz using Stow
	stow $(GRAPHVIZ_ARCHIVE_DIR) && touch $@

$(STOW_DIR)/$(GRAPHVIZ_ARCHIVE_DIR)/bin: $(PACKAGE_DIR)/$(GRAPHVIZ_ARCHIVE_DIR)/cmd/dot
	# Install graphviz to Stow directory
	cd $(PACKAGE_DIR)/$(GRAPHVIZ_ARCHIVE_DIR) && make install

$(PACKAGE_DIR)/$(GRAPHVIZ_ARCHIVE_DIR)/cmd/dot: | $(PACKAGE_DIR)/$(GRAPHVIZ_ARCHIVE_DIR)
	# Build graphviz from source
	cd $| && ./configure $(CONFIGURE_OPTIONS) --prefix=$(STOW_DIR)/$(GRAPHVIZ_ARCHIVE_DIR) && make

$(PACKAGE_DIR)/$(GRAPHVIZ_ARCHIVE_DIR): $(PACKAGE_DIR)/$(GRAPHVIZ_ARCHIVE)
	# Uncompress graphviz source package
	tar xzf $< -C $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(GRAPHVIZ_ARCHIVE):
	# Download graphviz source package to the packages directory
	wget $(WGET_OPTIONS) https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/$(GRAPHVIZ_VERSION)/$(GRAPHVIZ_ARCHIVE)

# ** pipx

ifeq ($(HOSTNAME), bioinformatics-dev.adpa6.local)
PYTHON=python3.8
else
PYTHON=python
endif

pipx: ~/.local/bin/pipx

~/.local/bin/pipx:
	# Install pipx using pip
	$(PYTHON) -m pip install --user pipx

# ** spacemacs

# Target ~spacemacs~ clones spacemacs and my spacemacs configuration to a custom
# stow directory - ~SPACEMACS_STOW_DIR~ defined below - and stows them in the root
# of my home directory. Companion target ~spacemacs-unstow~ unstows them.

# Stow makes it easy to try out the latest spacemacs: you 1) unstow the current
# spacemacs installation, 2) clone the latest spacemacs and my spacemacs
# configuration to another stow directory and 3) stow them. If you want to revert
# to the previous spacemacs installation, you unstow the current one and stow the
# previous one. Note that this workflow is not automated behind a target.

.PHONY: spacemacs spacemacs-unstow

SPACEMACS_COMMIT=500335a
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
	cd $@ && git checkout $(SPACEMACS_COMMIT)

$(SPACEMACS_STOW_DIR)/.spacemacs.d:
	# Clone my spacemacs config to its Stow directory
	git clone git@github.com:swinkels/spacemacs-config.git $@

install-spacemacs-dependencies:
	# sudo apt-get install -y fonts-powerline

# Target ~spacemacs-create-tarball~ creates a tarball from the Spacemacs
# directories at ~$(GIT_REPOS_DIR)/spacemacs-production~. The primary reason to
# create this target was to be able to transfer a working Spacemacs installation
# to a machine that could not access elpa (and therefore could not download the
# required Emacs packages).

# As a bonus, the tarball allows you to install a working installation on any
# machine in a known-good state. With a fresh installation that downloads the
# latest versions of its dependent packages there's a change things don't work
# as expected.

# The target creates the tarball in the packages/ subdirectory and names it
# according to the scheme defined in variable ~SPACEMACS_INSTALL_ARCHIVE~, e.g.
#
#   martin-emacs-27.1-spacemacs-679040f-spacemacs-config-43e1844-20210501-093008.tgz

.PHONY: spacemacs-create-tarball

HOST_SPEC=$(shell hostname)
EMACS_SPEC=emacs-$(shell emacs --version | head -n 1 | grep --only-matching "[[:digit:]]\+[.][^ ]\+")
SPACEMACS_REPO_SPEC=spacemacs-$(shell ./repo-spec.sh $(SPACEMACS_STOW_DIR)/.emacs.d)
SPACEMACS_CONFIG_REPO_SPEC=spacemacs-config-$(shell ./repo-spec.sh $(SPACEMACS_STOW_DIR)/.spacemacs.d)
TIMESTAMP=$(shell date +"%Y%m%d-%H%M%S")

SPACEMACS_INSTALL_ARCHIVE=$(HOST_SPEC)-$(EMACS_SPEC)-$(SPACEMACS_REPO_SPEC)-$(SPACEMACS_CONFIG_REPO_SPEC)-$(TIMESTAMP).tgz

spacemacs-create-tarball:
	tar cvzf $(PACKAGE_DIR)/$(SPACEMACS_INSTALL_ARCHIVE) -C $(GIT_REPOS_DIR) spacemacs-production

.PHONY: pyls

PYLS_VERSION=0.36.2

pyls: ~/.local/bin/pyls

~/.local/bin/pyls: ~/.local/bin/pipx
	# Install pyls using pipx
	pipx install python-language-server==$(PYLS_VERSION)
	# Install flake8 in the virtualenv of pyls
	pipx inject python-language-server flake8

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
	cd $< && ./configure $(CONFIGURE_OPTIONS) --prefix=$(HOME)/.local && make

$(PACKAGE_DIR)/$(STOW_ARCHIVE_DIR): $(PACKAGE_DIR)/$(STOW_ARCHIVE)
	# Uncompress stow source package
	tar xzf $< --directory $(PACKAGE_DIR)

$(PACKAGE_DIR)/$(STOW_ARCHIVE):
	# Download stow source package to the packages directory
	wget $(WGET_OPTIONS) https://ftp.gnu.org/gnu/stow/$(STOW_ARCHIVE)

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
