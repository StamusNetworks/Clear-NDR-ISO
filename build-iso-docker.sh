#!/usr/bin/env bash

# Simple Docker-based SELKS ISO Builder
# Works with the existing Dockerfile in the repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
cat << EOF
Simple Docker-based SELKS ISO Builder

Usage: $0 [BUILD_OPTIONS]

BUILD_OPTIONS (passed directly to build-debian-live.sh):
   -g no-desktop         Build without desktop environment
   -k KERNEL_VERSION     Use specific kernel version
   -p "PACKAGES"         Add extra packages

Examples:
   $0                    # Basic build
   $0 -g no-desktop      # Server build
   $0 -k 6.5             # Custom kernel

The ISO will be created in ./output/ClearNDR.iso
EOF
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker is required but not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Create output directory
mkdir -p "$OUTPUT_DIR"

log_info "Building SELKS ISO using Docker..."
log_info "Output directory: $OUTPUT_DIR"

# Build Docker image from existing Dockerfile
log_info "Building Docker image..."
docker build -t selks-builder "$SCRIPT_DIR"

# Run the build in Docker
log_info "Starting ISO build (this may take 30-60 minutes)..."

docker run --rm -it \
    --privileged \
    --tmpfs /tmp:exec,dev,suid \
    --tmpfs /var/tmp:exec,dev,suid \
    --security-opt seccomp=unconfined \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$SCRIPT_DIR:/src" \
    -v "$OUTPUT_DIR:/output" \
    -w /build \
    selks-builder \
    bash -c "
        # Copy source to avoid modifying mounted volume
        cp -r /src/* /build/
        cd /build

        # Fix tmp directory permissions throughout the system
        chmod 1777 /tmp /var/tmp
        mkdir -p /build/Stamus-Live-Build/chroot/tmp /build/Stamus-Live-Build/chroot/var/tmp

        # Additional debug information
        echo '[DEBUG] Container environment check:'
        echo '[DEBUG] /tmp permissions:' && ls -ld /tmp
        echo '[DEBUG] /var/tmp permissions:' && ls -ld /var/tmp
        echo '[DEBUG] Available disk space:' && df -h
        echo '[DEBUG] Mount points:' && mount | grep tmp

        # Install additional dependencies
        apt-get update && apt-get install -y xorriso squashfs-tools python3-docutils wget fakeroot gcc libncurses5-dev bc ca-certificates pkg-config make flex bison build-essential autoconf automake aptitude curl

        # Start Docker daemon if not running (Docker-in-Docker support)
        if ! docker info &> /dev/null; then
            service docker start
            sleep 3
        fi

        # Verify Docker is working
        docker --version

        # Set environment to fix GPG issues in chroot
        export GNUPGHOME=/tmp/gnupg-chroot
        mkdir -p \$GNUPGHOME
        chmod 700 \$GNUPGHOME

        # Additional debugging for the live-build process
        echo '[DEBUG] About to start build-debian-live.sh'
        echo '[DEBUG] Current directory:' && pwd
        echo '[DEBUG] Available scripts:' && ls -la *.sh

        # Run the build with error handling
        if ! ./build-debian-live.sh $*; then
            echo '[ERROR] build-debian-live.sh failed'
            echo '[DEBUG] Checking for build logs:'
            find . -name '*.log' -exec echo 'Found log: {}' \; -exec tail -20 {} \;
            echo '[DEBUG] Checking chroot tmp status:'
            ls -la Stamus-Live-Build/chroot/tmp/ 2>/dev/null || echo 'chroot tmp directory not found'
            echo '[DEBUG] Checking available space:'
            df -h
            exit 1
        fi

        # Copy ISO to output
        if [ -f Stamus-Live-Build/ClearNDR.iso ]; then
            cp Stamus-Live-Build/ClearNDR.iso /output/
            echo 'ISO created successfully: /output/ClearNDR.iso'
        elif [ -f Stamus-Live-Build/live-image-amd64.hybrid.iso ]; then
            cp Stamus-Live-Build/live-image-amd64.hybrid.iso /output/ClearNDR.iso
            echo 'ISO created successfully: /output/ClearNDR.iso'
        else
            echo 'ERROR: ISO file not found'
            echo 'Contents of Stamus-Live-Build directory:'
            ls -la Stamus-Live-Build/
            exit 1
        fi
    "

if [ -f "$OUTPUT_DIR/ClearNDR.iso" ]; then
    ISO_SIZE=$(du -h "$OUTPUT_DIR/ClearNDR.iso" | cut -f1)
    log_success "ISO build completed!"
    log_success "Location: $OUTPUT_DIR/ClearNDR.iso"
    log_success "Size: $ISO_SIZE"

    # Generate checksums
    cd "$OUTPUT_DIR"
    sha256sum ClearNDR.iso > ClearNDR.iso.sha256
    md5sum ClearNDR.iso > ClearNDR.iso.md5
    log_info "Checksums generated"

    echo
    echo "To use the ISO:"
    echo "  - Write to USB: sudo dd if=$OUTPUT_DIR/ClearNDR.iso of=/dev/sdX bs=4M status=progress"
    echo "  - Test in VM with VirtualBox, VMware, or KVM"
else
    log_error "Build failed - ISO file not created"
    exit 1
fi
