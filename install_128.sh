#!/usr/bin/env bash
# Metrical Photometric Tracker install script for
# Python 3.11 / PyTorch 2.9.1 / CUDA 12.8.
#
# Preconditions (verified before running this script):
#   - Python 3.11 is active (e.g. `python3.11 -m venv .venv && source .venv/bin/activate`).
#   - System CUDA Toolkit 12.8 is installed (nvcc on PATH, or CUDA_HOME set).
#   - gcc-11 / g++-11 are installed (Ubuntu 22.04: `sudo apt install gcc-11 g++-11`).
#
# This script mirrors MTamon/smirk (release/cuda128) install_128.sh,
# MTamon/DECA (cuda128) install_128.sh and MTamon/FlashAvatar
# (release/cuda128-fixed) install_128.sh as closely as possible so that
# metrical-tracker can coexist with SMIRK / DECA / FlashAvatar / FLARE in the
# same environment.
#
# `--no-deps` is used on the pinned block to prevent pip from mutating the pin
# set via transitive resolution. Tracker-specific additions (pytorch3d,
# trimesh, matplotlib, loguru, tensorboard, yacs) are installed at the end;
# their transitive deps are already satisfied by the pinned block.
#
# FLAME .pkl files unpickle to `chumpy.Ch` objects, so chumpy is required at
# inference time. It is installed from GitHub main (numpy 2.x compatible),
# identical to SMIRK / DECA / FlashAvatar.

set -euo pipefail

# ----------------------------------------------------------------------------
# Toolchain setup. Required because pytorch3d is built from source below.
# ----------------------------------------------------------------------------
export CC="${CC:-gcc-11}"
export CXX="${CXX:-g++-11}"

if [ -z "${CUDA_HOME:-}" ]; then
    if [ -d "/usr/local/cuda-12.8" ]; then
        export CUDA_HOME="/usr/local/cuda-12.8"
    elif [ -d "/usr/local/cuda" ]; then
        export CUDA_HOME="/usr/local/cuda"
    else
        echo "[install_128.sh] WARNING: CUDA_HOME is not set and /usr/local/cuda-12.8 was not found."
        echo "[install_128.sh]          Set CUDA_HOME manually to your CUDA 12.8 install path before rerunning."
        exit 1
    fi
fi
export PATH="${CUDA_HOME}/bin:${PATH}"

# Turing 7.5, Ampere 8.0/8.6, Ada 8.9, Hopper 9.0, Blackwell 12.0 (RTX 5090).
export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-7.5;8.0;8.6;8.9;9.0;12.0}"
export FORCE_CUDA=1

echo "[install_128.sh] CC=${CC} CXX=${CXX}"
echo "[install_128.sh] CUDA_HOME=${CUDA_HOME}"
echo "[install_128.sh] TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}"
nvcc --version || { echo "[install_128.sh] nvcc not found on PATH"; exit 1; }

# ----------------------------------------------------------------------------
# 1. Upgrade pip.
# ----------------------------------------------------------------------------
python -m pip install --upgrade pip==25.2

# ----------------------------------------------------------------------------
# 2. chumpy from GitHub main (numpy 2.x compatible; same source as SMIRK128 /
#    DECA128). FLAME .pkl files deserialize into chumpy.Ch objects.
# ----------------------------------------------------------------------------
pip install git+https://github.com/mattloper/chumpy.git

# ----------------------------------------------------------------------------
# 3. DECA128-aligned pinned dependencies (identical set to
#    MTamon/smirk/release/cuda128, MTamon/DECA/cuda128 and FlashAvatar128).
# ----------------------------------------------------------------------------
pip install --no-deps Cython==0.29.35
pip install --no-deps face-alignment==1.4.1
pip install --no-deps filelock==3.20.0
pip install --no-deps fsspec==2025.10.0
pip install --no-deps fvcore==0.1.5.post20221221
pip install --no-deps ImageIO==2.37.2
pip install --no-deps iopath==0.1.10
pip install --no-deps Jinja2==3.1.6
pip install --no-deps joblib==1.5.2
pip install --no-deps kornia==0.8.2
pip install --no-deps kornia_rs==0.1.10
pip install --no-deps lazy_loader==0.4
pip install --no-deps llvmlite==0.45.1
pip install --no-deps MarkupSafe==3.0.3
pip install --no-deps mpmath==1.3.0
pip install --no-deps networkx==3.5
pip install --no-deps ninja==1.13.0
pip install --no-deps numba==0.62.1
pip install --no-deps numpy==2.2.6
pip install --no-deps nvidia-cublas-cu12==12.8.4.1
pip install --no-deps nvidia-cuda-cupti-cu12==12.8.90
pip install --no-deps nvidia-cuda-nvrtc-cu12==12.8.93
pip install --no-deps nvidia-cuda-runtime-cu12==12.8.90
pip install --no-deps nvidia-cudnn-cu12==9.10.2.21
pip install --no-deps nvidia-cufft-cu12==11.3.3.83
pip install --no-deps nvidia-cufile-cu12==1.13.1.3
pip install --no-deps nvidia-curand-cu12==10.3.9.90
pip install --no-deps nvidia-cusolver-cu12==11.7.3.90
pip install --no-deps nvidia-cusparse-cu12==12.5.8.93
pip install --no-deps nvidia-cusparselt-cu12==0.7.1
pip install --no-deps nvidia-nccl-cu12==2.27.5
pip install --no-deps nvidia-nvjitlink-cu12==12.8.93
pip install --no-deps nvidia-nvshmem-cu12==3.3.20
pip install --no-deps nvidia-nvtx-cu12==12.8.90
pip install --no-deps opencv-python==4.12.0.88
pip install --no-deps packaging==25.0
pip install --no-deps pillow==12.0.0
pip install --no-deps portalocker==3.2.0
pip install --no-deps PyYAML==6.0.3
pip install --no-deps scikit-image==0.25.2
pip install --no-deps scikit-learn==1.7.2
pip install --no-deps scipy==1.16.3
pip install --no-deps six==1.17.0
pip install --no-deps sympy==1.14.0
pip install --no-deps tabulate==0.9.0
pip install --no-deps termcolor==3.2.0
pip install --no-deps threadpoolctl==3.6.0
pip install --no-deps tifffile==2025.10.16
pip install --no-deps torch==2.9.1
pip install --no-deps torchvision==0.24.1
pip install --no-deps tqdm==4.67.1
pip install --no-deps triton==3.5.1
pip install --no-deps typing_extensions==4.15.0
pip install --no-deps yacs==0.1.8

# ----------------------------------------------------------------------------
# 4. mediapipe + supporting packages (SMIRK128-aligned).
# metrical-tracker uses mediapipe.python.solutions.face_mesh_connections and
# FaceMesh for landmark detection.
# ----------------------------------------------------------------------------
pip install --no-deps absl-py==2.1.0
pip install --no-deps attrs==24.2.0
pip install --no-deps flatbuffers==24.3.25
pip install --no-deps jax==0.4.30
pip install --no-deps jaxlib==0.4.30
pip install --no-deps ml_dtypes==0.4.1
pip install --no-deps opt_einsum==3.4.0
pip install --no-deps protobuf==4.25.5
pip install --no-deps sounddevice==0.5.1
pip install --no-deps sentencepiece==0.2.0
pip install --no-deps mediapipe==0.10.14

# ----------------------------------------------------------------------------
# 5. Metrical-tracker specific additions (not in SMIRK128 / DECA128).
# Installed with `--no-deps` so the pin set above stays intact. Their
# transitive dependencies are already satisfied.
# ----------------------------------------------------------------------------
# trimesh is used to export per-frame meshes (.ply) and load the head template.
pip install --no-deps trimesh==4.5.3
# loguru is used for structured logging throughout the tracker.
pip install --no-deps loguru==0.7.2
# matplotlib is used by face-alignment internals and for optional debug plots.
pip install --no-deps contourpy==1.3.1
pip install --no-deps cycler==0.12.1
pip install --no-deps fonttools==4.55.0
pip install --no-deps kiwisolver==1.4.7
pip install --no-deps pyparsing==3.2.0
pip install --no-deps python-dateutil==2.9.0.post0
pip install --no-deps matplotlib==3.9.2
# tensorboard for torch.utils.tensorboard.SummaryWriter.
pip install --no-deps absl-py==2.1.0
pip install --no-deps grpcio==1.68.1
pip install --no-deps markdown==3.7
pip install --no-deps tensorboard-data-server==0.7.2
pip install --no-deps werkzeug==3.1.3
pip install --no-deps tensorboard==2.18.0
# pywavelets is an optional scikit-image dep used by skimage.io with some
# plugins; pinning to the numpy 2.x compatible release.
pip install --no-deps PyWavelets==1.7.0
# requests / urllib3 / certifi for chumpy / gdown / face-alignment URL fetches.
pip install --no-deps requests==2.32.3
pip install --no-deps charset_normalizer==3.4.0
pip install --no-deps idna==3.10
pip install --no-deps urllib3==2.2.3
pip install --no-deps certifi==2024.8.30

# ----------------------------------------------------------------------------
# 6. PyTorch3D from source.
# No pre-built wheel ships for torch 2.9.1 + CUDA 12.8 yet, so pytorch3d is
# compiled against the pinned torch above. FORCE_CUDA=1 and TORCH_CUDA_ARCH_LIST
# set above are required for the CUDA kernels to be built.
# ----------------------------------------------------------------------------
pip install --no-deps --no-build-isolation \
    "git+https://github.com/facebookresearch/pytorch3d.git@v0.7.8"

echo "[install_128.sh] done. Quick sanity check:"
python - <<'PY'
import torch
print("torch          :", torch.__version__)
print("torch.cuda     :", torch.version.cuda)
print("cuda available :", torch.cuda.is_available())
try:
    import numpy as np
    print("numpy          :", np.__version__)
except Exception as e:
    print("numpy          :", repr(e))
try:
    import pytorch3d
    print("pytorch3d      :", pytorch3d.__version__)
    from pytorch3d.renderer import MeshRasterizer  # noqa: F401
    print("pytorch3d.renderer: ok")
except Exception as e:
    print("pytorch3d      :", repr(e))
try:
    import mediapipe as mp
    print("mediapipe      :", mp.__version__)
except Exception as e:
    print("mediapipe      :", repr(e))
try:
    import face_alignment
    print("face_alignment :", face_alignment.__version__)
except Exception as e:
    print("face_alignment :", repr(e))
try:
    import trimesh
    print("trimesh        :", trimesh.__version__)
except Exception as e:
    print("trimesh        :", repr(e))
try:
    import chumpy
    print("chumpy         :", chumpy.__version__)
except Exception as e:
    print("chumpy         :", repr(e))
try:
    from torch.utils.tensorboard import SummaryWriter  # noqa: F401
    print("tensorboard    : ok")
except Exception as e:
    print("tensorboard    :", repr(e))
PY
