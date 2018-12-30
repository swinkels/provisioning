

EMACS_VERSION=26.1
EMACS_NAME=emacs-$(EMACS_VERSION)
EMACS_ARCHIVE=$(EMACS_NAME).tar.gz

all: emacs

.PHONY: depends install-emacs-dependencies

depends: install-emacs-dependencies

install-emacs-dependencies:
	sudo apt-get install build-essential
	sudo apt-get build-dep emacs25

emacs: $(HOME)/.local/bin/$(EMACS_NAME)

$(HOME)/.local/bin/$(EMACS_NAME): $(HOME)/external_software/$(EMACS_NAME) $(HOME)/.local
	cd $< && ./configure --prefix=$(HOME)/.local && make && make install

$(HOME)/external_software/$(EMACS_NAME): $(HOME)/tmp/$(EMACS_ARCHIVE) $(HOME)/external_software
	tar xvf $< -C $(word 2,$^)

$(HOME)/tmp/$(EMACS_ARCHIVE): $(HOME)/tmp
	cd $< && wget --timestamping http://ftp.snt.utwente.nl/pub/software/gnu/emacs/$(EMACS_ARCHIVE)

emacs-clean:
	- cd $(HOME)/external_software/$(EMACS_NAME) && make uninstall
	- rm -rf $(HOME)/external_software/$(EMACS_NAME)

$(HOME)/.local $(HOME)/tmp $(HOME)/external_software:
	mkdir -p $@
