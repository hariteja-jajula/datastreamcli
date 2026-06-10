#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
PACKAGE_DIR=$(dirname "$SCRIPT_DIR")
VERSIONS_FILE="${PACKAGE_DIR}/versions.yml"
VERSIONS_INTEGRATIONS_FILE="${PACKAGE_DIR}/versions_integrations.yml"

# Tags sourced the same way scripts/datastream does, so Singularity images
# stay consistent with the Docker-based CLI workflow.
DS_VERSION=$(sed -n 's/^datastream: *"\([^"]*\)".*/\1/p' "$VERSIONS_FILE")
FP_VERSION=$(sed -n 's/^forcingprocessor: *"\([^"]*\)".*/\1/p' "$VERSIONS_INTEGRATIONS_FILE")
NGIAB_VERSION=$(sed -n 's/^ciroh-ngen-image: *"\([^"]*\)".*/\1/p' "$VERSIONS_INTEGRATIONS_FILE")

echo "Building DataStreamCLI Singularity images..."
echo "  datastream version:       ${DS_VERSION}"
echo "  forcingprocessor version: ${FP_VERSION}"
echo "  ciroh-ngen-image version: ${NGIAB_VERSION}"

# Build from the singularity/ directory so that %files paths in the .def
# (which are interpreted relative to cwd) resolve correctly against the repo.
cd "$SCRIPT_DIR"

sed "s|^From: awiciroh/datastream:.*|From: awiciroh/datastream:${DS_VERSION}|" \
    datastream.def > datastream_pinned.def

singularity build --fakeroot datastream.sif datastream_pinned.def
rm datastream_pinned.def

singularity build --fakeroot forcingprocessor.sif "docker://awiciroh/forcingprocessor:${FP_VERSION}"
singularity build --fakeroot merkdir.sif docker://zwills/merkdir:latest
singularity build --fakeroot ngiabinabox.sif "docker://awiciroh/ciroh-ngen-image:${NGIAB_VERSION}"

echo "All Singularity images built successfully."
