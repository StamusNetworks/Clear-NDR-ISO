# Docker-based ISO Building

This directory contains a script for building SELKS ISO images using Docker.

## Script

### `build-iso-docker.sh`

Simple Docker build script that works with the existing Dockerfile.

- Easy to use
- Minimal configuration
- Good for all use cases
- Uses existing repository Dockerfile

```bash
./build-iso-docker.sh                    # Standard build
./build-iso-docker.sh -g no-desktop      # Server-only build
./build-iso-docker.sh -k 6.5             # Custom kernel
./build-iso-docker.sh -p "vim htop"      # Add extra packages
```

## Requirements

- Docker installed and running
- At least 10GB free disk space
- Internet connection (for downloading packages)

## Output

The script creates:

- `./output/ClearNDR.iso` - The bootable ISO file
- `./output/ClearNDR.iso.sha256` - SHA256 checksum
- `./output/ClearNDR.iso.md5` - MD5 checksum

## Advantages of Docker Build

1. **Consistent Environment**: Same build environment every time
2. **Isolation**: Doesn't affect your host system
3. **No Root Required**: Runs without sudo on host
4. **Easy Cleanup**: Simple to remove build artifacts
5. **Portability**: Works on any system with Docker

## Troubleshooting

If build fails:

1. Check Docker is running: `docker info`
2. Ensure sufficient disk space: `df -h`
3. Check network connectivity
4. Try rebuilding Docker image: `docker build -t selks-builder .`

For more details, see `ISO_BUILD_GUIDE.md`.
