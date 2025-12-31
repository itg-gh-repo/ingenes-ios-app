#!/bin/bash

#===============================================================================
# TAG2 Cognito User Creation Script
#===============================================================================
# This script creates new users in the TAG2 Cognito User Pool.
# Users are created with a temporary password and will be required to
# change their password on first login.
#
# Usage:
#   ./create-cognito-user.sh <email> [firstName] [lastName] [storeName] [customerId]
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - Appropriate IAM permissions to create Cognito users
#===============================================================================

set -e  # Exit on any error

# Configuration - TAG2 AWS Resource Identifiers
AWS_REGION="us-east-1"
COGNITO_USER_POOL_ID="us-east-1_93HMCJqvJ"
TEMPORARY_PASSWORD="TempPassword123!@"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Function to display usage
show_usage() {
    echo ""
    echo -e "${CYAN}TAG2 Cognito User Creation Script${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 <email> [firstName] [lastName] [storeName] [customerId]"
    echo ""
    echo "Arguments:"
    echo "  email       (required) User's email address (used as username)"
    echo "  firstName   (optional) User's first name"
    echo "  lastName    (optional) User's last name"
    echo "  storeName   (optional) Associated store name"
    echo "  customerId  (optional) Customer identifier"
    echo ""
    echo "Examples:"
    echo "  $0 user@example.com"
    echo "  $0 user@example.com John Doe"
    echo "  $0 user@example.com John Doe \"My Store\" CUST001"
    echo ""
    echo "Notes:"
    echo "  - Temporary password: $TEMPORARY_PASSWORD"
    echo "  - User will be required to change password on first login"
    echo "  - Email will be automatically marked as verified"
    echo ""
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        echo "  Installation: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured or are invalid."
        echo "  Run 'aws configure' to set up your credentials."
        exit 1
    fi
}

# Function to validate email format
validate_email() {
    local email=$1
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email format: $email"
        exit 1
    fi
}

# Function to check if user already exists
check_user_exists() {
    local email=$1
    if aws cognito-idp admin-get-user \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --username "$email" \
        --region "$AWS_REGION" &> /dev/null; then
        return 0  # User exists
    else
        return 1  # User does not exist
    fi
}

# Function to create user
create_user() {
    local email=$1
    local first_name=$2
    local last_name=$3
    local store_name=$4
    local customer_id=$5

    log_info "Creating user: $email"

    # Build user attributes array
    local attributes="Name=email,Value=$email Name=email_verified,Value=true"

    if [ -n "$first_name" ]; then
        attributes="$attributes Name=custom:firstName,Value=$first_name"
    fi

    if [ -n "$last_name" ]; then
        attributes="$attributes Name=custom:lastName,Value=$last_name"
    fi

    if [ -n "$store_name" ]; then
        attributes="$attributes Name=custom:storeName,Value=$store_name"
    fi

    if [ -n "$customer_id" ]; then
        attributes="$attributes Name=custom:customerId,Value=$customer_id"
    fi

    # Create the user
    aws cognito-idp admin-create-user \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --username "$email" \
        --temporary-password "$TEMPORARY_PASSWORD" \
        --user-attributes $attributes \
        --message-action SUPPRESS \
        --region "$AWS_REGION"

    if [ $? -eq 0 ]; then
        log_success "User created successfully!"
        echo ""
        echo -e "${CYAN}User Details:${NC}"
        echo "  Email:              $email"
        echo "  Temporary Password: $TEMPORARY_PASSWORD"
        [ -n "$first_name" ] && echo "  First Name:         $first_name"
        [ -n "$last_name" ] && echo "  Last Name:          $last_name"
        [ -n "$store_name" ] && echo "  Store Name:         $store_name"
        [ -n "$customer_id" ] && echo "  Customer ID:        $customer_id"
        echo ""
        log_warning "User must change password on first login."
    else
        log_error "Failed to create user"
        exit 1
    fi
}

# Main execution
main() {
    # Check for help flag
    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        show_usage
        exit 0
    fi

    # Check if email is provided
    if [ -z "$1" ]; then
        log_error "Email is required"
        show_usage
        exit 1
    fi

    local email=$1
    local first_name=$2
    local last_name=$3
    local store_name=$4
    local customer_id=$5

    echo ""
    echo "=============================================================================="
    echo "           TAG2 Cognito User Creation"
    echo "=============================================================================="
    echo ""

    # Pre-flight checks
    log_info "Running pre-flight checks..."
    check_aws_cli
    check_aws_credentials
    validate_email "$email"

    log_success "All checks passed"
    echo ""

    # Check if user already exists
    if check_user_exists "$email"; then
        log_error "User already exists: $email"
        echo ""
        echo "To delete and recreate the user, run:"
        echo "  aws cognito-idp admin-delete-user --user-pool-id $COGNITO_USER_POOL_ID --username \"$email\" --region $AWS_REGION"
        exit 1
    fi

    # Create the user
    create_user "$email" "$first_name" "$last_name" "$store_name" "$customer_id"

    echo "=============================================================================="
    echo ""
}

# Run main function
main "$@"
