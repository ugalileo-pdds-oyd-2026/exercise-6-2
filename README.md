# Exercise 6.2 — ALB with Listener and Target Group

**Course:** Optimizaciones y Desempeño — Cloud Deployment Automation
**Session:** 6 — May 28, 2026
**Instructor reference solution**

---

## Teacher's Intent

This exercise teaches students that a load balancer is not a single resource — it is a composition of at least four tightly coupled pieces: a security group that gates traffic, a target group that defines *where* traffic goes, the load balancer itself, and a listener that connects the two. Students often create an ALB and are surprised when nothing routes correctly; the typical culprit is a missing listener or a security group that does not permit the listener port. Walking through each piece in isolation forces students to think about data flow rather than just "create ALB."

The setup workspace models a production reality: the VPC and EC2 instance already exist and are owned by another team. Students must look these resources up by tag rather than hardcoding IDs — a habit that prevents the most common Terraform bug in long-lived environments (state drift when an ID changes after a recreation). `data` sources make this lookup explicit and readable; if the VPC is renamed, the error surfaces at plan time, not silently at apply.

The health check block on the target group teaches a concept students will hit in production: an ALB can provision successfully while the target group shows all instances as unhealthy, causing 503s. Understanding the health check path, interval, and thresholds is what lets engineers diagnose that in under five minutes instead of two hours.

Finally, separating the `terraform.tfvars` file with an `environment` variable mirrors real multi-environment workflows. Students learn that the same Terraform code, combined with different tfvars files, can describe dev, staging, and production — the foundation of every serious IaC setup.

---

## Prerequisites

- AWS CLI configured with credentials that can create VPC, EC2, and ALB resources.
- Terraform >= 1.8 installed and on PATH.
- A new empty directory initialized as a Git repository.

## Before You Start — Apply the Setup Workspace

The `setup/` directory provisions the pre-existing infrastructure (VPC + EC2) that the root workspace references via data sources.

```bash
cd setup/
terraform init
terraform apply -auto-approve
cd ..
```

Note the `vpc_name` (`mediastream-vpc`) and `instance_name` (`mediastream-api`) from `setup/variables.tf` — these are the tag values your data sources will use.

---

## Step-by-Step Implementation

### Step 1 — Scaffold

**Files created:** `.gitignore`, `provider.tf`, `setup/` (all three files), `README.md`, `evidence/` directory.

**Teaching point:** The repository structure is established before any root-workspace resources exist. The `provider.tf` is a given starter — students should not modify it, reinforcing the idea that provider configuration is a separate concern from resource configuration. The `setup/` workspace is applied once here; after that it is not touched again.

---

### Step 2 — Task 1: Variables

**Files created:** `variables.tf`, `terraform.tfvars`

**Teaching point:** Defining all variables up front is a discipline, not a formality. Every variable must have `type` and `description` — Terraform's plan output will display descriptions to anyone who runs the code, making the intent self-documenting. The `environment` variable has no default, which forces the caller to always make an explicit choice — a useful guard against accidentally deploying to the wrong environment.

#### Evidence

```
<!-- placeholder: terraform validate output after creating variables.tf -->
```

---

### Step 3 — Task 2: Data Sources

**Files created:** `data.tf`

**Teaching point:** `data` blocks read existing infrastructure without owning it. Using tag-based lookups (`Name = var.vpc_name`) instead of hardcoded IDs means the code is portable: the same repository works for a colleague who applied `setup/` in their own account. Students often confuse `data "aws_subnets"` with `data "aws_subnet"` (singular/plural) — the plural form returns a list and is the right choice when you want all matching subnets.

#### Evidence

```
<!-- placeholder: terraform plan output showing data sources resolved -->
```

---

### Step 4 — Task 3: ALB Security Group

**Files modified:** `main.tf` (created)

**Teaching point:** The ALB needs its own security group, separate from the EC2 instance's security group. A common mistake is attaching the EC2 security group to the ALB — this works until someone tightens the EC2 SG to only accept traffic from the ALB, at which point a circular dependency causes confusion. Keeping them separate is both architecturally cleaner and required for least-privilege egress rules.

#### Evidence

```
<!-- placeholder: terraform plan showing aws_security_group.alb -->
```

---

### Step 5 — Task 4: Target Group

**Files modified:** `main.tf`

**Teaching point:** The target group is the "bucket" that holds the registered instances and defines the health check contract. The `matcher = "200"` means the ALB expects an HTTP 200 from the health check path; `interval = 30` and `healthy_threshold = 2` means a newly registered instance is considered healthy after just two successful checks (60 seconds). Students should understand that changing these parameters affects how quickly traffic shifts during deployments.

#### Evidence

```
<!-- placeholder: terraform plan showing aws_lb_target_group.api -->
```

---

### Step 6 — Task 5: ALB, Listener, and Target Registration

**Files modified:** `main.tf`

**Teaching point:** Three resources work together here: the `aws_lb` creates the load balancer itself (the endpoint), the `aws_lb_listener` tells it which port to accept traffic on and where to forward it, and the `aws_lb_target_group_attachment` registers the specific EC2 instance. Removing any one of these three would break the data path in a way that is easy to diagnose once you know the model.

#### Evidence

```
<!-- placeholder: terraform plan showing aws_lb, aws_lb_listener, aws_lb_target_group_attachment -->
```

---

### Step 7 — Task 6: Outputs and Apply

**Files created:** `outputs.tf`

**Teaching point:** Outputs are the public interface of a Terraform workspace. Downstream automation (CI/CD pipelines, other Terraform workspaces) reads outputs to discover resource identifiers without needing to parse state files. Defining `alb_dns_name` as an output means an application deployment step can read the ALB endpoint directly from `terraform output -raw alb_dns_name`.

#### Evidence

```
<!-- placeholder: terraform apply output showing all resources created -->
```

---

### Step 8 — Task 7: Evidence Collection

**Files created:** `evidence/state-list.txt`, `evidence/outputs.txt`

**Teaching point:** `terraform state list` is the first command to run when debugging a Terraform workspace — it shows exactly which resources Terraform is tracking. `terraform output` is how you hand off information from one workspace or pipeline step to the next. Capturing both in version control gives a snapshot that can be compared against the state of a broken environment.

#### Evidence

See [## Evidence](#evidence) section below.

---

## Evidence

### Setup Apply

```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 12s [id=vpc-07a057c2de7173651]
aws_internet_gateway.main: Creating...
aws_subnet.public[0]: Creating...
aws_subnet.public[1]: Creating...
aws_security_group.ec2: Creating...
aws_internet_gateway.main: Creation complete after 1s [id=igw-021c407dab116b2c2]
aws_route_table.public: Creating...
aws_route_table.public: Creation complete after 1s [id=rtb-0216ce691793aeb0f]
aws_security_group.ec2: Creation complete after 4s [id=sg-0e1fc97e7eed60259]
aws_subnet.public[0]: Creation complete after 12s [id=subnet-036e189dd57b4b7fb]
aws_subnet.public[1]: Creation complete after 12s [id=subnet-0db585e45274205af]
aws_instance.api: Creating...
aws_route_table_association.public[1]: Creation complete after 1s [id=rtbassoc-09269e9432cee417f]
aws_route_table_association.public[0]: Creation complete after 1s [id=rtbassoc-00bd1debf55301dcb]
aws_instance.api: Creation complete after 13s [id=i-00b0ea81d9a6ba3bf]

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

instance_id = "i-00b0ea81d9a6ba3bf"
vpc_id = "vpc-07a057c2de7173651"
```

### Task 1 — Variables (terraform validate)

```
$ terraform validate
Success! The configuration is valid.
```

### Task 2 — Data Sources (terraform plan)

```
$ terraform plan -var-file=terraform.tfvars
data.aws_vpc.main: Reading...
data.aws_instance.api: Reading...
data.aws_vpc.main: Read complete after 1s [id=vpc-07a057c2de7173651]
data.aws_subnets.public: Reading...
data.aws_subnets.public: Read complete after 0s [id=us-east-1]
data.aws_instance.api: Read complete after 2s [id=i-00b0ea81d9a6ba3bf]

No changes. Your infrastructure matches the configuration.
```

### Task 3 — ALB Security Group (terraform plan excerpt)

```
$ terraform plan -var-file=terraform.tfvars

Terraform will perform the following actions:

  # aws_security_group.alb will be created
  + resource "aws_security_group" "alb" {
      + description = "Allow HTTP traffic to the ALB"
      + egress      = [
          + { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] },
        ]
      + ingress     = [
          + { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
        ]
      + name        = "mediastream-alb-sg"
      + vpc_id      = "vpc-07a057c2de7173651"
      + tags        = { "Name" = "mediastream-alb-sg" }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

### Task 4 — Target Group (terraform plan excerpt)

```
$ terraform plan -var-file=terraform.tfvars

  # aws_lb_target_group.api will be created
  + resource "aws_lb_target_group" "api" {
      + name        = "mediastream-api-tg"
      + port        = 80
      + protocol    = "HTTP"
      + target_type = "instance"
      + vpc_id      = "vpc-07a057c2de7173651"

      + health_check {
          + healthy_threshold   = 2
          + interval            = 30
          + matcher             = "200"
          + path                = "/"
          + protocol            = "HTTP"
          + unhealthy_threshold = 3
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

### Task 5 — ALB, Listener, Attachment (terraform plan excerpt)

```
$ terraform plan -var-file=terraform.tfvars

  # aws_lb.main will be created
  # aws_lb_listener.http will be created
  # aws_lb_target_group.api will be created
  # aws_lb_target_group_attachment.api will be created
  # aws_security_group.alb will be created

Plan: 5 to add, 0 to change, 0 to destroy.
```

### Task 6 — terraform apply

```
$ terraform apply -var-file=terraform.tfvars -auto-approve

aws_lb_target_group.api: Creation complete after 2s [id=arn:aws:elasticloadbalancing:us-east-1:439426070073:targetgroup/mediastream-api-tg/c14f1956178fc893]
aws_lb_target_group_attachment.api: Creation complete after 0s
aws_security_group.alb: Creation complete after 4s [id=sg-00dc75af73ea53637]
aws_lb.main: Creating...
aws_lb.main: Creation complete after 3m3s [id=arn:aws:elasticloadbalancing:us-east-1:439426070073:loadbalancer/app/mediastream-alb/48dfa6b70dbf47de]
aws_lb_listener.http: Creation complete after 0s [id=arn:aws:elasticloadbalancing:us-east-1:439426070073:listener/app/mediastream-alb/48dfa6b70dbf47de/3a0d32701d4631e9]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

alb_arn      = "arn:aws:elasticloadbalancing:us-east-1:439426070073:loadbalancer/app/mediastream-alb/48dfa6b70dbf47de"
alb_dns_name = "mediastream-alb-602667321.us-east-1.elb.amazonaws.com"
target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:439426070073:targetgroup/mediastream-api-tg/c14f1956178fc893"
```

### Task 7 — terraform state list

```
<!-- placeholder: contents of evidence/state-list.txt -->
```

### Task 7 — terraform output

```
<!-- placeholder: contents of evidence/outputs.txt -->
```
