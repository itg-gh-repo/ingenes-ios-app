# Ingenes Cognito User Creation Guide

## Overview

This document provides detailed instructions for creating new users in the Ingenes Cognito User Pool using the provided bash script.

---

## User Pool Information

| Property | Value |
|----------|-------|
| **User Pool ID** | `us-east-1_93HMCJqvJ` |
| **Region** | `us-east-1` (N. Virginia) |
| **Temporary Password** | `TempPassword123!@` |

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

```bash
aws configure
```

Enter when prompted:
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
                "cognito-idp:AdminCreateUser",
                "cognito-idp:AdminGetUser",
                "cognito-idp:AdminDeleteUser"
            ],
            "Resource": "arn:aws:cognito-idp:us-east-1:*:userpool/us-east-1_93HMCJqvJ"
        },
        {
            "Effect": "Allow",
            "Action": "sts:GetCallerIdentity",
            "Resource": "*"
        }
    ]
}
```

Or use the AWS managed policy: `AmazonCognitoPowerUser`

---

## Execution Instructions

### Step 1: Navigate to the Script Directory

```bash
cd /Users/ozz/Desktop/Ingenes/aws/commands
```

### Step 2: Make the Script Executable

```bash
chmod +x create-cognito-user.sh
```

### Step 3: Run the Script

#### Basic Usage (Email Only)

```bash
./create-cognito-user.sh user@example.com
```

#### With First and Last Name

```bash
./create-cognito-user.sh user@example.com John Doe
```

#### With All Custom Attributes

```bash
./create-cognito-user.sh user@example.com John Doe "My Store Name" CUST001
```

### Step 4: Share Credentials with User

After successful creation, share with the new user:
- **Email:** (the email you provided)
- **Temporary Password:** `TempPassword123!@`
- **First Login:** User must change password on first login

---

## Script Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `email` | Yes | User's email address (also used as username) |
| `firstName` | No | User's first name (stored in `custom:firstName`) |
| `lastName` | No | User's last name (stored in `custom:lastName`) |
| `storeName` | No | Associated store name (stored in `custom:storeName`) |
| `customerId` | No | Customer identifier (stored in `custom:customerId`) |

---

## Usage Examples

### Example 1: Create a Basic User

```bash
./create-cognito-user.sh john.smith@company.com
```

**Output:**
```
==============================================================================
           Ingenes Cognito User Creation
==============================================================================

[INFO] Running pre-flight checks...
[SUCCESS] All checks passed

[INFO] Creating user: john.smith@company.com
[SUCCESS] User created successfully!

User Details:
  Email:              john.smith@company.com
  Temporary Password: TempPassword123!@

[WARNING] User must change password on first login.
==============================================================================
```

### Example 2: Create User with Full Details

```bash
./create-cognito-user.sh jane.doe@example.com Jane Doe "ABC Store" CUST123
```

**Output:**
```
User Details:
  Email:              jane.doe@example.com
  Temporary Password: TempPassword123!@
  First Name:         Jane
  Last Name:          Doe
  Store Name:         ABC Store
  Customer ID:        CUST123
```

### Example 3: Store Name with Spaces

Use quotes for values containing spaces:

```bash
./create-cognito-user.sh user@test.com Bob Wilson "The Great Store" C001
```

---

## Creating Multiple Users

### Using a Loop

Create multiple users from a list:

```bash
#!/bin/bash
# Create a file called users.txt with one email per line

while IFS= read -r email; do
    ./create-cognito-user.sh "$email"
done < users.txt
```

### Using a CSV File

For users with full details, create a CSV file:

```bash
#!/bin/bash
# users.csv format: email,firstName,lastName,storeName,customerId

while IFS=, read -r email firstName lastName storeName customerId; do
    ./create-cognito-user.sh "$email" "$firstName" "$lastName" "$storeName" "$customerId"
done < users.csv
```

---

## Manual User Creation (Alternative)

### Via AWS Console

1. Go to: https://console.aws.amazon.com/cognito/users?region=us-east-1
2. Select User Pool: `us-east-1_93HMCJqvJ`
3. Click "Users" tab
4. Click "Create user"
5. Fill in the details:
   - Username: email address
   - Email: same email address
   - Temporary password: `TempPassword123!@`
   - Mark email as verified
6. Click "Create user"

### Via AWS CLI (Direct Command)

```bash
aws cognito-idp admin-create-user \
    --user-pool-id us-east-1_93HMCJqvJ \
    --username "user@example.com" \
    --temporary-password "TempPassword123!@" \
    --user-attributes \
        Name=email,Value="user@example.com" \
        Name=email_verified,Value=true \
        Name=custom:firstName,Value="John" \
        Name=custom:lastName,Value="Doe" \
    --message-action SUPPRESS \
    --region us-east-1
```

---

## Managing Existing Users

### List All Users

```bash
aws cognito-idp list-users \
    --user-pool-id us-east-1_93HMCJqvJ \
    --region us-east-1
```

### Get User Details

```bash
aws cognito-idp admin-get-user \
    --user-pool-id us-east-1_93HMCJqvJ \
    --username "user@example.com" \
    --region us-east-1
```

### Delete a User

```bash
aws cognito-idp admin-delete-user \
    --user-pool-id us-east-1_93HMCJqvJ \
    --username "user@example.com" \
    --region us-east-1
```

### Reset User Password

```bash
aws cognito-idp admin-set-user-password \
    --user-pool-id us-east-1_93HMCJqvJ \
    --username "user@example.com" \
    --password "TempPassword123!@" \
    --temporary \
    --region us-east-1
```

### Update User Attributes

```bash
aws cognito-idp admin-update-user-attributes \
    --user-pool-id us-east-1_93HMCJqvJ \
    --username "user@example.com" \
    --user-attributes Name=custom:storeName,Value="New Store Name" \
    --region us-east-1
```

---

## Troubleshooting

### Error: "User already exists"

The user already exists in the pool. To recreate:

```bash
# Delete existing user
aws cognito-idp admin-delete-user \
    --user-pool-id us-east-1_93HMCJqvJ \
    --username "user@example.com" \
    --region us-east-1

# Then create again
./create-cognito-user.sh user@example.com
```

### Error: "Invalid email format"

Ensure the email follows standard format: `user@domain.com`

### Error: "AccessDeniedException"

Your AWS credentials don't have sufficient permissions. Ensure you have `cognito-idp:AdminCreateUser` permission.

### Error: "InvalidParameterException"

Check that:
- Email is valid
- Custom attribute names match the User Pool schema
- Values don't exceed maximum length

### User Status Shows "FORCE_CHANGE_PASSWORD"

This is expected! The user needs to log in to the app and change their temporary password.

---

## User Lifecycle

1. **FORCE_CHANGE_PASSWORD** - Initial state after creation
2. **CONFIRMED** - After user changes password on first login
3. **RESET_REQUIRED** - If admin resets password
4. **DISABLED** - If admin disables the user

---

## Security Notes

1. **Temporary Password**: The script uses `TempPassword123!@` as temporary password. This meets Cognito's password policy requirements.

2. **Password Change Required**: Users MUST change their password on first login. The app enforces this.

3. **Email Suppression**: The `--message-action SUPPRESS` flag prevents Cognito from sending welcome emails. Share credentials manually.

4. **Email Verification**: Emails are marked as verified automatically (`email_verified=true`) since users are created by admin.

---

## Custom Attributes Reference

The Ingenes User Pool supports these custom attributes:

| Attribute | Description | Example |
|-----------|-------------|---------|
| `custom:firstName` | User's first name | John |
| `custom:lastName` | User's last name | Doe |
| `custom:storeName` | Associated store | My Store |
| `custom:customerId` | Customer ID | CUST001 |
| `custom:locationStatus` | Location status | Active |
| `custom:recordId` | FileMaker record ID | REC123 |

---

## Changelog

| Date | Description |
|------|-------------|
| 2024-12-30 | Initial creation of user creation script and documentation |
