---
title: Edge
linktitle: Nvidia GPU - AI/ML in the edge
description: A bunch of notes aroud GPU
tags: ["nvidia", "ai", "ml", "gpu", "jetson", "edge"]
---

# Nvidia GPU - AI/ML in the edge

### Check different versions & GPU support

```
dpkg-query --showformat='${Version}' --show nvidia-l4t-core

```

### Check opencv

```
python3 -c 'import cv2;print(cv2.getBuildInformation())'  |grep cuda
```

### Check dlib

```
python3 -c 'import dlib; print(dlib.DLIB_USE_CUDA);print(dlib.cuda.get_num_devices())'
```

### Cuda version

```
$ /usr/local/cuda/bin/nvcc --version
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2022 NVIDIA Corporation
Built on Wed_May__4_00:02:26_PDT_2022
Cuda compilation tools, release 11.4, V11.4.239
Build cuda_11.4.r11.4/compiler.31294910_0
```

## Issues & References

* <https://forums.developer.nvidia.com/t/issues-with-dlib-library/72600>
* <https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-cuda>
* [How to setup nvidia-container-runtime and podman/runc](https://gist.github.com/bernardomig/315534407585d5912f5616c35c7fe374)
* <https://developer.nvidia.com/embedded/learn/tutorials/first-picture-csi-usb-camera>
* <https://learnopencv.com/opencv-dnn-with-gpu-support/>
* <https://medium.com/@ageitgey/build-a-hardware-based-face-recognition-system-for-150-with-the-nvidia-jetson-nano-and-python-a25cb8c891fd>
* <https://repo.download.nvidia.com/jetson/>