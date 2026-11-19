FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends octave octave-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
