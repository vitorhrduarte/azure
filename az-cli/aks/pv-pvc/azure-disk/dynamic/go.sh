#!/bin/bash


## Define PVC using Dynamic Azure Disk
echo "Define PVC using Dynamic Azure Disk"
cat <<EOF > azure-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-managed-disk
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 5Gi
EOF

## Apply yaml
echo "Apply PVC Yaml"
kubectl apply -f azure-pvc.yaml


## Define Pod with the PVC
echo "Define Pod with the PVC"
echo ""
cat <<EOF > azure-pvc-disk.yaml 
kind: Pod
apiVersion: v1
metadata:
  name: mypod
spec:
  containers:
  - name: mypod
    image: mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 250m
        memory: 256Mi
    volumeMounts:
    - mountPath: "/mnt/azure"
      name: volume
  volumes:
    - name: volume
      persistentVolumeClaim:
        claimName: azure-managed-disk
EOF

## Apply yaml
echo "Deploy Pod"
kubectl apply -f azure-pvc-disk.yaml



