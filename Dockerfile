# Runs ESPHome's script/clang-tidy the way the clang-tidy jobs in .github/workflows/ci.yml do:
# Python 3.12 with requirements.txt, requirements_dev.txt and requirements_test.txt installed.
# The requirement files come from the checkout being checked, copied in by esphome-clang-tidy.
FROM python:3.12-slim-bookworm

# Tools the ESP-IDF and PlatformIO toolchain installers need.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bison \
        ccache \
        cmake \
        curl \
        dfu-util \
        flex \
        git \
        gperf \
        libffi-dev \
        libssl-dev \
        libusb-1.0-0 \
        ninja-build \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# The checkout is mounted from the host, so its owner differs from the user git runs as.
RUN git config --system --add safe.directory '*'

RUN pip install --no-cache-dir uv

COPY requirements.txt requirements_dev.txt requirements_test.txt /tmp/requirements/
RUN cd /tmp/requirements \
    && uv pip install --system --no-cache \
        -r requirements.txt -r requirements_dev.txt -r requirements_test.txt
