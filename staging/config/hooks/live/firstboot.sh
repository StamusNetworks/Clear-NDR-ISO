#!/usr/bin/env bash

function load_docker_images_from_tar(){
  tar_path="/opt/ClearNDRCommunity/docker/tar_images/"
  firstboot="/opt/ClearNDRCommunity/docker/firstboot.cndrc"

  if [ -d "$tar_path" ] && [ -f "$firstboot" ]; then
    echo -e "Found docker images tarballs"
    for filename in $tar_path/*.tar; do
    echo -e "\n Loading $filename into docker"
      docker load -i "$filename"
    done
    if [ $? -eq 0 ]; then
      rm -rf "$firstboot"
    else
      echo "FAILED to load Docker images"
      exit 1;
    fi
  fi
}

load_docker_images_from_tar
