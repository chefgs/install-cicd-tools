# Create EKS using Terraform and Deploy Jenkins and Nexus

To deploy Jenkins or Nexus as part of an **EKS cluster** created using **Terraform**, you can automate the deployment by integrating Kubernetes manifests (such as the `Deployment`, `Service`, and `PersistentVolumeClaim`) directly into your Terraform configuration. This ensures that when the EKS cluster is provisioned, Jenkins or Nexus is pre-installed and ready to use.

Below are the steps and Terraform configurations to achieve this.

---

### High-Level Steps:

1. **Create the EKS Cluster using Terraform**.
2. **Install Jenkins or Nexus using Kubernetes resources** within the Terraform code.
3. **Use Terraform's `kubectl` provider or apply Kubernetes manifests directly from Terraform**.

---

### Terraform Configuration to Deploy Jenkins/Nexus on EKS

**Step 1**: Add **EKS cluster creation** to your Terraform configuration.

```hcl
provider "aws" {
  region = "us-west-2"
}

# Create an EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.24"
  subnets         = ["subnet-abc123", "subnet-def456"]
  vpc_id          = "vpc-789012"
  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.medium"
    }
  }
}
```

**Step 2**: Add the Kubernetes resources for **Jenkins** or **Nexus** to be deployed after the EKS cluster is created. You can use Terraform’s `kubernetes` provider to apply the Kubernetes manifests directly.

Add the following block to handle the Kubernetes provider and apply the manifests.

```hcl
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks.token

  load_config_file = false
}
```

**Step 3**: Add the **Kubernetes manifests** for Jenkins or Nexus in your Terraform configuration. Here's how to apply the manifests using Terraform's `kubernetes_manifest` resource:

#### Jenkins Deployment in Terraform

```hcl
resource "kubernetes_persistent_volume_claim" "jenkins_pvc" {
  metadata {
    name = "jenkins-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "jenkins" {
  metadata {
    name = "jenkins"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "jenkins"
      }
    }
    template {
      metadata {
        labels = {
          app = "jenkins"
        }
      }
      spec {
        container {
          name  = "jenkins"
          image = "jenkins/jenkins:lts"
          port {
            container_port = 8080
          }
          volume_mount {
            name       = "jenkins-pv"
            mount_path = "/var/jenkins_home"
          }
        }
        volume {
          name = "jenkins-pv"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "jenkins_service" {
  metadata {
    name = "jenkins-service"
  }
  spec {
    selector = {
      app = "jenkins"
    }
    type = "LoadBalancer"
    port {
      port        = 8080
      target_port = 8080
    }
  }
}
```

#### Nexus Deployment in Terraform

```hcl
resource "kubernetes_persistent_volume_claim" "nexus_pvc" {
  metadata {
    name = "nexus-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "nexus" {
  metadata {
    name = "nexus"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nexus"
      }
    }
    template {
      metadata {
        labels = {
          app = "nexus"
        }
      }
      spec {
        container {
          name  = "nexus"
          image = "sonatype/nexus3:latest"
          port {
            container_port = 8081
          }
          volume_mount {
            name       = "nexus-pv"
            mount_path = "/nexus-data"
          }
        }
        volume {
          name = "nexus-pv"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.nexus_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nexus_service" {
  metadata {
    name = "nexus-service"
  }
  spec {
    selector = {
      app = "nexus"
    }
    type = "LoadBalancer"
    port {
      port        = 8081
      target_port = 8081
    }
  }
}
```

---

### **Step 4: Initialize and Apply Terraform**

Once your Terraform configuration is ready, you can deploy the EKS cluster along with Jenkins or Nexus using the following commands:

```bash
# Initialize the Terraform working directory
terraform init

# Apply the Terraform plan
terraform apply
```

---

### **Explanation of the Workflow:**

1. **EKS Cluster Creation**:
   - The EKS cluster is created using the `terraform-aws-modules/eks/aws` module.
   - Nodes (EC2 instances) are provisioned in the specified subnets.

2. **Kubernetes Provider**:
   - The Kubernetes provider connects to the newly created EKS cluster by fetching the necessary details (like cluster endpoint, CA certificate, and token).

3. **Jenkins or Nexus Deployment**:
   - The `kubernetes_deployment` resource defines the Jenkins or Nexus container deployment.
   - The `kubernetes_service` resource defines a LoadBalancer to expose the service externally.
   - The `kubernetes_persistent_volume_claim` resource ensures that Jenkins or Nexus data is persisted across reboots.

---

### **Advantages of Using Terraform for Jenkins/Nexus on EKS**:

- **Automation**: Terraform fully automates the process of creating EKS and deploying Jenkins/Nexus.
- **Consistency**: Every time you run `terraform apply`, the same setup is created, ensuring consistency.
- **Scalability**: Easily scale your Jenkins/Nexus setup by adjusting the number of replicas or EKS nodes.
- **Infrastructure as Code**: Maintain your infrastructure setup in code, version-controlled, and auditable.

---

### Next Steps:

- **Terraform Outputs**: Set up Terraform output variables to easily retrieve the LoadBalancer URL for accessing Jenkins or Nexus.
- **IAM Roles**: Configure IAM roles and policies for Jenkins/Nexus pods if required.
- **CI/CD Integration**: Integrate Jenkins with a CI/CD pipeline or Nexus with your development tools for repository management.
