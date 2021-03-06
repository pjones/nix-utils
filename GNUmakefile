################################################################################
# Some variables that can be changed from the outside:
NIXPKGS_REPO ?= $(HOME)/.nix-defexpr/custom/nixpkgs
FIRMWARE_DIR ?= $(HOME)/documents/disk-images/firmware
BIN_DEST     ?= $(HOME)/bin
LIB_DEST     ?= $(HOME)/.nixpkgs/lib
ENV_DEST     ?= $(HOME)/.nixpkgs/envs

################################################################################
# Some variables that will be needed:
HOSTNAME  = $(shell hostname)
BIN_FILES = $(shell find bin  -type f)
LIB_FILES = $(shell find lib  -type f)
ENV_FILES = $(shell find envs -type f)

################################################################################
# All remaining Nix commands should use this NIX_PATH.
export NIX_PATH=nixpkgs=$(NIXPKGS_REPO)

################################################################################
.PHONEY: all install install-packages

################################################################################
all:
	@ $(MAKE) install

################################################################################
ifeq ($(wildcard hosts/$(HOSTNAME).nix),)
install-packages:
	$(error "no host.nix file for $(HOSTNAME)")
else
install-packages:
# FIXME: add: --option extra-binary-cache http://localhost:5000
	find $(FIRMWARE_DIR) -type f -exec nix-prefetch-url 'file://{}' ';'
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
# Creates a destination directory name that includes the parent
# directory of the given file name.
#
# $1: Destination directory.
# $2: File name.
define SUBDIR_DEST
$(1)/$(notdir $(shell dirname $(2)))
endef

################################################################################
$(foreach f,$(BIN_FILES),$(eval $(call INSTALL_FILE,$(f),$(BIN_DEST),0755)))
$(foreach f,$(LIB_FILES),$(eval $(call INSTALL_FILE,$(f),$(call SUBDIR_DEST,$(LIB_DEST),$(f)),0644)))
$(foreach f,$(ENV_FILES),$(eval $(call INSTALL_FILE,$(f),$(call SUBDIR_DEST,$(ENV_DEST),$(f)),0644)))
