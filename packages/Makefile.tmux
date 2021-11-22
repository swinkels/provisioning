# -*- mode: Makefile -*-
# -*- eval: (outline-minor-mode); outline-regexp: "# [*]+"; -*-

# This file defines the variables needed to retrieve, build and install curl.

PACKAGE_VERSION=3.1b
PACKAGE_URL=https://github.com/tmux/tmux/releases/download/$(PACKAGE_VERSION)/tmux-$(PACKAGE_VERSION)-x86_64.AppImage
PACKAGE_TYPE=copy
# the archive doesn't have a root directory
# PACKAGE_ARCHIVE_DIR=
PACKAGE_ARCHIVE_TARGET=tmux-$(PACKAGE_VERSION)-x86_64.AppImage
PACKAGE_STOW_TARGET=bin/tmux
