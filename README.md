# Clear NDR Community

## Overview

This repository contains the ressources and tools needed to build ISO images for the Clear NDR Community, a Linux distribution focused on network detection and response (NDR).

The repository was previously known as SELKS but has been rebranded to Clear NDR Community to better reflect profound architectural changes. See the [Clear NDR Community](https://www.stamus-networks.com/clear-ndr-community/) page on Stamus Networks website for more details.

To get more information about Clear NDR and learn how to use it, please visit [Clear NDR documentation](https://docs.clearndr.io).

## Source Code

This repository is used to build the ISO images for Clear NDR Community. It contains a script and the associated configuration files to build the ISO images.

Clear NDR is using [stamusctl](https://github.com/StamusNetworks/stamusctl) to manage the installation and configuration of the system. The configuration files used by stamusctl are stored in a separate repository:
[Stamusctl Templates](https://github.com/StamusNetworks/stamusctl-templates/tree/main/data/clearndr).

Please use the [stamusctl](https://github.com/StamusNetworks/stamusctl/issues) repository to open issues related to Clear NDR Community.

## Building the ISO

To build the ISO images, you need to have a working installation of [Debian](https://www.debian.org). The build process has been tested on Debian 11 (Bullseye). You will also need to install the dependencies via the install-deps.sh script:

```sh
sudo ./install-deps.sh
```

To build the ISO image, clone this repository and run the build script:

```sh
sudo ./build-debian-live.sh
```

To build the headless ISO image, run the build script with the `-g no-desktop` option:

```sh
sudo ./build-debian-live.sh -g no-desktop
```

For help and more options, run:

```sh
./build-debian-live.sh -h
```
