LOCAL_FONTS_DIR=$(HOME)/.local/share/fonts
LOCAL_GITHUB_REPOS_DIR=$(HOME)/repos/github.com

all: spacemacs-config

.PHONY: depends install-emacs-dependencies

depends: install-emacs-dependencies
	sudo apt-get install arc-theme fonts-noto

install-emacs-dependencies:
	sudo apt-get install build-essential
	sudo apt-get build-dep emacs25

EMACS_VERSION=26.1
EMACS_NAME=emacs-$(EMACS_VERSION)
EMACS_ARCHIVE=$(EMACS_NAME).tar.gz

emacs: $(HOME)/.local/bin/$(EMACS_NAME)

$(HOME)/.local/bin/$(EMACS_NAME): $(HOME)/external_software/$(EMACS_NAME) | $(HOME)/.local
	cd $< && ./configure --prefix=$(HOME)/.local && make && make install

$(HOME)/external_software/$(EMACS_NAME): $(HOME)/tmp/$(EMACS_ARCHIVE) | $(HOME)/external_software
	tar xvf $< -C $(HOME)/external_software

$(HOME)/tmp/$(EMACS_ARCHIVE): | $(HOME)/tmp
	cd $< && wget --timestamping http://ftp.snt.utwente.nl/pub/software/gnu/emacs/$(EMACS_ARCHIVE)

emacs-clean:
	- cd $(HOME)/external_software/$(EMACS_NAME) && make uninstall
	- rm -rf $(HOME)/external_software/$(EMACS_NAME)

spacemacs: $(HOME)/.emacs.d

$(HOME)/.emacs.d: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/syl20bnr/spacemacs.git

spacemacs-config: $(HOME)/.spacemacs $(LOCAL_GITHUB_REPOS_DIR)/oje

$(HOME)/.spacemacs: $(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config/.spacemacs
	ln -s $< $@

$(LOCAL_GITHUB_REPOS_DIR)/spacemacs-config: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/swinkels/spacemacs-config.git

$(LOCAL_GITHUB_REPOS_DIR)/oje: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $(LOCAL_GITHUB_REPOS_DIR) && git clone https://github.com/swinkels/oje.git

fonts: $(LOCAL_FONTS_DIR)/source-code-pro
	
$(LOCAL_FONTS_DIR)/source-code-pro: $(LOCAL_GITHUB_REPOS_DIR)/source-code-pro | $(LOCAL_FONTS_DIR)
	ln -s $< $@
	fc-cache -f -v $@

$(LOCAL_GITHUB_REPOS_DIR)/source-code-pro: | $(LOCAL_GITHUB_REPOS_DIR)
	cd $< && git clone --branch release --depth 1 https://github.com/adobe-fonts/source-code-pro.git

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
	
desktop-look:
	xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark"
	xfconf-query -c xfwm4 -p /general/theme -s "Arc-Dark"
	xfconf-query -c xfwm4 -p /general/title-font -s "Noto Sans Bold 9"
	xfconf-query -c xfwm4 -p /Gtk/FontName -s "Noto Sans 9"
	xfconf-query -c xsettings -p /Xfce/LastCustomDPI -s 101
	xfconf-query -c xsettings -p /Xft/AntiAlias -s 1
	xfconf-query -c xsettings -p /Xft/DPI -s 101
	xfconf-query -c xsettings -p /Xft/Hinting -s 1
	xfconf-query -c xsettings -p /Xft/HintStyle -s "hintmedium"
	xfconf-query -c xsettings -p /Xft/RGBA -s "rgba"

$(HOME)/.local $(LOCAL_FONTS_DIR) $(HOME)/tmp $(HOME)/external_software $(LOCAL_GITHUB_REPOS_DIR):
	mkdir -p $@
