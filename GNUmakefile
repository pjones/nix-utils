################################################################################
# Some variables that can be changed from the outside:
NIXPKGS_REPO ?= $(HOME)/.nix-defexpr/custom/nixpkgs
BIN_DEST     ?= $(HOME)/bin

################################################################################
# Some variables that will be needed:
HOSTNAME  = $(shell hostname)
BIN_FILES = $(shell find bin -type f)

################################################################################
# All remaining Nix commands should use this NIX_PATH.
export NIX_PATH=nixpkgs=$(NIXPKGS_REPO)

################################################################################
.PHONEY: all install install-packages

################################################################################
all:
	@ echo "Nothing here.  Try \`make install' instead."

################################################################################
ifeq ($(wildcard hosts/$(HOSTNAME).nix),)
install-packages:
	$(error "no host.nix file for $(HOSTNAME)")
else
install-packages:
# FIXME: add: --option extra-binary-cache http://localhost:5000
	nix-env -f hosts/$(HOSTNAME).nix -ir
endif

################################################################################
# $1: Source file.
# $2: Destination directory.
# $3: Mode (optional, default: 0644).
define INSTALL_FILE
install: $(2)/$(notdir $(1))
$(2)/$(notdir $(1)): $(1)
	@ mkdir -p $(2)
	install -m $(if $(3),$(3),0644) $$< $$@
endef

################################################################################
$(foreach f,$(BIN_FILES),$(eval $(call INSTALL_FILE,$(f),$(BIN_DEST),0755)))
