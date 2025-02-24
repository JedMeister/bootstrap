About
=====

This project builds a Debian ``bootstrap`` for use as a base for
building TurnKey GNU/Linux appliances.

A ``bootstrap`` is the minimal root filesystem in which packages can
be installed. TurnKey uses ``debootstrap`` to build a default
"minbase" variant Debian bootstrap, with the addition of a couple of
packages.

For further info please run::

    make help

Current supported architectures are:
- amd64 (aka x86_64)
- arm64 (aka aarch64)

An amd64 host can build both amd64 & arch64; an arm64 host can only build
arm64.

Build & copy to bootstraps directory
====================================

If you are building a bootstrap for local use only, then it is not necessary
to do a complete ``make`` (which will generate a tarball as noted below).
Instead you can just build to the ``install`` target.

That will build the bootstrap, remove the pre-set list of files noted
within the removelist file and copy the bootstrap to
``$FAB_PATH/bootstraps/$(basename $RELEASE-$ARCH)``::

    make clean
    make install

Build arm64 bootstrap on amd64
==============================

The default action is to build a bootstrap with the same architecture as the
host. However, it is possible to build an arm64 (aka aarch64) bootstrap on an
amd64 (aka x86_64) system.

Dependencies
------------

To build a bootstrap for an architechture the same as the host, ``debootstrap``
is the only package required.

To build arm64 bootstrap on amd64, the following packages are required:

- qemu-system-arm
- qemu-user-static
- binfmt-support

Assuming fab is installed (as it is by default on TKLDev), a
``install-arm-on-amd-deps`` contib script will check that they are installed
and install them if needed.

Usage
-----

By default ``make`` will build the architecture of the host system. To build
arm64 on amd64, set ``FAB_ARCH=arm64``

E.g.::

    FAB_ARCH=64 make install
