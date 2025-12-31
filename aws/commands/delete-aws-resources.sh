#!/bin/bash

#===============================================================================
# TAG2 AWS Resources Deletion Script
#===============================================================================
# WARNING: This script will PERMANENTLY DELETE all AWS resources used by TAG2.
# This action is IRREVERSIBLE. Make sure you have backups before proceeding.
#
# AWS Services to be deleted:
#   1. Cognito User Pool (includes all users and app clients)
#   2. Cognito Identity Pool
#   3. Secrets Manager Secret
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - Appropriate IAM permissions to delete these resources
#   - AWS credentials configured (aws configure)
#===============================================================================

set -e  # Exit on any error

# Configuration - TAG2 AWS Resource Identifiers
AWS_REGION="us-east-1"
COGNITO_USER_POOL_ID="us-east-1_93HMCJqvJ"
COGNITO_IDENTITY_POOL_ID="us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd"
SECRETS_MANAGER_SECRET_NAME="TAG2/FileMaker/Credentials"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        echo "  Installation: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    log_success "AWS CLI is installed"
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured or are invalid."
        echo "  Run 'aws configure' to set up your credentials."
        exit 1
    fi

    local account_id=$(aws sts get-caller-identity --query 'Account' --output text)
    local user_arn=$(aws sts get-caller-identity --query 'Arn' --output text)
    log_success "AWS credentials configured"
    log_info "Account ID: $account_id"
    log_info "User/Role: $user_arn"
}

# Function to display warning and get confirmation
confirm_deletion() {
    echo ""
    echo "=============================================================================="
    echo -e "${RED}                    ⚠️  DANGER ZONE ⚠️${NC}"
    echo "=============================================================================="
    echo ""
    echo "You are about to DELETE the following AWS resources in region: $AWS_REGION"
    echo ""
    echo "  1. Cognito User Pool: $COGNITO_USER_POOL_ID"
    echo "     - This will delete ALL users in the pool"
    echo "     - This will delete ALL app clients"
    echo "     - Users will NO LONGER be able to authenticate"
    echo ""
    echo "  2. Cognito Identity Pool: $COGNITO_IDENTITY_POOL_ID"
    echo "     - This will revoke all temporary AWS credentials"
    echo ""
    echo "  3. Secrets Manager Secret: $SECRETS_MANAGER_SECRET_NAME"
    echo "     - This will delete FileMaker credentials"
    echo "     - Secret will be scheduled for deletion (default 7-day recovery period)"
    echo ""
    echo "=============================================================================="
    echo -e "${RED}THIS ACTION IS IRREVERSIBLE!${NC}"
    echo "=============================================================================="
    echo ""

    read -p "Type 'DELETE-TAG2-AWS' to confirm deletion: " confirmation

    if [ "$confirmation" != "DELETE-TAG2-AWS" ]; then
        log_warning "Deletion cancelled. No resources were modified."
        exit 0
    fi

    echo ""
    read -p "Are you ABSOLUTELY sure? (yes/no): " final_confirmation

    if [ "$final_confirmation" != "yes" ]; then
        log_warning "Deletion cancelled. No resources were modified."
        exit 0
    fi
}

# Function to delete Cognito User Pool
delete_cognito_user_pool() {
    log_info "Deleting Cognito User Pool: $COGNITO_USER_POOL_ID"

    # First, check if the user pool exists
    if aws cognito-idp describe-user-pool \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --region "$AWS_REGION" &> /dev/null; then

        # Delete any domain associated with the user pool (if exists)
        log_info "Checking for custom domain..."
        local domain=$(aws cognito-idp describe-user-pool \
            --user-pool-id "$COGNITO_USER_POOL_ID" \
            --region "$AWS_REGION" \
            --query 'UserPool.Domain' \
            --output text 2>/dev/null)

        if [ "$domain" != "None" ] && [ -n "$domain" ]; then
            log_info "Deleting user pool domain: $domain"
            aws cognito-idp delete-user-pool-domain \
                --domain "$domain" \
                --user-pool-id "$COGNITO_USER_POOL_ID" \
                --region "$AWS_REGION" || log_warning "Could not delete domain (may not exist)"
        fi

        # Delete the user pool
        aws cognito-idp delete-user-pool \
            --user-pool-id "$COGNITO_USER_POOL_ID" \
            --region "$AWS_REGION"

        log_success "Cognito User Pool deleted successfully"
    else
        log_warning "Cognito User Pool not found or already deleted: $COGNITO_USER_POOL_ID"
    fi
}

# Function to delete Cognito Identity Pool
delete_cognito_identity_pool() {
    log_info "Deleting Cognito Identity Pool: $COGNITO_IDENTITY_POOL_ID"

    # Check if the identity pool exists
    if aws cognito-identity describe-identity-pool \
        --identity-pool-id "$COGNITO_IDENTITY_POOL_ID" \
        --region "$AWS_REGION" &> /dev/null; then

        aws cognito-identity delete-identity-pool \
            --identity-pool-id "$COGNITO_IDENTITY_POOL_ID" \
            --region "$AWS_REGION"

        log_success "Cognito Identity Pool deleted successfully"
    else
        log_warning "Cognito Identity Pool not found or already deleted: $COGNITO_IDENTITY_POOL_ID"
    fi
}

# Function to delete Secrets Manager secret
delete_secrets_manager_secret() {
    log_info "Deleting Secrets Manager Secret: $SECRETS_MANAGER_SECRET_NAME"

    # Check if the secret exists
    if aws secretsmanager describe-secret \
        --secret-id "$SECRETS_MANAGER_SECRET_NAME" \
        --region "$AWS_REGION" &> /dev/null; then

        # Option 1: Schedule deletion with recovery window (safer - default 7 days)
        # aws secretsmanager delete-secret \
        #     --secret-id "$SECRETS_MANAGER_SECRET_NAME" \
        #     --region "$AWS_REGION"

        # Option 2: Force immediate deletion (no recovery possible)
        aws secretsmanager delete-secret \
            --secret-id "$SECRETS_MANAGER_SECRET_NAME" \
            --force-delete-without-recovery \
            --region "$AWS_REGION"

        log_success "Secrets Manager Secret deleted successfully (immediate deletion)"
    else
        log_warning "Secrets Manager Secret not found or already deleted: $SECRETS_MANAGER_SECRET_NAME"
    fi
}

# Function to delete IAM roles associated with Cognito Identity Pool (optional)
delete_cognito_iam_roles() {
    log_info "Checking for Cognito Identity Pool IAM roles..."

    # Common naming pattern for Cognito Identity Pool roles
    local auth_role="Cognito_TAG2Auth_Role"
    local unauth_role="Cognito_TAG2Unauth_Role"

    # These are placeholder names - actual role names depend on how they were created
    # You may need to update these based on your actual IAM role names

    log_warning "IAM roles may need to be deleted manually."
    log_info "Check for roles with names containing 'TAG2' or 'Cognito' in IAM console."
    echo ""
    echo "  Common role patterns to look for:"
    echo "    - Cognito_TAG2*"
    echo "    - TAG2-CognitoAuthorizedRole"
    echo "    - TAG2-CognitoUnauthorizedRole"
    echo ""
    echo "  To list Cognito-related roles, run:"
    echo "    aws iam list-roles --query \"Roles[?contains(RoleName, 'Cognito') || contains(RoleName, 'TAG2')].RoleName\""
}

# Main execution
main() {
    echo ""
    echo "=============================================================================="
    echo "           TAG2 AWS Resources Deletion Script"
    echo "=============================================================================="
    echo ""

    # Pre-flight checks
    log_info "Running pre-flight checks..."
    check_aws_cli
    check_aws_credentials

    echo ""
    log_info "Target AWS Region: $AWS_REGION"
    echo ""

    # Confirm deletion
    confirm_deletion

    echo ""
    log_info "Starting deletion process..."
    echo ""

    # Delete resources in order (dependent resources first)
    # 1. Delete Secrets Manager secret first (depends on Identity Pool for access)
    delete_secrets_manager_secret
    echo ""

    # 2. Delete Cognito Identity Pool (depends on User Pool for federation)
    delete_cognito_identity_pool
    echo ""

    # 3. Delete Cognito User Pool last (core authentication resource)
    delete_cognito_user_pool
    echo ""

    # 4. Note about IAM roles
    delete_cognito_iam_roles

    echo ""
    echo "=============================================================================="
    log_success "TAG2 AWS resource deletion completed!"
    echo "=============================================================================="
    echo ""
    log_warning "Remember to:"
    echo "  1. Check IAM roles and policies that may have been created for Cognito"
    echo "  2. Update any environment configurations that reference these resources"
    echo "  3. Remove AWS credentials from the iOS app keychain on test devices"
    echo "  4. Update CI/CD pipelines if they reference these resources"
    echo ""
}

# Run main function
main "$@"
