FROM ghcr.io/rocker-org/devcontainer/r-ver:4.5

# System libraries required by the R packages in renv.lock
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake pandoc libcurl4-openssl-dev libssl-dev libxml2-dev zlib1g-dev libuv1-dev libicu-dev \
    libx11-dev libcairo2-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev \
    libjpeg-dev libpng-dev libtiff-dev libwebp-dev \
    && rm -rf /var/lib/apt/lists/*
