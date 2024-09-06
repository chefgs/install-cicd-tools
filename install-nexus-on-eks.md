# Install Nexus as Image in EKS

To install **Nexus Repository Manager** on **Amazon EKS** as a Docker image, we'll follow a similar approach as we did for Jenkins. The process includes creating Kubernetes manifests to deploy Nexus on EKS with persistent storage and external access via a LoadBalancer.

### Step-by-Step Instructions and Scripts

---

### 1. **Create EKS Cluster (Optional)**

If you haven't already set up an EKS cluster, you can use the following script (same as before):

```bash
#!/bin/bash

# Set variables
CLUSTER_NAME="nexus-eks-cluster"
NODE_GROUP_NAME="nexus-node-group"
REGION="us-west-2"
NODE_TYPE="t3.medium"
NODE_COUNT=2

# Create EKS cluster
aws eks create-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --kubernetes-version 1.24 \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/EKSRole \
  --resources-vpc-config subnetIds=subnet-abc1234,subnet-def5678,securityGroupIds=sg-123456789 \
  --output json

# Create EKS node group
aws eks create-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name $NODE_GROUP_NAME \
  --node-role arn:aws:iam::YOUR_ACCOUNT_ID:role/EKSNodeRole \
  --subnets subnet-abc1234 subnet-def5678 \
  --instance-types $NODE_TYPE \
  --scaling-config minSize=1,maxSize=4,desiredSize=$NODE_COUNT \
  --output json

echo "EKS Cluster and Node Group setup initiated. Check AWS console for status."
```

This script sets up the EKS cluster and node group. Make sure to replace the `role-arn` and `subnet-ids` with your AWS account-specific values.

---

### 2. **Nexus Kubernetes Manifests**

Next, create the Kubernetes manifests to deploy **Nexus Repository Manager** on EKS.

#### 1. `nexus-deployment.yaml`: Nexus Deployment

This YAML file defines the Nexus deployment using the official `sonatype/nexus3` Docker image.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nexus
  labels:
    app: nexus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nexus
  template:
    metadata:
      labels:
        app: nexus
    spec:
      containers:
        - name: nexus
          image: sonatype/nexus3:latest
          ports:
            - containerPort: 8081
          volumeMounts:
            - name: nexus-pv
              mountPath: /nexus-data
      volumes:
        - name: nexus-pv
          persistentVolumeClaim:
            claimName: nexus-pvc
```

#### 2. `nexus-service.yaml`: Nexus Service

This file exposes Nexus via a LoadBalancer.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nexus-service
  labels:
    app: nexus
spec:
  type: LoadBalancer
  ports:
    - port: 8081
      targetPort: 8081
      protocol: TCP
  selector:
    app: nexus
```

#### 3. `nexus-pvc.yaml`: Persistent Volume for Nexus

Nexus requires persistent storage to store repositories and other data. The following PVC manifest allocates 10GB of persistent storage.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nexus-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

---

### 3. **Deploy Nexus on EKS**

Once you have your EKS cluster ready and the Kubernetes manifest files prepared, deploy Nexus to EKS using `kubectl`.

#### Steps:

1. **Configure `kubectl`**: 
   Make sure `kubectl` is configured to point to your EKS cluster by running:
   ```bash
   aws eks update-kubeconfig --region <REGION> --name <CLUSTER_NAME>
   ```

2. **Create PersistentVolumeClaim (PVC)**:
   First, apply the `nexus-pvc.yaml` to ensure persistent storage for Nexus:
   ```bash
   kubectl apply -f nexus-pvc.yaml
   ```

3. **Deploy Nexus**:
   Deploy the Nexus deployment with the `nexus-deployment.yaml` file:
   ```bash
   kubectl apply -f nexus-deployment.yaml
   ```

4. **Expose Nexus via LoadBalancer**:
   Apply the service to expose Nexus via an external LoadBalancer:
   ```bash
   kubectl apply -f nexus-service.yaml
   ```

---

### 4. **Access Nexus**

After deploying Nexus, AWS will provision an external Load Balancer. To get the external IP:

```bash
kubectl get services nexus-service
```

This will output the **EXTERNAL-IP** of the LoadBalancer. You can then access Nexus Repository Manager in your browser:

```
http://<EXTERNAL-IP>:8081
```

---

### 5. **Initial Setup of Nexus**

- The default credentials for Nexus are:
  - Username: `admin`
  - Password: Retrieve from the Nexus logs or use the following command:

```bash
kubectl exec --namespace default -it $(kubectl get pod --namespace default -l "app=nexus" -o jsonpath="{.items[0].metadata.name}") -- cat /nexus-data/admin.password
```

---

### Full Set of Scripts:

1. **Cluster Creation Script** (if needed): `create-eks-cluster.sh`
2. **Kubernetes Manifests**:
   - `nexus-deployment.yaml` – Defines the Nexus deployment.
   - `nexus-service.yaml` – Exposes Nexus using a LoadBalancer.
   - `nexus-pvc.yaml` – Persistent storage for Nexus data.

---

### Suggested Next Steps:
- Integrate Nexus with your CI/CD pipelines for repository management.
- Enable Nexus authentication and role-based access control (RBAC).
- Scale Nexus by adjusting the number of replicas and PVC size.
