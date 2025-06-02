#!/bin/bash

set -e

ROOT_DIR="rhods-gitops-kustomize"
mkdir -p $ROOT_DIR/base/{workbenches,model-serving,pipelines}
mkdir -p $ROOT_DIR/overlays/data-scientists
mkdir -p $ROOT_DIR/overlays/ml-engineers

# === BASE ===

cat > $ROOT_DIR/base/namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: rhods-project
  labels:
    opendatahub.io/dashboard: "true"
EOF

cat > $ROOT_DIR/base/workbenches/team-notebook-1.yaml <<EOF
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: team-notebook-1
  namespace: rhods-project
spec:
  template:
    spec:
      containers:
        - name: team-notebook-1
          image: s2i-minimal-notebook
          resources:
            limits:
              cpu: "2"
              memory: "8Gi"
EOF

cat > $ROOT_DIR/base/workbenches/team-notebook-2.yaml <<EOF
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: team-notebook-2
  namespace: rhods-project
spec:
  template:
    spec:
      containers:
        - name: team-notebook-2
          image: pytorch-gpu
          resources:
            limits:
              cpu: "2"
              memory: "8Gi"
EOF

cat > $ROOT_DIR/base/model-serving/fraud-detector.yaml <<EOF
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: fraud-detector
  namespace: rhods-project
spec:
  predictor:
    model:
      modelFormat:
        name: onnx
      runtime: ovms-runtime
      storageUri: s3://models/fraud-detector
EOF

cat > $ROOT_DIR/base/model-serving/image-classifier.yaml <<EOF
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: image-classifier
  namespace: rhods-project
spec:
  predictor:
    model:
      modelFormat:
        name: tensorrt
      runtime: triton-runtime
      storageUri: s3://models/image-classifier
EOF

cat > $ROOT_DIR/base/pipelines/ml-pipeline.yaml <<EOF
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: ml-pipeline
  namespace: rhods-project
spec:
  params:
    - name: storage
      default: "10Gi"
EOF

cat > $ROOT_DIR/base/rbac.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhods-project-admin
  namespace: rhods-project
subjects:
- kind: Group
  name: data-scientists
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
EOF

cat > $ROOT_DIR/base/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - workbenches/team-notebook-1.yaml
  - workbenches/team-notebook-2.yaml
  - model-serving/fraud-detector.yaml
  - model-serving/image-classifier.yaml
  - pipelines/ml-pipeline.yaml
  - rbac.yaml

commonLabels:
  app.kubernetes.io/managed-by: kustomize
EOF

# === OVERLAYS: data-scientists ===

cat > $ROOT_DIR/overlays/data-scientists/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

patchesStrategicMerge:
  - patch-notebook.yaml
  - patch-runtime.yaml

commonLabels:
  rhods-group: data-scientists
EOF

cat > $ROOT_DIR/overlays/data-scientists/patch-notebook.yaml <<EOF
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: team-notebook-1
spec:
  template:
    spec:
      containers:
        - name: team-notebook-1
          resources:
            limits:
              cpu: "4"
              memory: "16Gi"
EOF

cat > $ROOT_DIR/overlays/data-scientists/patch-runtime.yaml <<EOF
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: fraud-detector
spec:
  predictor:
    model:
      resources:
        limits:
          cpu: "2"
          memory: "8Gi"
EOF

# === OVERLAYS: ml-engineers ===

cat > $ROOT_DIR/overlays/ml-engineers/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

patchesStrategicMerge:
  - patch-notebook.yaml

commonLabels:
  rhods-group: ml-engineers
EOF

cat > $ROOT_DIR/overlays/ml-engineers/patch-notebook.yaml <<EOF
apiVersion: kubeflow.org/v1
kind: Notebook
metadata:
  name: team-notebook-2
spec:
  template:
    spec:
      containers:
        - name: team-notebook-2
          resources:
            limits:
              cpu: "6"
              memory: "24Gi"
EOF

echo "✅ Yapı '${ROOT_DIR}/' dizini altında oluşturuldu."

