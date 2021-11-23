# -*- mode: Makefile -*-
# -*- eval: (outline-minor-mode); outline-regexp: "# [*]+"; -*-

PACKAGE_VERSION=3.20.0
PACKAGE_URL=https://github.com/Kitware/CMake/releases/download/v$(PACKAGE_VERSION)/cmake-$(PACKAGE_VERSION).tar.gz
PACKAGE_TYPE=configure
PACKAGE_CONFIGURE_COMMAND=./bootstrap --prefix=$(PACKAGE_STOW_PATH)
PACKAGE_ARCHIVE_DIR=cmake-$(PACKAGE_VERSION)
PACKAGE_ARCHIVE_TARGET=git
PACKAGE_STOW_TARGET=bin/cmake
