#!/bin/bash



function cDown() {
  hour=$1
  min=$2
  sec=$3

  while [ $hour -ge 0 ]; do
    while [ $min -ge 0 ]; do
      while [ $sec -ge 0 ]; do
         echo -ne "$hour:$min:$sec\033[0K\r"
         let "sec=sec-1"
         sleep 1
      done
        
      sec=59
      let "min=min-1"
    done
      
    min=59
    let "hour=hour-1"
  
  done
}




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





## Define PVC using Dynamic Azure Disk Second Pod
echo "Define PVC using Dynamic Azure Disk Second Pod"
cat <<EOF > azure-pvc-second.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-managed-disk-second
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-csi
  resources:
    requests:
      storage: 10Gi
EOF

## Apply yaml
echo "Apply PVC Yaml"
kubectl apply -f azure-pvc-second.yaml


## Define DB Pod
cat << 'EOF' > db.yaml
apiVersion: v1
kind: Pod 
metadata:
  name: db  
spec:
  containers:
  - image: mongo:4.0.6
    name: mongodb
    # Mount as volume 
    volumeMounts:
    - name: data
      mountPath: /data/db
    ports:
    - containerPort: 27017
      protocol: TCP 
  volumes:
  - name: data
    # Declare the PVC to use for the volume
    persistentVolumeClaim:
      claimName: azure-managed-disk-second
EOF


## Deploy yaml
echo "Deploy yaml for second Pod"
kubectl create -f db.yaml


## Wait for DB pod
echo "Wait for DB Pod"
echo "Wait for 45s"
sleep 45
cDown 0 0 45

## Run the MongoDB CLI client to insert a document that contains the message "I was here" into a test database and then confirm it was inserted:
echo "Run MongoDB cli"
kubectl exec db -it -- mongo testdb --quiet --eval 'db.messages.insert({"message": "I was here"}); db.messages.findOne().message'


## Delete Db Pod
echo "Delete Db Pod"
kubectl delete -f db.yaml


## Redeploy new DB Pod with same PVC and PV
kubectl create -f db.yaml


## Wait for DB pod
echo "Wait for DB Pod"
echo "Wait for 45s"
sleep 45
cDown 0 0 45


## Confirm persistent data
echo "Confirm persistent data"
kubectl exec db -it -- mongo testdb --quiet --eval 'db.messages.findOne().message'
