# Terraform foundation workflow

Nothing has been deployed. Review the code and account boundaries before running AWS operations. Use an existing, separately configured Project 3 profile; do not overwrite the default profile or Project 2 credentials.

```bash
cd ~/Projects/aws-enterprise-hybrid-migration
export AWS_PROFILE=project3-network
aws sts get-caller-identity
```

Confirm the returned account is the intended network account. The profile name above is a convention, not an assertion that it exists.

## 1. Bootstrap

Create an ignored `terraform/bootstrap/terraform.tfvars` with `aws_account_id` (12 digits) and a globally unique `state_bucket_name`. Do not put credentials in it.

```bash
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap fmt -check
terraform -chdir=terraform/bootstrap validate
terraform -chdir=terraform/bootstrap plan -out=bootstrap.tfplan
```

Review the plan, account and cost before applying the saved plan. The bucket has `prevent_destroy`; do not remove protection simply to clean up. Keep bootstrap local state secure until migration.

After the bucket exists, copy the network `backend.tf.example` to `backend.tf`, and create an ignored `backend.tfbackend` containing the actual bucket, `key = "project3/network/terraform.tfstate"`, `region = "eu-west-2"`, `encrypt = true` and `use_lockfile = true`. Migrate bootstrap state separately: add the same empty S3 backend block in bootstrap, with a separate `project3/bootstrap/terraform.tfstate` key, then run `terraform init -migrate-state -backend-config=backend.tfbackend` there. Securely retain a backup and verify remote state before removing local copies. Restrict IAM to the appropriate bucket/key and lock-file operations.

## 2. Network

Create an ignored network `terraform.tfvars` containing the expected `aws_account_id`, and two available zone names in `availability_zones`, for example `["eu-west-2a", "eu-west-2b"]`. Confirm proposed CIDRs do not overlap existing networks.

```bash
terraform -chdir=terraform/environments/network init -backend-config=backend.tfbackend
terraform -chdir=terraform/environments/network fmt -check
terraform -chdir=terraform/environments/network validate
terraform -chdir=terraform/environments/network plan -out=network.tfplan
```

Review before applying. Commit generated `.terraform.lock.hcl` files after initialization; do not commit plans, state, backend value files or local variables. Provider validation is not proof of successful deployment or connectivity.

## Next milestones

1. Record account ownership, non-overlapping CIDRs, VM sizing, router IPsec/NAT support and budget.
2. Add Transit Gateway and VPN with explicit route propagation and tunnel testing.
3. Build the on-premises application/database, capture backups and baseline tests.
4. Implement migration rehearsal, cutover, rollback and recovery evidence.
