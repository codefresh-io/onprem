# Deploy tiller with image from private registry

### create docker registry imagePullSecret 
```
kubectl create secret docker-registry private-docker-registry --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword>
```
