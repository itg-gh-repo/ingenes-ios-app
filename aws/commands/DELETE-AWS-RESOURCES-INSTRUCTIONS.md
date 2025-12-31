# TAG2 AWS Resources Deletion Guide

## Overview

This document provides detailed instructions for permanently deleting all AWS resources used by the TAG2 iOS application.

---

## AWS Resources That Will Be Deleted

| Resource Type | Resource Identifier | Description |
|---------------|---------------------|-------------|
| **Cognito User Pool** | `us-east-1_93HMCJqvJ` | User authentication pool with all registered users |
| **Cognito App Client** | `6s98m6r64ql20ab09phvj2of2n` | iOS app client (deleted with User Pool) |
| **Cognito Identity Pool** | `us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd` | Provides temporary AWS credentials |
| **Secrets Manager Secret** | `TAG2/FileMaker/Credentials` | FileMaker API credentials |

**Region:** `us-east-1` (N. Virginia)

---

## Prerequisites

### 1. Install AWS CLI

If you don't have the AWS CLI installed:

**macOS (using Homebrew):**
```bash
brew install awscli
```

**macOS (using installer):**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Verify installation:**
```bash
aws --version
```

### 2. Configure AWS Credentials

You need AWS credentials with sufficient permissions to delete these resources.

```bash
aws configure
```

Enter the following when prompted:
- **AWS Access Key ID:** Your access key
- **AWS Secret Access Key:** Your secret key
- **Default region name:** `us-east-1`
- **Default output format:** `json`

### 3. Required IAM Permissions

Your AWS user/role must have the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DeleteUserPool",
                "cognito-idp:DescribeUserPool",
                "cognito-idp:DeleteUserPoolDomain",
                "cognito-identity:DeleteIdentityPool",
                "cognito-identity:DescribeIdentityPool",
                "secretsmanager:DeleteSecret",
                "secretsmanager:DescribeSecret",
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

Or use the AWS managed policies:
- `AmazonCognitoPowerUser`
- `SecretsManagerReadWrite`

---

## Execution Instructions

### Step 1: Navigate to the Script Directory

```bash
cd /Users/ozz/Desktop/TAG2/aws/commands
```

### Step 2: Make the Script Executable

```bash
chmod +x delete-aws-resources.sh
```

### Step 3: (Optional) Dry Run - Verify Resources Exist

Before deletion, verify the resources exist:

```bash
# Check Cognito User Pool
aws cognito-idp describe-user-pool \
    --user-pool-id us-east-1_93HMCJqvJ \
    --region us-east-1

# Check Cognito Identity Pool
aws cognito-identity describe-identity-pool \
    --identity-pool-id us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd \
    --region us-east-1

# Check Secrets Manager Secret
aws secretsmanager describe-secret \
    --secret-id TAG2/FileMaker/Credentials \
    --region us-east-1
```

### Step 4: Execute the Deletion Script

```bash
./delete-aws-resources.sh
```

### Step 5: Confirm Deletion

The script will:
1. Verify AWS CLI is installed
2. Verify AWS credentials are valid
3. Display a warning about the resources to be deleted
4. Ask you to type `DELETE-TAG2-AWS` to confirm
5. Ask for a final `yes/no` confirmation
6. Delete the resources in the correct order

---

## Manual Deletion (Alternative)

If you prefer to delete resources manually via AWS Console or CLI:

### Delete via AWS Console

1. **Secrets Manager:**
   - Go to: https://console.aws.amazon.com/secretsmanager/home?region=us-east-1
   - Find secret: `TAG2/FileMaker/Credentials`
   - Click "Delete secret"

2. **Cognito Identity Pool:**
   - Go to: https://console.aws.amazon.com/cognito/federated?region=us-east-1
   - Find identity pool with ID: `us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd`
   - Click "Delete identity pool"

3. **Cognito User Pool:**
   - Go to: https://console.aws.amazon.com/cognito/users?region=us-east-1
   - Find user pool: `us-east-1_93HMCJqvJ`
   - Click "Delete user pool"

### Delete via AWS CLI (Manual Commands)

```bash
# 1. Delete Secrets Manager Secret (force immediate deletion)
aws secretsmanager delete-secret \
    --secret-id "TAG2/FileMaker/Credentials" \
    --force-delete-without-recovery \
    --region us-east-1

# 2. Delete Cognito Identity Pool
aws cognito-identity delete-identity-pool \
    --identity-pool-id "us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd" \
    --region us-east-1

# 3. Delete Cognito User Pool (this also deletes the app client)
aws cognito-idp delete-user-pool \
    --user-pool-id "us-east-1_93HMCJqvJ" \
    --region us-east-1
```

---

## Post-Deletion Cleanup

After deleting the AWS resources, you should also:

### 1. Check for IAM Roles

Cognito Identity Pool may have created IAM roles. Check and delete if needed:

```bash
# List roles that might be related to TAG2
aws iam list-roles --query "Roles[?contains(RoleName, 'TAG2') || contains(RoleName, 'Cognito')].RoleName" --output table
```

If you find roles like:
- `Cognito_TAG2Auth_Role`
- `Cognito_TAG2Unauth_Role`

Delete them:
```bash
# First, detach any policies
aws iam list-attached-role-policies --role-name "ROLE_NAME"
aws iam detach-role-policy --role-name "ROLE_NAME" --policy-arn "POLICY_ARN"

# Then delete the role
aws iam delete-role --role-name "ROLE_NAME"
```

### 2. Clean Up Local Configuration

Remove or update these files in the project:
- `tag2/Config/Debug.xcconfig`
- `tag2/Config/Release.xcconfig`

### 3. Clear Keychain on Test Devices

Users/testers should clear the app data or reinstall the app to remove cached tokens.

### 4. Update CI/CD

If you have any CI/CD pipelines referencing these resources, update them accordingly.

---

## Recovery Options

### Secrets Manager Secret Recovery

If you used the standard deletion (not force delete), the secret will be in a "pending deletion" state for 7-30 days (default 7 days). You can recover it:

```bash
aws secretsmanager restore-secret \
    --secret-id "TAG2/FileMaker/Credentials" \
    --region us-east-1
```

### Cognito Resources

**Cognito User Pools and Identity Pools cannot be recovered once deleted.** All user data will be permanently lost.

If you need to recreate them:
1. Refer to the setup documentation in `memory-bank/AWS-COGNITO-IOS-SETUP-GUIDE.md`
2. Update the app configuration with new resource IDs

---

## Troubleshooting

### Error: "User pool does not exist"

The user pool was already deleted or the ID is incorrect.

### Error: "AccessDeniedException"

Your AWS credentials don't have sufficient permissions. Ensure you have the required IAM permissions listed above.

### Error: "ResourceNotFoundException"

The resource was already deleted or never existed.

### Error: "Cannot delete user pool while domain exists"

Delete the domain first:
```bash
aws cognito-idp delete-user-pool-domain \
    --domain "YOUR_DOMAIN" \
    --user-pool-id "us-east-1_93HMCJqvJ" \
    --region us-east-1
```

---

## Support

For questions or issues:
1. Check AWS documentation: https://docs.aws.amazon.com/
2. Review CloudTrail logs for API call history
3. Contact your AWS administrator

---

## Changelog

| Date | Description |
|------|-------------|
| 2024-12-30 | Initial creation of deletion script and documentation |
