# Install Jenkins as Image in EKS

To install Jenkins as a **Docker image** on **Amazon EKS (Elastic Kubernetes Service)**, we'll go through the following process:

1. **Prepare EKS Cluster**: Set up an EKS cluster if not already done.
2. **Deploy Jenkins on EKS**: We'll use Kubernetes manifests (YAML files) for Jenkins deployment, including a `Deployment`, `Service`, and `PersistentVolume`.
3. **Expose Jenkins**: Configure external access via a LoadBalancer.

### Step-by-Step Scripts

#### 1. **Create EKS Cluster using AWS CLI**

Here’s a script that automates EKS cluster creation using AWS CLI:

**Cluster Creation Script (`create-eks-cluster.sh`)**

```bash
#!/bin/bash

# Set variables
CLUSTER_NAME="jenkins-eks-cluster"
NODE_GROUP_NAME="jenkins-node-group"
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

#### 2. **Kubernetes Manifest for Jenkins**

Create the following YAML files to deploy Jenkins to EKS:

##### 1. `jenkins-deployment.yaml`: Deploy Jenkins as a Docker image on EKS

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  labels:
    app: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: jenkins-pv
              mountPath: /var/jenkins_home
      volumes:
        - name: jenkins-pv
          persistentVolumeClaim:
            claimName: jenkins-pvc
```

##### 2. `jenkins-service.yaml`: Expose Jenkins using LoadBalancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  labels:
    app: jenkins
spec:
  type: LoadBalancer
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  selector:
    app: jenkins
```

##### 3. `jenkins-pvc.yaml`: Persistent Volume for Jenkins Data

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

#### 3. **Deploy Jenkins on EKS**

Once you have your EKS cluster set up and the Kubernetes manifest files, you can deploy Jenkins using `kubectl` commands.

##### Steps:

1. **Configure `kubectl`**: 
   Set up `kubectl` to connect to your EKS cluster by running:
   ```bash
   aws eks update-kubeconfig --region <REGION> --name <CLUSTER_NAME>
   ```

2. **Create the PersistentVolumeClaim (PVC)**:
   ```bash
   kubectl apply -f jenkins-pvc.yaml
   ```

3. **Deploy Jenkins**:
   ```bash
   kubectl apply -f jenkins-deployment.yaml
   ```

4. **Expose Jenkins**:
   ```bash
   kubectl apply -f jenkins-service.yaml
   ```

#### 4. **Access Jenkins**

After deploying Jenkins, AWS will provision an external Load Balancer. To get the external IP:

```bash
kubectl get services jenkins-service
```

This will output the **EXTERNAL-IP** (Load Balancer IP). You can then access Jenkins at:

```
http://<EXTERNAL-IP>:8080
```

#### 5. **Get Initial Admin Password**

To retrieve the Jenkins admin password, you can run:

```bash
kubectl exec --namespace default -it $(kubectl get pod --namespace default -l "app=jenkins" -o jsonpath="{.items[0].metadata.name}") -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### Full Set of Scripts:

1. **Cluster Creation Script (`create-eks-cluster.sh`)**
2. **Kubernetes Manifests for Jenkins** (`jenkins-deployment.yaml`, `jenkins-service.yaml`, `jenkins-pvc.yaml`)

### Suggested Next Steps:
- Configure a Jenkins pipeline for deploying to AWS.
- Add Jenkins agents for parallel builds in Kubernetes.
- Secure Jenkins access using IAM roles and policies.
