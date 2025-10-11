#!/usr/bin/make -f
# Copyright (c) 2020-2025 TurnKey GNU/Linux - https://www.turnkeylinux.org

HOST_DISTRO := $(shell lsb_release -si | tr [A-Z] [a-z])
HOST_CODENAME := $(shell lsb_release -sc)
HOST_RELEASE := $(HOST_DISTRO)/$(HOST_CODENAME)
HOST_ARCH := $(shell dpkg --print-architecture)

ifndef BOOTSTRAPS_PATH
ifndef FAB_PATH
ifdef SUDO_USER
$(info running via sudo - BOOTSTAPS_PATH or FAB_PATH need to be set)
endif
$(error neither BOOTSTAPS_PATH or FAB_PATH are set)
else
BOOTSTRAPS_PATH := $(FAB_PATH)/bootstraps
endif
endif

ifndef RELEASE
$(info RELEASE not defined - falling back to system: '$(HOST_RELEASE)')
RELEASE := $(HOST_RELEASE)
endif

ifndef FAB_ARCH
$(info FAB_ARCH not defined - falling back to system: '$(HOST_ARCH)')
FAB_ARCH := $(HOST_ARCH)
endif

ifneq ($(FAB_ARCH),$(HOST_ARCH))
$(info building $(FAB_ARCH) on $(HOST_ARCH))
ifeq ($(HOST_ARCH),arm64)
$(error amd64 bootstrap can not be built on arm64)
else
ARM_ON_AMD := y
endif
endif

DISTRO ?= $(shell dirname $(RELEASE))
CODENAME ?= $(shell basename $(RELEASE))

MIRROR ?= http://deb.debian.org/debian
VARIANT ?= minbase
EXTRA_PKGS ?= initramfs-tools,gpg,gpg-agent,ca-certificates,lsb-release,zstd
REMOVELIST ?= ./removelist

# build output path
O ?= build

.PHONY: all
all: $O/bootstrap-$(FAB_ARCH).tar.gz

help:
	@echo '=== Configurable variables'
	@echo 'Resolution order:'
	@echo '1) command line (highest precedence)'
	@echo '2) product Makefile'
	@echo '3) environment variable'
	@echo '4) built-in default (lowest precedence)'
	@echo
	@echo '# Required environment/configuration variables'
	@echo '# - one of:'
	@echo '  BOOTSTRAPS_PATH            $(value BOOTSTRAPS_PATH)'
	@echo '                             root directory to rsync bootstrap to'
	@echo '  FAB_PATH                   $(value FAB_PATH)'
	@echo '                             if BOOTSTRAPS_PATH not set, will'
	@echo '                               fallback to FAB_PATH/bootstraps'
	@echo
	@echo '# Recommended configuration variables:'
	@echo '  RELEASE                    $(value RELEASE)'
	@echo '                             if not set, will fall back to system:'
	@echo '                             	$(value HOST_RELEASE)'
	@echo
	@echo '# Build context variables'
	@echo '  FAB_ARCH                   $(value FAB_ARCH)'
	@echo '                             if not set, will fall back to system:'
	@echo '                                 $(value HOST_ARCH)'
	@echo '  MIRROR                     $(value MIRROR)'
	@echo '  VARIANT                    $(value VARIANT)'
	@echo '  EXTRA_PKGS                 $(value EXTRA_PKGS)'
	@echo '  REMOVELIST                 $(value REMOVELIST)'
	@echo
	@echo '# Product output variables   [VALUE]'
	@echo '  O                          $(value O)/'
	@echo
	@echo '=== Usage'
	@echo '# remake target and the targets that depend on it'
	@echo '$$ make <target>'
	@echo
	@echo '# build a target (default: bootstrap.tar.gz)'
	@echo '$$ make [target] [O=path/to/build/dir]'
	@echo
	@echo '  clean            # clean all build targets'
	@echo '  bootstrap        # build bootstrap with debootstrap'
	@echo '  show-packages    # show packages installed in bootstrap'
	@echo '  removelist       # apply removelist'
	@echo '  install          # rsymc bootstrap to FAB_PATH/bootstraps/CODENAME-ARCH'
	@echo '  bootstrap.tar.gz # build tarball from bootstrap'

.PHONY: clean
clean:
	rm -rf $O/bootstrap*

.PHONY: show-packages
show-packages: $O/bootstrap
	fab-chroot build/bootstrap-* "dpkg -l | grep ^ii"

$O/bootstrap-$(FAB_ARCH):
	mkdir -p $O
ifneq ($(HOST_CODENAME), $(CODENAME))
	@echo
	@echo '***Note: OS release transition may require a newer version of `debootstrap`.'
	@echo
endif

ifdef ARM_ON_AMD
	qemu-debootstrap --arch=$(FAB_ARCH) --variant=$(VARIANT) --include=$(EXTRA_PKGS) $(CODENAME) $O/bootstrap-$(FAB_ARCH) $(MIRROR)
else
	debootstrap --arch=$(FAB_ARCH) --variant=$(VARIANT) --include=$(EXTRA_PKGS) $(CODENAME) $O/bootstrap-$(FAB_ARCH) $(MIRROR)
endif

.PHONY: bootstrap-$(FAB_ARCH)
bootstrap: $O/bootstrap-$(FAB_ARCH)

.PHONY: removelist
removelist: $O/bootstrap-$(FAB_ARCH)
	fab-apply-removelist $(REMOVELIST) $O/bootstrap-$(FAB_ARCH)

$O/bootstrap-$(FAB_ARCH).tar.gz: removelist
	tar -C $O/bootstrap-$(FAB_ARCH) -zcf $O/bootstrap-$(FAB_ARCH).tar.gz .

.PHONY: bootstrap-$(FAB_ARCH).tar.gz
bootstrap-$(FAB_ARCH).tar.gz: $O/bootstrap-$(FAB_ARCH).tar.gz

.PHONY: install
install: removelist
	mkdir -p $(BOOTSTRAPS_PATH)
	rsync --delete -Hac $O/bootstrap-$(FAB_ARCH)/ $(BOOTSTRAPS_PATH)/$(shell basename $(CODENAME))-$(FAB_ARCH)/
