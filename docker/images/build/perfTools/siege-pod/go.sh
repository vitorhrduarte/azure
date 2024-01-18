#!/usr/bin/env zsh

usage() {
    echo "Usage: `basename $0` -d deployment_name -n namespace -r replicas -i image_registry [-o output_dir] [-a]"
    echo
    echo "Generate a Kubernetes deployment YAML file and optionally apply it."
    echo
    echo "Options:"
    echo "  -d,  Set the deployment name."
    echo "  -n,  Set the namespace."
    echo "  -r,  Set the number of replicas."
    echo "  -i,  Set the image registry."
    echo "  -o,  Set the output directory for the deployment YAML file."
    echo "  -a,  Apply the configuration immediately."
    echo "  -h,  Display this help and exit."
}
APPLY=false
while getopts "hao:d:n:r:i:" arg
do
    case $arg in
        d)
            DEPLOYMENT_NAME=$OPTARG
            ;;
        n)
            NAMESPACE=$OPTARG
            ;;
        r)
            REPLICAS=$OPTARG
            ;;
        i)
            IMAGE_REGISTRY=$OPTARG
            ;;
        o)
            OUTPUT_DIR=$OPTARG
            ;;
        a)
            APPLY=true
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# Check that all arguments are provided
if [ -z "$DEPLOYMENT_NAME" ] || [ -z "$NAMESPACE" ] || [ -z "$REPLICAS" ] || [ -z "$IMAGE_REGISTRY" ]; then
  echo "Required arguments must be provided!" >&2
  usage
  exit 1
fi

# Generate the YAML
deployment=$(cat << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: siege
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: siege
  template:
    metadata:
      labels:
        app: siege
    spec:
      containers:
      - name: siege
        image: ${IMAGE_REGISTRY}/siege:1.0
        command: ["sh", "-c", "tail -f /dev/null"]
EOF
)

if [ "$APPLY" = "true" ]; then
    echo "$deployment" | kubectl apply -f -
    echo "Applied the configuration immediately to the cluster."
fi

if [ ! -z "$OUTPUT_DIR" ]; then
    echo "$deployment" > $OUTPUT_DIR/deployment.yaml
    echo "Saved deployment.yaml file to directory: $OUTPUT_DIR"
fi

