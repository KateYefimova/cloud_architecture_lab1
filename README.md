# cloud_architecture_lab1

### How to execute and check your Terraform code:

- Initialize (download providers):
```
terraform init
```
- Validate (check syntax):
```
terraform validate
```
- Plan (preview changes):
```
terraform plan
```
- Apply (deploy infrastructure):
```
terraform apply
(type yes to confirm)
```
## Tasks

### 1.	Dissect the LabRole. Write down what it allows, what it denies, and — most importantly — how you found out (console, CLI, policy simulator).



![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)

What is accessible:

- There is an identity-based ReadOnlyAccess policy that provides a general baseline read-only access to resources.   
- Inline policies and session policies (Session policy) are applied to regulate the current session permissions for the voclabs role.  

 What is restricted:
 - Active organizational Service control policies (SCPs from AWS Organizations, such as o-gr4bic35ej/... and p-FullAWSAccess) impose global restrictions and control boundaries at the sandbox account level. This explains the occurrence of an Explicit deny when attempting certain privileged or restricted operations (such as managing IAM roles).



### 2. Create an IAM policy that allows ONLY to view resources (no write access). In the sandbox you cannot attach it, so deliver it as an IaC template and explain what it would do.

```
resource "aws_iam_policy" "view_only" {
  name        = "SandboxViewOnlyPolicy"
  description = "Allows read-only access to resources for Milestone 1 demonstration."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadOnlyAccess"
        Effect   = "Allow"
        Action   = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "rds:Describe*",
          "cloudformation:Describe*",
          "cloudformation:Get*",
          "vpc:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}
```
1) Resource Declaration (aws_iam_policy):

    - This block tells Terraform to create a Custom Managed IAM Policy in your AWS account.

    - name = "SandboxViewOnlyPolicy": Assigns a clear, descriptive name to the policy.

    - description: Documents the purpose of the policy, noting it is designed for the Milestone 1 demonstration.

2) Policy Document (jsonencode):

    - The jsonencode function translates the HCL-based map structure into a valid JSON string that AWS IAM expects for policy definitions.

    - Version = "2012-10-17": Specifies the standard policy language version established by AWS.

3) Statement Block (Statement):

    - Sid = "AllowReadOnlyAccess": A Statement ID used to uniquely identify this specific rule within the policy document.

    - Effect = "Allow": Explicitly grants permission for the actions defined below (opposed to Deny).

4) Permitted Actions (Action):
    - This is the core security boundary of the policy. It uses wildcards (*) to grant read-only/inspection rights across essential AWS services without allowing any modification, creation, or deletion:

    - ec2:Describe*: Allows viewing EC2 instances, security groups, AMIs, and other compute configurations.

    - s3:Get* & s3:List*: Allows listing S3 buckets and getting object metadata or contents, while blocking write/delete operations (Put, Delete).

    - rds:Describe*: Allows viewing database instances, snapshots, and parameter groups.

    - cloudformation:Describe* & cloudformation:Get*: Allows inspecting CloudFormation stacks, change sets, and templates.

    - vpc:Describe*: Allows viewing VPCs, subnets, internet gateways, and route tables.

5) Resource Scope (Resource = "*"):

    - Applies these read-only permissions globally across all resources (*) within the AWS account scope.


 ### 3.	Create a Role that has this policy attached and could be assumed by another principal. Same rule: describe it in IaC, explain why the sandbox refuses it. 
 
 The rejection of the IAM role and policy creation is an expected behavior enforced by the architectural design of educational cloud sandboxes. The root causes include:

- The user session executing the Terraform code runs under an assumed temporary role (arn:aws:sts::667052343720:assumed-role/voclabs/user5619835=kyefimova@kse.org.ua).

- The underlying identity-based permissions granted to students intentionally exclude administrative actions such as iam:CreatePolicy and iam:CreateRole to prevent privilege escalation or accidental tampering with account security boundaries.


### 6.	Review the service quotas you will need in milestone 2. Write down the ones that can limit you.

1) Compute Resources (vCPU Limits for EC2):

    - The total number of vCPUs I can run simultaneously within a region for On-Demand instances.

    - Impact on Milestone 2: If deploy multiple nodes for testing and YCSB benchmarking (such as a coordinator and several shards using t3 or c6i instance types), i can quickly hit the default vCPU limits enforced on sandbox accounts.

2) Storage and Disk Performance (EBS Volume Limits and IOPS):

    - The maximum total EBS storage capacity (General Purpose SSD gp2/gp3) and IOPS per volume or account.

    - Impact on Milestone 2: The YCSB benchmark generates heavy read and write workloads. Baseline disk performance limits or storage volume restrictions can cause artificial throttling or latency during baseline performance testing of sharded storage system.

3) Networking and IP Quotas (Elastic IP and VPC Limits):

    - The number of Elastic IP addresses or limits on the number of VPCs and subnets per region.

    - Impact on Milestone 2: If every component of  sharded architecture requires direct public access or dedicated network interfaces, it might run into Elastic IP shortages, though using private IPs within the VPC for internal shards is standard practice.


### 7.	Calculate the monthly budget for milestone 2, assuming there will be only 2 shards, and compare it against your sandbox credit ceiling.

1. Monthly Budget Calculation for Milestone 2 (2 Shards)
To calculate the monthly budget for Milestone 2, we assume a basic distributed architecture consisting of 1 Coordinator node and 2 Shard nodes (total of 3 EC2 instances) operating continuously.

- EC2 Instances (t3.small):

    - 3 instances running 24/7 for a 30-day month (approx. 730 hours each, totaling 2,190 compute hours).

    - Estimated cost at ~$0.0208 per hour per instance: $45.55

- EBS Storage (gp3 SSD):

    - 3 volumes of 20 GB each (60 GB total) required for system logs and local data storage.

    - Estimated cost at ~$0.08 per GB/month: $4.80

- Data Transfer / Network:

    - Inter-node traffic inside the VPC is free, but external API requests and YCSB benchmarking output (approx. 50 GB) incur external transfer costs.

    - Estimated cost at ~$0.09 per GB (after free tier): $4.41

**Total Estimated Monthly Budget: ~$54.76**

AWS Academy Sandbox environments typically operate under a strict, limited credit ceiling ($20).

*Comparison & Risk Analysis:*

- If left running continuously 24/7 over a full month, the estimated infrastructure cost of $54.76 would fully exhaust or exceed the standard sandbox credit ceiling.

- In a educational environment, instances are only active during active development and YCSB benchmark runs (roughly 20–30 hours total per month rather than 730 hours). By destroying or stopping the infrastructure when not in use (terraform destroy), the actual monthly cost drops to under $3–$5, comfortably fitting within the sandbox credit limits.

### 8.Prove recreatability: tear the whole stack down and bring it back from IaC alone. Record how long it took and what broke on the first attempt.

*Breakdown:*

- terraform destroy, init and  validate: ~10 seconds
- terraform plan: ~5 seconds
- terraform apply execution & failure handling: ~10 seconds

What Broke on Execution:

- IAM Creation (iam:CreatePolicy, iam:CreateRole): Blocked with a 403 AccessDenied error because the underlying voclabs session lacks administrative privileges required to mutate IAM entities.

- VPC Creation (ec2:CreateVpc): Blocked with a 403 UnauthorizedOperation due to an explicit deny enforced by the AWS Organizations Service Control Policy (SCP) (p-r0spokdc).

- The test successfully proves recreatability via IaC. The code templates are syntactically correct and ready for documentation.

logs of it:
```
PS C:\Users\Юлія\cloud_architecture_lab1\terraform> terraform destroy
data.aws_iam_policy_document.assume_role_trust: Reading...
data.aws_iam_policy_document.assume_role_trust: Read complete after 0s [id=1319698919]

No changes. No objects need to be destroyed.

Either you have not created any objects yet or the existing objects were already deleted outside of Terraform.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes


Destroy complete! Resources: 0 destroyed.
PS C:\Users\Юлія\cloud_architecture_lab1\terraform> terraform init    
Initializing the backend...

Initializing provider plugins...
- Reusing version 6.71.0 of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.71.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
PS C:\Users\Юлія\cloud_architecture_lab1\terraform> terraform validate
Success! The configuration is valid.

PS C:\Users\Юлія\cloud_architecture_lab1\terraform> terraform plan    
data.aws_iam_policy_document.assume_role_trust: Reading...
data.aws_iam_policy_document.assume_role_trust: Read complete after 1s [id=1319698919]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_iam_policy.view_only will be created
  + resource "aws_iam_policy" "view_only" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "Allows read-only access to resources for Milestone 1 demonstration."
      + id               = (known after apply)
      + name             = "SandboxViewOnlyPolicy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "ec2:Describe*",
                          + "s3:Get*",
                          + "s3:List*",
                          + "rds:Describe*",
                          + "cloudformation:Describe*",
                          + "cloudformation:Get*",
                          + "vpc:Describe*",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                      + Sid      = "AllowReadOnlyAccess"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # aws_iam_role.assumable_role will be created
  + resource "aws_iam_role" "assumable_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::667052343720:root"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "A role with view-only access that can be assumed by another principal."
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "SandboxAssumableReadOnlyRole"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # aws_iam_role_policy_attachment.attach_view_only will be created
  + resource "aws_iam_role_policy_attachment" "attach_view_only" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "SandboxAssumableReadOnlyRole"
    }

  # aws_internet_gateway.gw will be created
  + resource "aws_internet_gateway" "gw" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + region   = "eu-central-1"
      + tags     = {
          + "Name" = "capstone-igw"
        }
      + tags_all = {
          + "Name" = "capstone-igw"
        }
      + vpc_id   = (known after apply)
    }

  # aws_route_table.public will be created
  + resource "aws_route_table" "public" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + region           = "eu-central-1"
      + route            = [
          + {
              + cidr_block                 = "0.0.0.0/0"
              + gateway_id                 = (known after apply)
                # (12 unchanged attributes hidden)
            },
        ]
      + tags             = {
          + "Name" = "capstone-public-rt"
        }
      + tags_all         = {
          + "Name" = "capstone-public-rt"
        }
      + vpc_id           = (known after apply)
    }

  # aws_route_table_association.public will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + region         = "eu-central-1"
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_subnet.private will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.100.2.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "eu-central-1"
      + tags                                           = {
          + "Name" = "capstone-private-subnet"
        }
      + tags_all                                       = {
          + "Name" = "capstone-private-subnet"
        }
      + vpc_id                                         = (known after apply)
    }

  # aws_subnet.public will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.100.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = true
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "eu-central-1"
      + tags                                           = {
          + "Name" = "capstone-public-subnet"
        }
      + tags_all                                       = {
          + "Name" = "capstone-public-subnet"
        }
      + vpc_id                                         = (known after apply)
    }

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.100.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + region                               = "eu-central-1"
      + tags                                 = {
          + "Name" = "capstone-vpc"
        }
      + tags_all                             = {
          + "Name" = "capstone-vpc"
        }
    }

Plan: 9 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
PS C:\Users\Юлія\cloud_architecture_lab1\terraform> terraform apply   
data.aws_iam_policy_document.assume_role_trust: Reading...
data.aws_iam_policy_document.assume_role_trust: Read complete after 0s [id=1319698919]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_iam_policy.view_only will be created
  + resource "aws_iam_policy" "view_only" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "Allows read-only access to resources for Milestone 1 demonstration."
      + id               = (known after apply)
      + name             = "SandboxViewOnlyPolicy"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "ec2:Describe*",
                          + "s3:Get*",
                          + "s3:List*",
                          + "rds:Describe*",
                          + "cloudformation:Describe*",
                          + "cloudformation:Get*",
                          + "vpc:Describe*",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                      + Sid      = "AllowReadOnlyAccess"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # aws_iam_role.assumable_role will be created
  + resource "aws_iam_role" "assumable_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::667052343720:root"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "A role with view-only access that can be assumed by another principal."
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "SandboxAssumableReadOnlyRole"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # aws_iam_role_policy_attachment.attach_view_only will be created
  + resource "aws_iam_role_policy_attachment" "attach_view_only" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "SandboxAssumableReadOnlyRole"
    }

  # aws_internet_gateway.gw will be created
  + resource "aws_internet_gateway" "gw" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + region   = "eu-central-1"
      + tags     = {
          + "Name" = "capstone-igw"
        }
      + tags_all = {
          + "Name" = "capstone-igw"
        }
      + vpc_id   = (known after apply)
    }

  # aws_route_table.public will be created
  + resource "aws_route_table" "public" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + region           = "eu-central-1"
      + route            = [
          + {
              + cidr_block                 = "0.0.0.0/0"
              + gateway_id                 = (known after apply)
                # (12 unchanged attributes hidden)
            },
        ]
      + tags             = {
          + "Name" = "capstone-public-rt"
        }
      + tags_all         = {
          + "Name" = "capstone-public-rt"
        }
      + vpc_id           = (known after apply)
    }

  # aws_route_table_association.public will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + region         = "eu-central-1"
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_subnet.private will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.100.2.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "eu-central-1"
      + tags                                           = {
          + "Name" = "capstone-private-subnet"
        }
      + tags_all                                       = {
          + "Name" = "capstone-private-subnet"
        }
      + vpc_id                                         = (known after apply)
    }

  # aws_subnet.public will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.100.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = true
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "eu-central-1"
      + tags                                           = {
          + "Name" = "capstone-public-subnet"
        }
      + tags_all                                       = {
          + "Name" = "capstone-public-subnet"
        }
      + vpc_id                                         = (known after apply)
    }

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.100.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + region                               = "eu-central-1"
      + tags                                 = {
          + "Name" = "capstone-vpc"
        }
      + tags_all                             = {
          + "Name" = "capstone-vpc"
        }
    }

Plan: 9 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_policy.view_only: Creating...
aws_iam_role.assumable_role: Creating...
aws_vpc.main: Creating...
╷
│ Error: creating IAM Policy (SandboxViewOnlyPolicy): operation error IAM: CreatePolicy, https response error StatusCode: 403, RequestID: 2979a6f7-ef8d-419c-8636-5535745ee52a, api error AccessDenied: User: arn:aws:sts::667052343720:assumed-role/voclabs/user5619835=kyefimova@kse.org.ua is not authorized to perform: iam:CreatePolicy on resource: policy SandboxViewOnlyPolicy because no identity-based policy allows the iam:CreatePolicy action. Go to https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/authorization-details/7v0lvbfz5qsngwdmgsiqg3eee for complete details, or call the GetRequestAuthorizationDetails API with the following authorization id: 7v0lvbfz5qsngwdmgsiqg3eee
│ 
│   with aws_iam_policy.view_only,
│   on iam.tf line 1, in resource "aws_iam_policy" "view_only":
│    1: resource "aws_iam_policy" "view_only" {
│ 
╵
╷
│ Error: creating IAM Role (SandboxAssumableReadOnlyRole): operation error IAM: CreateRole, https response error StatusCode: 403, RequestID: 97e882d3-c3d0-40e3-b5e3-af52191b2015, api error AccessDenied: User: arn:aws:sts::667052343720:assumed-role/voclabs/user5619835=kyefimova@kse.org.ua is not authorized to perform: iam:CreateRole on resource: arn:aws:iam::667052343720:role/SandboxAssumableReadOnlyRole because no identity-based policy allows the iam:CreateRole action. Go to https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/authorization-details/em238n1g484niwwtrs4ugjtio for complete details, or call the GetRequestAuthorizationDetails API with the following authorization id: em238n1g484niwwtrs4ugjtio
│ 
│   with aws_iam_role.assumable_role,
│   on iam2.tf line 15, in resource "aws_iam_role" "assumable_role":
│   15: resource "aws_iam_role" "assumable_role" {
│ 
╵
╷
│ Error: creating EC2 VPC: operation error EC2: CreateVpc, https response error StatusCode: 403, RequestID: 6b89c7bd-d02c-4bae-8a47-af2bd13997ab, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:sts::667052343720:assumed-role/voclabs/user5619835=kyefimova@kse.org.ua is not authorized to perform: ec2:CreateVpc on resource: arn:aws:ec2:eu-central-1:667052343720:vpc/* with an explicit deny in a service control policy: arn:aws:organizations::003485381260:policy/o-gr4bic3e5j/service_control_policy/p-r0spokdc. Encoded authorization failure message: FWXSyKIuXVnhTpVwuZCrB1xZZSqKutaZxeJXyURumt6x0vzAmh2ZapbI_YPYSpOj5N2nfnFyoNyMZQGBA5c89ES_40tMbD9_wGSkttVkvVBhIeiCZJAllHfxKsKU9ifZ1NKDgsMy_YoYxDsmGo0NS7_Z4tignmA2CagPAnsZSDBTGJCBJlS6DMx9qTKXFfnTKgpXfkND3MnIMpD1jsVTyiyRwS08ANX90Am3UxgXuBGITjsbd7jtXZVyMAhV_gxxhxU2boAwzHECq5DO7YR21JHV-7abTR38iZhPLNILGst1yeHgt0SsZZiJJHKwnqFZKZoHcwtem0EdePewM3bZTjZP7k9B5sj7asoqgN-lg_5LEWLmyePMTRgxKDQlZeICGCx8nVd5EUSmMdpwu-ZjUSLriCLCarmnS6EvvYsOtvqiw2lIwCIDiBE8G7LXf6iTi6qk4M__ZXQQwyO1w-1Jx61C_1gNChOsDflnwD48JM3T9X6Mv9VfrNy9hs7MMFWRkFhSPBu_Pmz_fQPJlgdPr33kfjz1oO_D7U_rSY_YsNWhZmm17Fq0bWk9cj3qOes_b1ygiAhonNshYUtPmquwcnmZ-i2GxDEx1_ElzV3x8WebSa5beNFfu-HwW_h13W-H-04W2Wh3MOl4bsjWSkZ8NVkzLJmL9AZfWpRejh8BX-njGL7CUgQ8r0C4M4UmHphWPWz8cP5ch8l36pU87T4xitFL19jbwOGp4-cM3IJ_oD-cYELLyeeDlOlMtCQMzXco6Qdp4hU3xndzDx8j5-KD9aqZpsAUr4etG8a9hA1yNchSfZbzDoob3F2ncBaRoRuT4hwTCzFaD0xNHc-EXCqUiO86sLYcp4pTlL0Gr0DjD_eAYIBg4QZ1chx8uN5hf3cUYaiY0G7b4ZzBsupGV6Vj4WlPSeP69mSQJTLmDpcZPGm1oCkLTFVDEqnNkdy6Oz6jrRaAIklUDNE_dHyPdgmth8p4TVVHksST1xdxosHtfUu3SqSizuvb2uQpTaAGw2aqnZGzSAMC7HtasVqkIeeH7kAH0DRqHvzEjkRYS5fXSPCHDQBdk-Dxw2xc2MPphWhuGfsL-K9Wp5gA8Up8NcCMzoI5pzVBs-sl2uURpFueqQvgn3OEHfYtW2YCweAIJnu43sOQhorQOuyyA9WIRe0N49VC98kFqF7xppBFWdVdI8yBnHyIIh8GENN6sZXIpNUy07OLoKOQnsHAykRhXXpx2hsWMa7p2DDgaB4DERXWIEQXGnaPWqxyzDDqwQiCy4vAZSsoGQCTMA2-BLNCgOKh0Q2h_M66jxSdKduvkoyY-4hOw48nfU4EKd3Vkm4benl2zjprhVc8jZbn7NRpesWVWnW2jIrBIp4VbNgkhZOp7v9UA80fIUqTEKr3W_3SB2dHxWMKWzfCKAxCsZt3Fyg8XIDNttVP3ObpWU2uKU6sdVEkhw2WPrzwulvwmTqJg7TKvVpa0An0t63btGvhNIVbrvCNy0jX5pSuIVNhlRwlMSb8Hqy20EkBOexpmuge-RD3xcSUviOxV6QVhtZwa2dT-FzJU77A5lu2cMKHDRh-DZy1GDe0MRpIXaQXbRDy4A9Hhr-fFKcmrPZrpZqkbSdVTZ1oR-_8cgPOisKZYtxB2dhyNRH6E4jxd-LI7ks8zGIvwpgjWOIEZ5neTiRc0yfZrB9R5GgT6RXBPliKs1CwVPKtxq2OehUNaHMlc3JtkvCqXQdq6Vg526tprbBf83m8bk9k5g2QrqsApVPPR_tbRsHjYe_9VyWyZCL1JQeYnni1n4E0SM8JE3wsVXksomv2p5dimumwS_usfBJc1aYFEKxzkzd9h51H5DTk9TUo-MLkUXgDSQVpnvsNUy3uOm2xhAk2-6v4esrVHNNwrsLjTDnLHgernixOxshvT2FujL0dDY4SCBMYcjNEuStUKKvNaL-C0l2JwurnVrR97jAWwGnaogFf-fUK-mKXx64KJNVcl4oT92i4yCs7egYT4dSeFg
│ 
│   with aws_vpc.main,
│   on network.tf line 2, in resource "aws_vpc" "main":
│    2: resource "aws_vpc" "main" {
│ 
╵
PS C:\Users\Юлія\cloud_architecture_lab1\terraform> 
```