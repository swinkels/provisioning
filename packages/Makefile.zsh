# -*- mode: Makefile -*-
# -*- eval: (outline-minor-mode); outline-regexp: "# [*]+"; -*-

# This file defines
#
# - the variables needed to retrieve and install yadm and
# - the extra target to retrieve and install my personal set of dotfiles.

PACKAGE_VERSION=5.8
PACKAGE_URL=https://www.zsh.org/pub/zsh-$(PACKAGE_VERSION).tar.xz
PACKAGE_TYPE=configure
# The default uncompress command expects .tar.gz archives. As the Zsh archive is
# a tar.xz one, we override the default.
PACKAGE_UNCOMPRESS_COMMAND=tar xf $<
PACKAGE_ARCHIVE_DIR=zsh-$(PACKAGE_VERSION)
PACKAGE_ARCHIVE_TARGET=Src/zsh
PACKAGE_STOW_TARGET=bin/zsh

PACKAGE_POSTPROCESS_TARGETS=call-zsh-from-bash-profile $(HOME)/.oh-my-zsh

.PHONY: call-zsh-from-bash-profile

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

call-zsh-from-bash-profile: export LINE_TO_ADD=$(EXEC_LOCAL_ZSH)
call-zsh-from-bash-profile:
	@if ! grep -q "export SHELL=~/.local/bin/zsh" $(BASH_PROFILE) ; then \
	  @echo "# Update bash profile to call zsh" \
		echo -e "$$LINE_TO_ADD\n`cat $(BASH_PROFILE)`" > $(BASH_PROFILE) ; \
	fi

$(HOME)/.oh-my-zsh: $(WORKBENCH_PATH)/oh-my-zsh/install.sh
	# Install Oh My Zsh using its installation script
	cd $(WORKBENCH_PATH)/oh-my-zsh && chmod u+x install.sh && ./install.sh --unattended --keep-zshrc

$(WORKBENCH_PATH)/oh-my-zsh/install.sh: | $(WORKBENCH_PATH)/oh-my-zsh
	# Download Oh My Zsh installation script
	cd $| && wget --quiet --timestamping https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh

$(WORKBENCH_PATH)/oh-my-zsh:
	# Create subdirectory for Oh My Zsh installation script
	mkdir -p ${PACKAGE_DIR}/oh-my-zsh
