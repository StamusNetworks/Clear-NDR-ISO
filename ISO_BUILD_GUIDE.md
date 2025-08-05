# SELKS ISO Generation System - Complete Guide

## Overview

This repository contains the tooling to build bootable Debian Live ISO images for SELKS (Suricata + ELK Stack + Scirius). The system creates a custom Debian Bookworm-based Linux distribution that can run live from USB/CD or be installed to disk.

## What is This System

Think of this system like a factory that builds a special version of Linux:

1. **Base Ingredients**: We start with regular Debian Linux (like flour for baking)
2. **Custom Recipe**: We add special software and configurations (like adding chocolate chips)
3. **Packaging**: We wrap it all up into an ISO file (like putting cookies in a box)
4. **Final Product**: You get a bootable USB/CD that runs SELKS

The ISO can either:

- Run "live" (temporary, everything resets when you reboot)
- Be installed permanently to a hard drive

## Quick Start (Docker Method - Recommended)

If you just want to build an ISO quickly using Docker:

```bash
# Make sure Docker is running
docker --version

# Build a standard SELKS ISO
./build-iso-docker.sh

# The ISO will be created at ./output/ClearNDR.iso
```

That's it! The script handles everything automatically. For more options and native builds, see the detailed sections below.

## Key Technologies Explained

### Debian Live-Build

- **What**: Official Debian tool for creating custom Linux distributions
- **Purpose**: Automates the complex process of building bootable ISOs
- **How**: Uses configuration files to specify what packages to install and how to configure them

### Chroot (Change Root)

- **What**: A way to create a "fake" Linux environment inside another Linux system
- **Purpose**: Lets us install and configure software for the ISO without affecting the host system
- **Think of it as**: A sandbox where we build our custom Linux

### Debootstrap

- **What**: Tool that downloads and installs a minimal Debian system
- **Purpose**: Creates the foundation of our custom Linux distribution
- **Process**: Downloads packages from Debian repositories and sets up basic filesystem

## Directory Structure Explained

```
/
├── build-debian-live.sh           # Main build script (native build)
├── build-iso-docker.sh            # Docker build script
├── Dockerfile                     # Docker image definition
├── install-deps.sh                # Installs required build tools
├── staging/                       # Template files for customization
│   ├── config/                    # Build configuration
│   │   ├── hooks/                 # Scripts that run during build
│   │   └── includes.chroot/       # Files copied to final system
│   ├── etc/                       # System configuration files
│   ├── usr/                       # User applications and data
│   └── wallpaper/                 # Desktop backgrounds
├── Stamus-Live-Build/             # Working directory (created during build)
│   ├── config/                    # Live-build configuration
│   ├── chroot/                    # The "fake" Linux system being built
│   ├── cache/                     # Downloaded packages (for faster rebuilds)
│   └── binary/                    # Final ISO components
└── output/                        # Output directory for Docker builds
    ├── ClearNDR.iso               # Final ISO file
    ├── ClearNDR.iso.sha256        # SHA256 checksum
    └── ClearNDR.iso.md5           # MD5 checksum
```

## Build Process Step-by-Step

### Phase 1: Preparation (Host System)

1. **Dependency Installation** (`install-deps.sh`)

    - Installs live-build, xorriso, squashfs-tools
    - These are the tools needed to build ISOs

2. **Directory Setup**
    - Creates `Stamus-Live-Build/` working directory
    - Sets up configuration structure

### Phase 2: Configuration

1. **Base System Configuration**

    - Architecture: amd64 (64-bit)
    - Distribution: Debian Bookworm
    - Bootloader: Syslinux
    - Installer: Debian installer with live capabilities

2. **Package Selection**

    - Core system packages (networking, security tools)
    - GUI packages (XFCE desktop environment)
    - Development tools (compilers, libraries)
    - SELKS-specific software

3. **Custom Files Setup**
    - Copies desktop shortcuts
    - Adds custom wallpapers
    - Sets up configuration files
    - Installs polkit policies for user permissions

### Phase 3: Chroot Environment Creation

1. **Bootstrap** (via debootstrap)

    - Downloads minimal Debian system
    - Creates base filesystem in `chroot/`

2. **Package Installation**

    - Installs all specified packages into chroot
    - Resolves dependencies automatically

3. **Custom Configuration** (via hooks)
    - Runs `chroot-inside-Debian-Live.hook.chroot`
    - Sets passwords, hostnames, services
    - Installs additional software (Docker, Clear NDR Community tools)
    - Configures first-boot scripts

### Phase 4: ISO Assembly

1. **Filesystem Creation**

    - Creates compressed filesystem (squashfs) from chroot
    - This becomes the "live" system

2. **Boot Configuration**

    - Sets up bootloader (syslinux)
    - Creates boot menus for live/install options
    - Adds splash screen

3. **ISO Generation**
    - Combines filesystem, bootloader, and installer
    - Creates final `.iso` file

## Key Files and Their Roles

### Main Scripts

- **`build-debian-live.sh`**: Master orchestrator script (native build)
- **`build-iso-docker.sh`**: Docker-based build script (recommended)
- **`install-deps.sh`**: Installs build dependencies (for native builds)
- **`staging/config/hooks/live/chroot-inside-Debian-Live.hook.chroot`**: Runs inside chroot to customize system

### Configuration Templates

- **`staging/etc/`**: System configuration files
- **`staging/usr/share/applications/`**: Desktop application shortcuts
- **`staging/config/hooks/live/firstboot.sh`**: Script that runs on first boot

### Package Lists (Generated)

- **`StamusNetworks-CoreSystem.list.chroot`**: Essential system packages
- **`StamusNetworks-Tools.list.chroot`**: Network monitoring tools
- **`StamusNetworks-Gui.list.chroot`**: Desktop environment packages

## Build Options

### Native Build (Traditional Method)

#### Basic Build

```bash
sudo ./build-debian-live.sh
```

Creates standard SELKS ISO with default kernel and full desktop.

#### Custom Kernel

```bash
sudo ./build-debian-live.sh -k 6.5
```

Uses specific kernel version (downloads and compiles from kernel.org).

#### No Desktop

```bash
sudo ./build-debian-live.sh -g no-desktop
```

Creates server-only version without GUI.

#### Additional Packages

```bash
sudo ./build-debian-live.sh -p "package1 package2"
```

Adds extra packages to the build.

### Docker Build (Recommended Method)

The Docker-based build provides a consistent, isolated environment and eliminates host system dependencies.

#### Prerequisites

- Docker installed and running
- At least 10GB free disk space
- Internet connection for package downloads

#### Simple Docker Build

```bash
./build-iso-docker.sh
```

Creates standard SELKS ISO using Docker. The ISO will be saved to `./output/ClearNDR.iso`.

#### Docker Build with Options

```bash
./build-iso-docker.sh -g no-desktop     # Server-only build
./build-iso-docker.sh -k 6.5            # Custom kernel
./build-iso-docker.sh -p "vim htop"     # Add extra packages
```

#### Docker Build Advantages

- **Isolation**: Build doesn't affect host system
- **Consistency**: Same environment every time
- **Portability**: Works on any system with Docker
- **Safety**: No need for root privileges on host
- **Cleanup**: Easy to clean up build artifacts

## Current Issues and Improvement Plan

### Issues Identified

1. **Build Script Complexity**

    - Single monolithic script (434 lines)
    - Hard to maintain and debug
    - Limited error handling

2. **Configuration Management**

    - Hard-coded values scattered throughout
    - No centralized configuration
    - Difficult to customize

3. **Documentation**

    - Limited inline documentation
    - No architecture documentation
    - Hard for new maintainers to understand

4. **Build Reliability**

    - Limited error checking
    - No build validation
    - Hard to troubleshoot failures

5. **Resource Management**
    - No cleanup of temporary files
    - Large disk space requirements
    - No caching optimization

### Improvement Plan

#### Phase 1: Restructure and Modularize (Weeks 1-2)

1. **Split Main Script**

    ```
    build-debian-live.sh  →  scripts/
    ├── 00-validate-environment.sh
    ├── 10-setup-build-directory.sh
    ├── 20-configure-live-build.sh
    ├── 30-setup-packages.sh
    ├── 40-copy-customizations.sh
    ├── 50-build-iso.sh
    └── 90-cleanup.sh
    ```

2. **Centralize Configuration**

    ```
    config/
    ├── build.conf              # Main build configuration
    ├── packages/
    │   ├── core.list
    │   ├── tools.list
    │   ├── gui.list
    │   └── optional.list
    └── customizations/
        ├── users.conf
        ├── services.conf
        └── branding.conf
    ```

3. **Improve Error Handling**
    - Add validation functions
    - Better error messages
    - Rollback capabilities
    - Build logging

#### Phase 2: Enhanced Features (Weeks 3-4)

1. **Build Validation**

    - Pre-build environment checks
    - Post-build ISO validation
    - Automated testing framework

2. **Caching System**

    - Package download caching
    - Partial rebuild capabilities
    - Build artifact reuse

3. **Configuration Templates**
    - Jinja2-based templating
    - Environment-specific configs
    - Easy customization system

#### Phase 3: DevOps Integration (Weeks 5-6)

1. **CI/CD Pipeline**

    - Automated builds on Git changes
    - Multi-architecture support
    - Release automation

2. **Container-based Building**

    - Docker-based build environment
    - Consistent build results
    - Easy local development

3. **Monitoring and Metrics**
    - Build time tracking
    - Success/failure rates
    - Resource usage monitoring

## Immediate Action Items

### Week 1: Understanding and Documentation

1. **Complete Code Review**

    - Document all hooks and their purposes
    - Map all configuration files
    - Identify all dependencies

2. **Create Development Environment**

    - Set up build VM/container
    - Test current build process
    - Document gotchas and issues

3. **Backup and Version Control**
    - Ensure all code is in Git
    - Tag current working version
    - Create development branch

### Week 2: Quick Wins

1. **Add Validation**

    - Check for required tools before building
    - Validate available disk space
    - Check network connectivity

2. **Improve Logging**

    - Add timestamped logging
    - Separate error/info/debug levels
    - Log to files with rotation

3. **Configuration Cleanup**
    - Extract hard-coded values
    - Create configuration file
    - Add command-line options for common settings

### Tools and Resources You'll Need

1. **Development Environment**

    - Debian Bookworm VM with 4+ GB RAM
    - 50+ GB free disk space
    - Fast internet connection

2. **Documentation Tools**

    - Markdown editor
    - Diagram tools (draw.io, plantuml)
    - Screen recording for tutorials

3. **Testing Infrastructure**
    - VM hypervisor (VirtualBox, KVM)
    - USB testing devices
    - Various hardware for compatibility testing

## Key Learning Resources

1. **Debian Live Manual**: https://live-team.pages.debian.net/live-manual/
2. **Live-Build Documentation**: https://manpages.debian.org/testing/live-build/
3. **Debian Package Management**: https://www.debian.org/doc/manuals/debian-reference/ch02.en.html
4. **Chroot Tutorial**: https://help.ubuntu.com/community/BasicChroot

## Success Metrics

- **Build Reliability**: 95%+ success rate
- **Build Time**: <30 minutes for incremental builds
- **Maintainability**: New team member can make changes within 1 day
- **Documentation**: Complete coverage of all components
- **Testing**: Automated validation of all builds

This system, while complex, follows standard Debian practices and is built on solid foundations. With proper modularization and documentation, it can become much more maintainable and reliable.
