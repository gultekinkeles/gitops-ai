#!/bin/bash

USER_FILE=$1
USERNAME=$(jq -r .username "$USER_FILE")
NAMESPACE=$(jq -r .namespace "$USER_FILE")
OVERLAY_DIR="overlays/$USERNAME"

mkdir -p "$OVERLAY_DIR"

cat <<EOF > "$OVERLAY_DIR/kustomization.yaml"
resources:
  - ../../base

configMapGenerator:
  - name: user-config
    envs:
      - params.env

vars:
  - name: USERNAME
    objref:
      kind: ConfigMap
      name: user-config
      apiVersion: v1
    fieldref:
      fieldpath: data.USERNAME
  - name: NAMESPACE_NAME
    objref:
      kind: ConfigMap
      name: user-config
      apiVersion: v1
    fieldref:
      fieldpath: data.NAMESPACE_NAME
EOF

cat <<EOF > "$OVERLAY_DIR/params.env"
USERNAME=$USERNAME
NAMESPACE_NAME=$NAMESPACE
EOF
