# Connect Nexus with ArgoCD

To configure **ArgoCD** to pull Docker images from a private **Nexus Docker Registry**, you need to set up Docker credentials in ArgoCD. These credentials allow ArgoCD to authenticate with Nexus when pulling images for Kubernetes deployments. Here’s how you can configure Docker credentials in ArgoCD to connect to Nexus:

### Steps to Configure Docker Credentials in ArgoCD:

#### Step 1: Create a Kubernetes Secret for Docker Registry Credentials

ArgoCD stores Docker credentials using Kubernetes Secrets. This secret will store the credentials required to authenticate to your Nexus Docker registry.

##### 1.1. Create a Docker Config JSON

First, you need to create a Docker config JSON that contains the login credentials for your Nexus repository.

Run the following command on your local machine to create the `config.json` using Docker’s login command:

```bash
docker login <nexus-ip>:5000 --username <your-nexus-username> --password <your-nexus-password>
```

This will create or update the `~/.docker/config.json` file with credentials. The structure of this file looks like this:

```json
{
    "auths": {
        "<nexus-ip>:5000": {
            "auth": "base64-encoded-credentials"
        }
    }
}
```

You can use this JSON file to create the Kubernetes Secret.

##### 1.2. Create a Kubernetes Secret for Docker Credentials

Now, create a Kubernetes Secret in the namespace where ArgoCD is deployed (typically, this is the `argocd` namespace). This secret will contain your Docker credentials, which ArgoCD will use to authenticate with your Nexus repository.

Run the following command:

```bash
kubectl create secret docker-registry nexus-docker-creds \
    --docker-server=<nexus-ip>:5000 \
    --docker-username=<your-nexus-username> \
    --docker-password=<your-nexus-password> \
    --docker-email=<your-email> \
    -n argocd
```

- Replace `<nexus-ip>` with the IP address or domain of your Nexus repository.
- Replace `<your-nexus-username>` and `<your-nexus-password>` with your Nexus credentials.
- Replace `<your-email>` with your email address.
- Ensure you use the `-n argocd` flag to create the secret in the **argocd** namespace.

This will create a Kubernetes secret called `nexus-docker-creds`.

#### Step 2: Configure ArgoCD to Use the Docker Credentials

After creating the Docker credentials secret, you need to configure ArgoCD to use this secret when pulling images from the Nexus Docker registry.

##### 2.1. Edit the ArgoCD `argocd-cm` ConfigMap

The `argocd-cm` ConfigMap is where ArgoCD stores configurations related to repositories, Helm chart repositories, and Docker registries.

To add the Docker credentials, follow these steps:

1. Run the following command to edit the `argocd-cm` ConfigMap:

   ```bash
   kubectl edit configmap argocd-cm -n argocd
   ```

2. Add the following `repositories` entry under the `configManagementPlugins` section, specifying the name of the secret you created:

   ```yaml
   data:
     configManagementPlugins: |
       - name: docker-credentials
         config: |
           secretName: nexus-docker-creds
           namespace: argocd
   ```

3. Save and exit the editor.

##### 2.2. Add the Docker Registry in ArgoCD

In the same `argocd-cm` ConfigMap, add your Nexus Docker registry to the list of `repositories` or `repositories.credentials` (depending on your ArgoCD version):

1. Under the `repositories.credentials` section, add an entry for your Nexus registry:

   ```yaml
   repositories.credentials: |
     - name: nexus-docker-repo
       url: <nexus-ip>:5000
       type: docker
       usernameSecret:
         name: nexus-docker-creds
         key: .dockerconfigjson
   ```

This configuration allows ArgoCD to use the credentials from the `nexus-docker-creds` secret whenever it pulls Docker images from your Nexus repository.

#### Step 3: Verify the Configuration

Once you have configured the credentials in the ArgoCD ConfigMap:

1. Restart the ArgoCD server to apply the changes:

   ```bash
   kubectl rollout restart deployment argocd-server -n argocd
   ```

2. Check if the secret is properly configured:

   ```bash
   kubectl get secret nexus-docker-creds -n argocd
   ```

3. Ensure that ArgoCD can now pull the images from your Nexus Docker repository by triggering a deployment.

#### Step 4: Update Your Kubernetes Deployment YAML

In your Kubernetes manifest, reference the Docker image hosted in the Nexus Docker registry, like so:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: <nexus-ip>:5000/my-app:latest
        ports:
        - containerPort: 80
```

Now, ArgoCD will be able to pull the Docker image from Nexus using the configured credentials.

### Troubleshooting

1. **Secret not found**:
   - Ensure the secret name in the `argocd-cm` ConfigMap matches the secret name created in the `argocd` namespace.
   - Verify that the secret is in the correct namespace (`argocd`).

2. **Failed to pull image**:
   - Ensure that the Nexus registry is accessible from the ArgoCD server (e.g., check networking/firewalls).
   - Ensure that Nexus is properly configured for Docker, and Docker image push/pull operations work using the Docker CLI.

3. **Check ArgoCD Logs**:
   - If you encounter issues, review the ArgoCD logs for more details:

   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
   ```

---

### Conclusion

By following these steps, you’ve successfully configured ArgoCD to authenticate with a private Nexus Docker registry and pull Docker images for deployment on an EKS cluster. This setup integrates well with both Jenkins (for CI) and ArgoCD (for CD), ensuring a seamless CI/CD pipeline for your Kubernetes workloads.
