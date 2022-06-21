# K3s

At this point there should be an extra node in your `k3s` cluster.  

The next step is to make sure only the pods you want are scheduled on that node.  

This is done using taints, toleration and affinities

## Adding the Taints and Affinity

This is an example command for setting the taint and affinity using `kubectl`:

```console
kubectl taint nodes mynode.example.com type=power:NoSchedule
kubectl label nodes mynode.example.com type=power
```

## Deployment with Toleration and Affinity

This is a sample deployment that has as toleration the above configured type and affinity:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-app
  name:  my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app:  my-app
  template:
    metadata:
      labels:
        app:  my-app
    spec:
      tolerations:
      - key: "type"
        value: "power"
        operator: "Equal"
        effect: "NoSchedule"
      affinity:
        nodeAffinity: 
          requiredDuringSchedulingIgnoredDuringExecution: 
            nodeSelectorTerms:
            - matchExpressions:
              - key: type
                operator: In 
                values:
                - power
      containers:
      - image: ubuntu
        name:  my-app
```
