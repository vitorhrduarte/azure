






apiVersion: v1
kind: Pod
metadata:
  name: cpu-perf-03
spec:
  containers:
  - image: typeoneg/stresstest-pod:v1 
    name: cpu-perf
    command: [ "sh", "-c", "sleep infinity" ]
  nodeSelector:
    #kubernetes.io/os: linux
    #agentpool: usrnp01
    kubernetes.io/hostname: aks-usrnp-27798712-vmss000002 




cat <<EOF > aci.yaml
apiVersion: '2021-07-01'
location: $LOCATION
name: appcontaineryaml
properties:
  containers:
  - name: appcontaineryaml
    properties:
      image: mcr.microsoft.com/azuredocs/aci-helloworld
      ports:
      - port: 80
        protocol: TCP
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.5
  ipAddress:
    type: Public
    ports:
    - protocol: tcp
      port: '80'
  osType: Linux
  restartPolicy: Always
  subnetIds:
    - id: $SUBNET_ID
      name: default
tags: null
type: Microsoft.ContainerInstance/containerGroups
EOF
