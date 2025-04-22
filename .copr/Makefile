#!/usr/bin/make

SHELL := bash

source:
	dnf -y install cmake gcc gcc-c++
	cmake --fresh -DBUILD_RPMS=ON -B build -S .
	cmake --build build --target srpm

srpm: source
	mkdir -p $(outdir)
	cp dist/*.src.rpm $(outdir)
