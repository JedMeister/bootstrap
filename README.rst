About
=====

This project builds a Debian ``bootstrap`` for use as the build base for
TurnKey GNU/Linux appliances.

A ``bootstrap`` is the minimal root filesystem in which packages can
be installed. TurnKey uses the default Debian ``debootstrap`` tool to build a
"minbase" variant Debian bootstrap, with the addition of a couple of packages.

Current supported architectures are:

- amd64 - aka x86_64
- arm64 - aka aarch64

An amd64 host can build both amd64 & arch64 bootstraps; an arm64 host can only
build arm64.

Install
=======

Requirements
------------

An internet connection is required to download the Debian packages when building
the bootstrap. There are also some dependencies that can be installed via apt.
If running on a non-TurnKey system you will need to add the TurnKey apt repo
to install the 2 TurnKey dependencies.


* TurnKey packages (from TurnKey apt repo):
    - fab
    - pool

* Debian packages - native arch builds - amd64 on amd64 / arm64 on arm64:
    - debootstrap

* Debian packages - arm64 built on amd64:
    - qemu-debootstrap
    - qemu-system-arm
    - qemu-user-static
    - binfmt-support

When building an arm64 bootstrap on amd64, the fab ``install-arm-on-amd-deps``
script can be used to install all deps.

** ``debootstrap`` Debian release transition note **

During a transition to a new Debian release occasionally you may need a newer
version of `debootstrap`` than the one packaged for your host system. If the
bootstrap fails to build for a Debian release newer than the host system, try
upgrading to the ``debootstrap`` version of the bootstrap you are building.
Installing a newer ``debootstrap`` deb is fine as it is a collection of shell
scripts with minimal dependencies.

Download the newer deb and install with apt. E.g. to install the Debian
14/Forky ``debootstrap`` package on a v19.x TKLDev (Debian 13/Trixie)::

    # where XXXX is the debootstrap version

    wget http://deb.debian.org/debian/pool/main/d/debootstrap/debootstrap_XXXX_all.deb
    apt update
    apt install ./debootstrap/debootstrap_XXXX_all.deb

Clone this repo
---------------

Once dependencies are installed, then simply clone this repo::

    cd /turnkey
    git clone https://github.com/turnkeylinux/bootstrap.git

Usage
=====

This project uses a Makefile so building is as simple as running ``make``. A
few common usage scenarios are covered below, but for full details about the
possible env vars that can be used to control the process can be viewed via::

    make help

Build and copy bootstrap
------------------------

When building a bootstrap for local use build to the ``install`` target. I.e.::

    make clean
    make install

That will build the bootstrap, remove the paths noted in the ``removelist``
and copy to a directory named ``<DEBIAN_CODENAME>-$ARCH`` in
``BOOTSTRAPS_PATH``. The default value of ``BOOTSTRAPS_PATH`` is
``$FAB_PATH/bootstraps/`` (usually ``/turnkey/fab/bootstraps/``) so the full
path of a trixie amd64 bootstrap will be
``/turnkey/fab/bootstraps/trixie-amd64/``

Build tarball
-------------

If you wish to share your bootstrap, do not specify a make target. With no
target noted, it will generate a tarball of the bootstrap as an additional
step. I.e.::

    make clean
    make

Build an alternate release bootstrap
------------------------------------

To build a bootstrap for a Debian release other than the host, set the value
of ``RELEASE``. E.g. to build a Debian forky release on a v19.x (trixie)
TKLDev::

    make clean
    RELEASE=debian/forky make install

Build arm64 bootstrap on amd64
------------------------------

To build a non-native arch bootstrap, set the value of ``FAB_ARCH``. E.g.
to build an arm64 forky bootstrap on v19.x TKLDev::

    make clean
    FAB_ARCH=arm64 RELEASE=debian/forky make install
