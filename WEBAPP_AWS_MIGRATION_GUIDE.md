# AWS Cognito & Secrets Manager - Webapp Implementation Guide

> **Source Reference:** Based on Ingenes iOS App implementation
> **Target:** Web Application (React/Next.js recommended)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Project Setup](#3-project-setup)
4. [AWS Configuration](#4-aws-configuration)
5. [Authentication Service](#5-authentication-service)
6. [AWS Credentials Service](#6-aws-credentials-service)
7. [Secrets Manager Service](#7-secrets-manager-service)
8. [Token Storage](#8-token-storage)
9. [FileMaker Service (User Validation)](#9-filemaker-service-user-validation)
10. [Auth State Management](#10-auth-state-management)
11. [UI Components](#11-ui-components)
12. [Password Reset Flow](#12-password-reset-flow)
13. [Security Best Practices](#13-security-best-practices)
14. [Testing](#14-testing)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Overview

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        WEB APPLICATION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │   React     │    │   Auth      │    │   AWS Services      │ │
│  │   Context   │◄──►│   Service   │◄──►│   Integration       │ │
│  │   (State)   │    │             │    │                     │ │
│  └─────────────┘    └─────────────┘    └─────────────────────┘ │
│                            │                     │              │
│                            ▼                     ▼              │
│                    ┌─────────────┐       ┌─────────────┐       │
│                    │   Token     │       │   Secrets   │       │
│                    │   Storage   │       │   Service   │       │
│                    │(localStorage)│       │             │       │
│                    └─────────────┘       └─────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         AWS CLOUD                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Cognito        │  │  Cognito        │  │  Secrets        │ │
│  │  User Pool      │  │  Identity Pool  │  │  Manager        │ │
│  │                 │  │                 │  │                 │ │
│  │  - Auth         │  │  - AWS Creds    │  │  - FileMaker    │ │
│  │  - Users        │  │  - IAM Roles    │  │    Credentials  │ │
│  │  - Tokens       │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Your AWS Configuration (From iOS App)

| Resource | Value |
|----------|-------|
| **Region** | `us-east-1` |
| **User Pool ID** | `us-east-1_93HMCJqvJ` |
| **Client ID** | `6s98m6r64ql20ab09phvj2of2n` |
| **Client Secret** | *(empty - no secret required)* |
| **Identity Pool ID** | `us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd` |
| **Secrets Manager Secret Name** | `Ingenes/FileMaker/Credentials` |

### FileMaker API Configuration (Retrieved from Secrets Manager)

The FileMaker credentials are stored in AWS Secrets Manager and retrieved at runtime:

```json
{
  "baseUrl": "https://your-filemaker-server.com/fmi/data/v1/databases/YOUR_DATABASE",
  "username": "api_username",
  "password": "api_password"
}
```

### Complete Authentication Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        COMPLETE AUTHENTICATION FLOW                          │
└─────────────────────────────────────────────────────────────────────────────┘

Step 1: User enters email/password
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  AWS COGNITO AUTHENTICATION                                                  │
│  cognitoService.signIn(email, password)                                     │
│  → Validates credentials against User Pool                                   │
│  → Returns: ID Token, Access Token, Refresh Token                           │
│  → Extracts user attributes from ID Token (custom:customerId, etc.)         │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  AWS CREDENTIALS (via Cognito Identity Pool)                                │
│  awsCredentialsService.getCredentials()                                     │
│  → Exchanges ID Token for temporary AWS credentials                         │
│  → Returns: AccessKeyId, SecretAccessKey, SessionToken                      │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  AWS SECRETS MANAGER                                                         │
│  secretsManagerService.getFileMakerCredentials()                            │
│  → Uses temporary AWS credentials to fetch secret                           │
│  → Returns: FileMaker baseUrl, username, password                           │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  FILEMAKER API - GET SESSION TOKEN                                          │
│  fileMakerService.getToken()                                                │
│  → POST {baseUrl}/sessions with Basic Auth                                  │
│  → Returns: FileMaker session token (10-min expiry)                         │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  FILEMAKER API - VALIDATE USER                                              │
│  fileMakerService.validateUser(email, companyId)                            │
│  → POST {baseUrl}/layouts/@Usuarios/_find                                   │
│  → Query: {"Email": "==user@email.com"}                                     │
│  → Returns: User data from FileMaker database                               │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  USER AUTHENTICATED & VALIDATED                                              │
│  → Store Cognito tokens                                                      │
│  → Store FileMaker token                                                     │
│  → Update app state with user data                                           │
│  → Redirect to dashboard                                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Prerequisites

### Required Packages

```bash
# Core AWS SDK v3 packages
npm install @aws-sdk/client-cognito-identity-provider
npm install @aws-sdk/client-cognito-identity
npm install @aws-sdk/client-secrets-manager

# For token handling
npm install jwt-decode

# Optional: For React apps
npm install @tanstack/react-query  # For caching/state
```

### Package.json Dependencies

```json
{
  "dependencies": {
    "@aws-sdk/client-cognito-identity": "^3.x.x",
    "@aws-sdk/client-cognito-identity-provider": "^3.x.x",
    "@aws-sdk/client-secrets-manager": "^3.x.x",
    "jwt-decode": "^4.x.x"
  }
}
```

---

## 3. Project Setup

### 3.1 Environment Variables

Create `.env.local` (for Next.js) or `.env` file:

```env
# AWS Cognito Configuration
NEXT_PUBLIC_AWS_REGION=us-east-1
NEXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_93HMCJqvJ
NEXT_PUBLIC_COGNITO_CLIENT_ID=6s98m6r64ql20ab09phvj2of2n
NEXT_PUBLIC_COGNITO_IDENTITY_POOL_ID=us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd

# If your app client has a secret (check AWS Console)
# IMPORTANT: Client secret should NOT be in frontend code for production
# Only use this for testing or server-side rendering
COGNITO_CLIENT_SECRET=

# Secrets Manager
NEXT_PUBLIC_FILEMAKER_SECRET_NAME=Ingenes/FileMaker/Credentials
```

### 3.2 TypeScript Types

Create `src/types/aws.ts`:

```typescript
// ===== AWS COGNITO TYPES =====

export interface CognitoTokens {
  idToken: string;
  accessToken: string;
  refreshToken: string;
  expiresAt: number; // Unix timestamp
}

export interface CognitoUserAttributes {
  email: string;
  firstName: string;
  lastName: string;
  storeName: string;
  customerId: string;      // Company ID for multi-tenant
  locationStatus: string;
  recordId: string;
}

export interface IdTokenPayload {
  sub: string;
  email: string;
  'custom:firstName'?: string;
  'custom:lastName'?: string;
  'custom:storeName'?: string;
  'custom:customerId'?: string;
  'custom:locationStatus'?: string;
  'custom:recordId'?: string;
  given_name?: string;
  family_name?: string;
  exp: number;
  iat: number;
  auth_time: number;
}

// ===== AWS CREDENTIALS TYPES =====

export interface AWSCredentials {
  accessKeyId: string;
  secretAccessKey: string;
  sessionToken: string;
  expiration: Date;
}

// ===== SECRETS MANAGER TYPES =====

export interface FileMakerCredentials {
  baseUrl: string;
  username: string;
  password: string;
}

// ===== ERROR TYPES =====

export type CognitoErrorCode =
  | 'NotAuthorizedException'
  | 'UserNotFoundException'
  | 'UserNotConfirmedException'
  | 'PasswordResetRequiredException'
  | 'TooManyRequestsException'
  | 'CodeMismatchException'
  | 'ExpiredCodeException'
  | 'InvalidPasswordException'
  | 'InvalidParameterException'
  | 'LimitExceededException';

export class AuthError extends Error {
  constructor(
    message: string,
    public code: CognitoErrorCode | string,
    public originalError?: Error
  ) {
    super(message);
    this.name = 'AuthError';
  }
}
```

### 3.3 Configuration File

Create `src/config/aws.ts`:

```typescript
export const awsConfig = {
  region: process.env.NEXT_PUBLIC_AWS_REGION || 'us-east-1',

  cognito: {
    userPoolId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID || '',
    clientId: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID || '',
    clientSecret: process.env.COGNITO_CLIENT_SECRET || '', // Optional
    identityPoolId: process.env.NEXT_PUBLIC_COGNITO_IDENTITY_POOL_ID || '',
  },

  secretsManager: {
    fileMakerSecretName: process.env.NEXT_PUBLIC_FILEMAKER_SECRET_NAME || 'Ingenes/FileMaker/Credentials',
    cacheDuration: 3600000, // 1 hour in milliseconds
  },

  // Derived values
  get cognitoIssuer() {
    return `cognito-idp.${this.region}.amazonaws.com/${this.cognito.userPoolId}`;
  },
} as const;

// Validation
export function validateConfig(): void {
  const required = [
    ['User Pool ID', awsConfig.cognito.userPoolId],
    ['Client ID', awsConfig.cognito.clientId],
    ['Identity Pool ID', awsConfig.cognito.identityPoolId],
  ];

  const missing = required.filter(([_, value]) => !value);

  if (missing.length > 0) {
    throw new Error(
      `Missing AWS configuration: ${missing.map(([name]) => name).join(', ')}`
    );
  }
}
```

---

## 4. AWS Configuration

### 4.1 AWS Cognito Console Setup

> **Note:** Your iOS app already has this configured. This section is for reference.

#### User Pool Settings Checklist

- [ ] User Pool ID: `us-east-1_93HMCJqvJ`
- [ ] App Client ID: `6s98m6r64ql20ab09phvj2of2n`
- [ ] Auth Flow: `ALLOW_USER_PASSWORD_AUTH` enabled
- [ ] Refresh Token Rotation: Check settings

#### Custom Attributes (Already Configured)

Your User Pool should have these custom attributes:

| Attribute | Type | Mutable |
|-----------|------|---------|
| `custom:firstName` | String | Yes |
| `custom:lastName` | String | Yes |
| `custom:storeName` | String | Yes |
| `custom:customerId` | String | Yes |
| `custom:locationStatus` | String | Yes |
| `custom:recordId` | String | Yes |

### 4.2 Identity Pool Configuration

> **Your Identity Pool ID:** `us-east-1:c9967d40-795e-4682-a4f4-67ab4286c7dd`

#### Authenticated Role IAM Policy

The authenticated role should have this policy for Secrets Manager access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:*:secret:Ingenes/FileMaker/Credentials*"
      ]
    }
  ]
}
```

### 4.3 CORS Configuration for Web

**IMPORTANT:** For web apps, you may need to add your domain to the Cognito User Pool app client's callback URLs.

In AWS Console:
1. Go to Cognito → User Pools → Your Pool → App Integration
2. Add your webapp domain to "Allowed callback URLs"
3. Add CORS origins if using hosted UI

---

## 5. Authentication Service

Create `src/services/cognitoService.ts`:

```typescript
import {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
  InitiateAuthCommandInput,
  ForgotPasswordCommand,
  ConfirmForgotPasswordCommand,
  GlobalSignOutCommand,
  AuthFlowType,
} from '@aws-sdk/client-cognito-identity-provider';
import { jwtDecode } from 'jwt-decode';
import crypto from 'crypto';

import { awsConfig } from '@/config/aws';
import {
  CognitoTokens,
  CognitoUserAttributes,
  IdTokenPayload,
  AuthError,
} from '@/types/aws';
import { tokenStorage } from './tokenStorage';

// ===== COGNITO CLIENT =====

const cognitoClient = new CognitoIdentityProviderClient({
  region: awsConfig.region,
});

// ===== SECRET HASH CALCULATION =====
// Required if your app client has a client secret

function calculateSecretHash(username: string): string | undefined {
  const clientSecret = awsConfig.cognito.clientSecret;
  if (!clientSecret) return undefined;

  const message = username + awsConfig.cognito.clientId;

  // Browser-compatible HMAC-SHA256
  // Note: In browser, use SubtleCrypto instead
  const hmac = crypto.createHmac('sha256', clientSecret);
  hmac.update(message);
  return hmac.digest('base64');
}

// Browser-compatible version using SubtleCrypto
async function calculateSecretHashBrowser(username: string): Promise<string | undefined> {
  const clientSecret = awsConfig.cognito.clientSecret;
  if (!clientSecret) return undefined;

  const message = username + awsConfig.cognito.clientId;
  const encoder = new TextEncoder();

  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(clientSecret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(message)
  );

  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

// ===== COGNITO SERVICE =====

export const cognitoService = {
  // ===== SIGN IN =====
  async signIn(username: string, password: string): Promise<CognitoUserAttributes> {
    try {
      const secretHash = await calculateSecretHashBrowser(username);

      const authParams: Record<string, string> = {
        USERNAME: username,
        PASSWORD: password,
      };

      if (secretHash) {
        authParams.SECRET_HASH = secretHash;
      }

      const input: InitiateAuthCommandInput = {
        AuthFlow: AuthFlowType.USER_PASSWORD_AUTH,
        ClientId: awsConfig.cognito.clientId,
        AuthParameters: authParams,
      };

      const command = new InitiateAuthCommand(input);
      const response = await cognitoClient.send(command);

      // Handle challenges (e.g., NEW_PASSWORD_REQUIRED)
      if (response.ChallengeName) {
        if (response.ChallengeName === 'NEW_PASSWORD_REQUIRED') {
          throw new AuthError(
            'Password change required',
            'NEW_PASSWORD_REQUIRED'
          );
        }
        throw new AuthError(
          `Authentication challenge: ${response.ChallengeName}`,
          response.ChallengeName
        );
      }

      // Extract tokens
      const authResult = response.AuthenticationResult;
      if (!authResult?.IdToken || !authResult?.AccessToken || !authResult?.RefreshToken) {
        throw new AuthError('Invalid authentication response', 'InvalidResponse');
      }

      // Calculate expiry
      const expiresIn = authResult.ExpiresIn || 3600;
      const expiresAt = Date.now() + expiresIn * 1000;

      // Store tokens
      const tokens: CognitoTokens = {
        idToken: authResult.IdToken,
        accessToken: authResult.AccessToken,
        refreshToken: authResult.RefreshToken,
        expiresAt,
      };
      tokenStorage.setTokens(tokens);

      // Parse user attributes from ID token
      const userAttributes = this.parseIdToken(authResult.IdToken);

      return userAttributes;

    } catch (error: any) {
      // Map Cognito errors to user-friendly messages
      const errorCode = error.name || error.__type || 'UnknownError';

      const errorMessages: Record<string, string> = {
        NotAuthorizedException: 'Invalid email or password',
        UserNotFoundException: 'User not found',
        UserNotConfirmedException: 'Please verify your email address',
        PasswordResetRequiredException: 'Password reset required',
        TooManyRequestsException: 'Too many attempts. Please try again later',
        InvalidParameterException: 'Invalid input provided',
      };

      throw new AuthError(
        errorMessages[errorCode] || error.message || 'Authentication failed',
        errorCode,
        error
      );
    }
  },

  // ===== SIGN OUT =====
  async signOut(): Promise<void> {
    try {
      const accessToken = tokenStorage.getAccessToken();

      if (accessToken) {
        // Invalidate all sessions server-side
        const command = new GlobalSignOutCommand({
          AccessToken: accessToken,
        });

        try {
          await cognitoClient.send(command);
        } catch {
          // Continue with local sign out even if server call fails
          console.warn('GlobalSignOut failed, proceeding with local sign out');
        }
      }
    } finally {
      // Always clear local tokens
      tokenStorage.clearTokens();
    }
  },

  // ===== REFRESH TOKENS =====
  async refreshTokens(): Promise<boolean> {
    try {
      const refreshToken = tokenStorage.getRefreshToken();
      if (!refreshToken) {
        return false;
      }

      // Note: For REFRESH_TOKEN_AUTH, username is in the refresh token
      // Some setups may need the username from stored user data
      const secretHash = awsConfig.cognito.clientSecret
        ? await calculateSecretHashBrowser(tokenStorage.getUsername() || '')
        : undefined;

      const authParams: Record<string, string> = {
        REFRESH_TOKEN: refreshToken,
      };

      if (secretHash) {
        authParams.SECRET_HASH = secretHash;
      }

      const command = new InitiateAuthCommand({
        AuthFlow: AuthFlowType.REFRESH_TOKEN_AUTH,
        ClientId: awsConfig.cognito.clientId,
        AuthParameters: authParams,
      });

      const response = await cognitoClient.send(command);
      const authResult = response.AuthenticationResult;

      if (!authResult?.IdToken || !authResult?.AccessToken) {
        return false;
      }

      // Update stored tokens (refresh token may or may not be returned)
      const expiresIn = authResult.ExpiresIn || 3600;
      const tokens: CognitoTokens = {
        idToken: authResult.IdToken,
        accessToken: authResult.AccessToken,
        refreshToken: authResult.RefreshToken || refreshToken,
        expiresAt: Date.now() + expiresIn * 1000,
      };
      tokenStorage.setTokens(tokens);

      return true;

    } catch (error) {
      console.error('Token refresh failed:', error);
      return false;
    }
  },

  // ===== FORGOT PASSWORD =====
  async forgotPassword(username: string): Promise<void> {
    try {
      const secretHash = await calculateSecretHashBrowser(username);

      const command = new ForgotPasswordCommand({
        ClientId: awsConfig.cognito.clientId,
        Username: username,
        SecretHash: secretHash,
      });

      await cognitoClient.send(command);

    } catch (error: any) {
      const errorCode = error.name || 'UnknownError';

      const errorMessages: Record<string, string> = {
        UserNotFoundException: 'No account found with this email',
        LimitExceededException: 'Too many attempts. Please try again later',
        InvalidParameterException: 'Invalid email format',
      };

      throw new AuthError(
        errorMessages[errorCode] || 'Failed to send reset code',
        errorCode,
        error
      );
    }
  },

  // ===== CONFIRM FORGOT PASSWORD =====
  async confirmForgotPassword(
    username: string,
    code: string,
    newPassword: string
  ): Promise<void> {
    try {
      const secretHash = await calculateSecretHashBrowser(username);

      const command = new ConfirmForgotPasswordCommand({
        ClientId: awsConfig.cognito.clientId,
        Username: username,
        ConfirmationCode: code,
        Password: newPassword,
        SecretHash: secretHash,
      });

      await cognitoClient.send(command);

    } catch (error: any) {
      const errorCode = error.name || 'UnknownError';

      const errorMessages: Record<string, string> = {
        CodeMismatchException: 'Invalid verification code',
        ExpiredCodeException: 'Verification code has expired',
        InvalidPasswordException: 'Password does not meet requirements',
        LimitExceededException: 'Too many attempts. Please try again later',
      };

      throw new AuthError(
        errorMessages[errorCode] || 'Failed to reset password',
        errorCode,
        error
      );
    }
  },

  // ===== CHECK AUTHENTICATION =====
  isAuthenticated(): boolean {
    const tokens = tokenStorage.getTokens();
    if (!tokens) return false;

    // Check if token is expired (with 5 minute buffer)
    const bufferMs = 5 * 60 * 1000;
    return tokens.expiresAt > Date.now() + bufferMs;
  },

  // ===== AUTO REFRESH IF NEEDED =====
  async ensureValidToken(): Promise<string | null> {
    const tokens = tokenStorage.getTokens();
    if (!tokens) return null;

    // Check if token needs refresh (within 5 minutes of expiry)
    const bufferMs = 5 * 60 * 1000;
    if (tokens.expiresAt < Date.now() + bufferMs) {
      const refreshed = await this.refreshTokens();
      if (!refreshed) return null;
    }

    return tokenStorage.getAccessToken();
  },

  // ===== PARSE ID TOKEN =====
  parseIdToken(idToken: string): CognitoUserAttributes {
    try {
      const decoded = jwtDecode<IdTokenPayload>(idToken);

      return {
        email: decoded.email || '',
        firstName: decoded['custom:firstName'] || decoded.given_name || '',
        lastName: decoded['custom:lastName'] || decoded.family_name || '',
        storeName: decoded['custom:storeName'] || '',
        customerId: decoded['custom:customerId'] || '',
        locationStatus: decoded['custom:locationStatus'] || 'Active',
        recordId: decoded['custom:recordId'] || decoded.sub,
      };

    } catch (error) {
      console.error('Failed to parse ID token:', error);
      throw new AuthError('Invalid token format', 'InvalidToken');
    }
  },

  // ===== GET CURRENT USER =====
  getCurrentUser(): CognitoUserAttributes | null {
    const idToken = tokenStorage.getIdToken();
    if (!idToken) return null;

    try {
      return this.parseIdToken(idToken);
    } catch {
      return null;
    }
  },

  // ===== GET ACCESS TOKEN (for API calls) =====
  getAccessToken(): string | null {
    return tokenStorage.getAccessToken();
  },

  // ===== GET ID TOKEN (for AWS credentials) =====
  getIdToken(): string | null {
    return tokenStorage.getIdToken();
  },
};

export default cognitoService;
```

---

## 6. AWS Credentials Service

Create `src/services/awsCredentialsService.ts`:

```typescript
import {
  CognitoIdentityClient,
  GetIdCommand,
  GetCredentialsForIdentityCommand,
} from '@aws-sdk/client-cognito-identity';

import { awsConfig } from '@/config/aws';
import { AWSCredentials, AuthError } from '@/types/aws';
import { cognitoService } from './cognitoService';

// ===== COGNITO IDENTITY CLIENT =====

const identityClient = new CognitoIdentityClient({
  region: awsConfig.region,
});

// ===== CREDENTIALS CACHE =====

let cachedCredentials: AWSCredentials | null = null;
let cachedIdentityId: string | null = null;

// ===== AWS CREDENTIALS SERVICE =====

export const awsCredentialsService = {
  // ===== GET AWS CREDENTIALS =====
  async getCredentials(): Promise<AWSCredentials> {
    // Check if cached credentials are still valid
    if (cachedCredentials && !this.isExpiringSoon(cachedCredentials)) {
      return cachedCredentials;
    }

    // Get ID token from Cognito auth
    const idToken = cognitoService.getIdToken();
    if (!idToken) {
      throw new AuthError('Not authenticated', 'NotAuthenticated');
    }

    // Step 1: Get Identity ID
    const identityId = await this.getIdentityId(idToken);

    // Step 2: Get AWS Credentials for Identity
    const credentials = await this.getCredentialsForIdentity(identityId, idToken);

    // Cache the credentials
    cachedCredentials = credentials;
    cachedIdentityId = identityId;

    return credentials;
  },

  // ===== GET IDENTITY ID =====
  private async getIdentityId(idToken: string): Promise<string> {
    // Use cached identity if available
    if (cachedIdentityId) {
      return cachedIdentityId;
    }

    try {
      const logins: Record<string, string> = {
        [awsConfig.cognitoIssuer]: idToken,
      };

      const command = new GetIdCommand({
        IdentityPoolId: awsConfig.cognito.identityPoolId,
        Logins: logins,
      });

      const response = await identityClient.send(command);

      if (!response.IdentityId) {
        throw new Error('No identity ID returned');
      }

      return response.IdentityId;

    } catch (error: any) {
      throw new AuthError(
        'Failed to get AWS identity',
        error.name || 'IdentityError',
        error
      );
    }
  },

  // ===== GET CREDENTIALS FOR IDENTITY =====
  private async getCredentialsForIdentity(
    identityId: string,
    idToken: string
  ): Promise<AWSCredentials> {
    try {
      const logins: Record<string, string> = {
        [awsConfig.cognitoIssuer]: idToken,
      };

      const command = new GetCredentialsForIdentityCommand({
        IdentityId: identityId,
        Logins: logins,
      });

      const response = await identityClient.send(command);
      const creds = response.Credentials;

      if (!creds?.AccessKeyId || !creds?.SecretKey || !creds?.SessionToken) {
        throw new Error('Invalid credentials response');
      }

      return {
        accessKeyId: creds.AccessKeyId,
        secretAccessKey: creds.SecretKey,
        sessionToken: creds.SessionToken,
        expiration: creds.Expiration || new Date(Date.now() + 3600000),
      };

    } catch (error: any) {
      throw new AuthError(
        'Failed to get AWS credentials',
        error.name || 'CredentialsError',
        error
      );
    }
  },

  // ===== CHECK IF EXPIRING SOON =====
  isExpiringSoon(credentials: AWSCredentials): boolean {
    // Consider expired if within 5 minutes
    const bufferMs = 5 * 60 * 1000;
    return credentials.expiration.getTime() < Date.now() + bufferMs;
  },

  // ===== CLEAR CACHED CREDENTIALS =====
  clearCredentials(): void {
    cachedCredentials = null;
    cachedIdentityId = null;
  },
};

export default awsCredentialsService;
```

---

## 7. Secrets Manager Service

Create `src/services/secretsManagerService.ts`:

```typescript
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from '@aws-sdk/client-secrets-manager';

import { awsConfig } from '@/config/aws';
import { FileMakerCredentials, AuthError } from '@/types/aws';
import { awsCredentialsService } from './awsCredentialsService';

// ===== CACHE =====

let cachedCredentials: FileMakerCredentials | null = null;
let cacheExpiry: number | null = null;

// ===== SECRETS MANAGER SERVICE =====

export const secretsManagerService = {
  // ===== GET FILEMAKER CREDENTIALS =====
  async getFileMakerCredentials(): Promise<FileMakerCredentials> {
    // Check cache first
    if (cachedCredentials && cacheExpiry && Date.now() < cacheExpiry) {
      return cachedCredentials;
    }

    try {
      // Get AWS credentials via Cognito Identity
      const awsCreds = await awsCredentialsService.getCredentials();

      // Create Secrets Manager client with temporary credentials
      const secretsClient = new SecretsManagerClient({
        region: awsConfig.region,
        credentials: {
          accessKeyId: awsCreds.accessKeyId,
          secretAccessKey: awsCreds.secretAccessKey,
          sessionToken: awsCreds.sessionToken,
        },
      });

      // Fetch the secret
      const command = new GetSecretValueCommand({
        SecretId: awsConfig.secretsManager.fileMakerSecretName,
      });

      const response = await secretsClient.send(command);

      if (!response.SecretString) {
        throw new Error('Secret value is empty');
      }

      // Parse the secret JSON
      const credentials = JSON.parse(response.SecretString) as FileMakerCredentials;

      // Validate required fields
      if (!credentials.baseUrl || !credentials.username || !credentials.password) {
        throw new Error('Invalid secret format');
      }

      // Cache for 1 hour
      cachedCredentials = credentials;
      cacheExpiry = Date.now() + awsConfig.secretsManager.cacheDuration;

      return credentials;

    } catch (error: any) {
      // Clear cache on error
      this.clearCache();

      const errorCode = error.name || 'UnknownError';

      const errorMessages: Record<string, string> = {
        ResourceNotFoundException: 'Configuration not found',
        AccessDeniedException: 'Access denied to configuration',
        InvalidRequestException: 'Invalid request',
      };

      throw new AuthError(
        errorMessages[errorCode] || 'Failed to load configuration',
        errorCode,
        error
      );
    }
  },

  // ===== GET BASE64 CREDENTIALS (for FileMaker Basic Auth) =====
  async getBase64Credentials(): Promise<string> {
    const creds = await this.getFileMakerCredentials();
    const combined = `${creds.username}:${creds.password}`;
    return btoa(combined);
  },

  // ===== CLEAR CACHE =====
  clearCache(): void {
    cachedCredentials = null;
    cacheExpiry = null;
  },
};

export default secretsManagerService;
```

---

## 8. Token Storage

Create `src/services/tokenStorage.ts`:

```typescript
import { CognitoTokens } from '@/types/aws';

// ===== STORAGE KEYS =====

const STORAGE_KEYS = {
  ID_TOKEN: 'ingenes_cognito_id_token',
  ACCESS_TOKEN: 'ingenes_cognito_access_token',
  REFRESH_TOKEN: 'ingenes_cognito_refresh_token',
  TOKEN_EXPIRY: 'ingenes_cognito_token_expiry',
  USERNAME: 'ingenes_saved_username',
  REMEMBER_USERNAME: 'ingenes_remember_username',
} as const;

// ===== TOKEN STORAGE SERVICE =====

export const tokenStorage = {
  // ===== SET ALL TOKENS =====
  setTokens(tokens: CognitoTokens): void {
    try {
      localStorage.setItem(STORAGE_KEYS.ID_TOKEN, tokens.idToken);
      localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, tokens.accessToken);
      localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, tokens.refreshToken);
      localStorage.setItem(STORAGE_KEYS.TOKEN_EXPIRY, tokens.expiresAt.toString());
    } catch (error) {
      console.error('Failed to store tokens:', error);
    }
  },

  // ===== GET ALL TOKENS =====
  getTokens(): CognitoTokens | null {
    try {
      const idToken = localStorage.getItem(STORAGE_KEYS.ID_TOKEN);
      const accessToken = localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
      const refreshToken = localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN);
      const expiresAt = localStorage.getItem(STORAGE_KEYS.TOKEN_EXPIRY);

      if (!idToken || !accessToken || !refreshToken || !expiresAt) {
        return null;
      }

      return {
        idToken,
        accessToken,
        refreshToken,
        expiresAt: parseInt(expiresAt, 10),
      };
    } catch {
      return null;
    }
  },

  // ===== GET INDIVIDUAL TOKENS =====
  getIdToken(): string | null {
    return localStorage.getItem(STORAGE_KEYS.ID_TOKEN);
  },

  getAccessToken(): string | null {
    return localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
  },

  getRefreshToken(): string | null {
    return localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN);
  },

  getTokenExpiry(): number | null {
    const expiry = localStorage.getItem(STORAGE_KEYS.TOKEN_EXPIRY);
    return expiry ? parseInt(expiry, 10) : null;
  },

  // ===== CLEAR ALL TOKENS =====
  clearTokens(): void {
    localStorage.removeItem(STORAGE_KEYS.ID_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.TOKEN_EXPIRY);
  },

  // ===== USERNAME MANAGEMENT =====
  setUsername(username: string): void {
    localStorage.setItem(STORAGE_KEYS.USERNAME, username);
  },

  getUsername(): string | null {
    return localStorage.getItem(STORAGE_KEYS.USERNAME);
  },

  clearUsername(): void {
    localStorage.removeItem(STORAGE_KEYS.USERNAME);
  },

  // ===== REMEMBER USERNAME =====
  setRememberUsername(remember: boolean): void {
    localStorage.setItem(STORAGE_KEYS.REMEMBER_USERNAME, remember.toString());
  },

  getRememberUsername(): boolean {
    return localStorage.getItem(STORAGE_KEYS.REMEMBER_USERNAME) === 'true';
  },
};

// ===== SECURE TOKEN STORAGE (Alternative using sessionStorage) =====

export const secureTokenStorage = {
  // Use sessionStorage for more security (cleared when tab closes)
  // Same API as tokenStorage but uses sessionStorage

  setTokens(tokens: CognitoTokens): void {
    sessionStorage.setItem(STORAGE_KEYS.ID_TOKEN, tokens.idToken);
    sessionStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, tokens.accessToken);
    sessionStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, tokens.refreshToken);
    sessionStorage.setItem(STORAGE_KEYS.TOKEN_EXPIRY, tokens.expiresAt.toString());
  },

  // ... same methods as above but using sessionStorage
};

export default tokenStorage;
```

---

## 9. FileMaker Service (User Validation)

After successful Cognito authentication, you must validate the user exists in FileMaker database.

### 9.1 TypeScript Types for FileMaker

Add to `src/types/filemaker.ts`:

```typescript
// ===== FILEMAKER API TYPES =====

export interface FileMakerUser {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  companyId: string;
  userType: string;
  username: string;
  phone?: string;
  recordId: string;
}

export interface FileMakerTokenResponse {
  response: {
    token: string;
  };
  messages: FileMakerMessage[];
}

export interface FileMakerMessage {
  code: string;
  message: string;
}

export interface FileMakerRecordsResponse<T> {
  response: {
    data: FileMakerRecord<T>[];
    dataInfo?: {
      database: string;
      layout: string;
      table: string;
      totalRecordCount: number;
      foundCount: number;
      returnedCount: number;
    };
  };
  messages: FileMakerMessage[];
}

export interface FileMakerRecord<T> {
  fieldData: T;
  recordId: string;
  modId?: string;
}

// Field data structure from @Usuarios layout
export interface FileMakerUserFieldData {
  id?: number;
  nombreCompleto?: string;
  Email?: string;
  idEmpresa?: string;
  idUsuario?: number;
  tipo?: string;
  usuario?: string;
  celular?: string;
  fechaRegistro?: string;
}

export interface FileMakerFindRequest {
  query: Array<Record<string, string>>;
  sort?: Array<{ fieldName: string; sortOrder: 'ascend' | 'descend' }>;
  limit?: number;
}

// ===== ERROR TYPES =====

export class FileMakerError extends Error {
  constructor(
    message: string,
    public code: string,
    public httpStatus?: number
  ) {
    super(message);
    this.name = 'FileMakerError';
  }
}
```

### 9.2 FileMaker Service Implementation

Create `src/services/fileMakerService.ts`:

```typescript
import { secretsManagerService } from './secretsManagerService';
import {
  FileMakerUser,
  FileMakerTokenResponse,
  FileMakerRecordsResponse,
  FileMakerUserFieldData,
  FileMakerFindRequest,
  FileMakerError,
} from '@/types/filemaker';

// ===== STORAGE KEYS =====

const STORAGE_KEYS = {
  FM_TOKEN: 'ingenes_filemaker_token',
  FM_TOKEN_EXPIRY: 'ingenes_filemaker_token_expiry',
} as const;

// ===== CACHE =====

let cachedToken: string | null = null;
let tokenExpiry: number | null = null;
let cachedBaseUrl: string | null = null;

// ===== FILEMAKER SERVICE =====

export const fileMakerService = {
  // ===== GET FILEMAKER SESSION TOKEN =====
  async getToken(): Promise<string> {
    // Check memory cache first
    if (cachedToken && tokenExpiry && Date.now() < tokenExpiry) {
      return cachedToken;
    }

    // Check localStorage
    const storedToken = localStorage.getItem(STORAGE_KEYS.FM_TOKEN);
    const storedExpiry = localStorage.getItem(STORAGE_KEYS.FM_TOKEN_EXPIRY);

    if (storedToken && storedExpiry) {
      const expiryTime = parseInt(storedExpiry, 10);
      if (Date.now() < expiryTime) {
        cachedToken = storedToken;
        tokenExpiry = expiryTime;
        return storedToken;
      }
    }

    // Get new token
    console.log('[FileMaker] Requesting new session token...');

    // Get credentials from Secrets Manager
    const credentials = await secretsManagerService.getFileMakerCredentials();
    cachedBaseUrl = credentials.baseUrl;

    // Create Basic Auth header
    const basicAuth = btoa(`${credentials.username}:${credentials.password}`);

    // Request session token
    const response = await fetch(`${credentials.baseUrl}/sessions`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${basicAuth}`,
        'Content-Type': 'application/json',
      },
      body: '{}',
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[FileMaker] Session creation failed:', response.status, errorText);

      // Clear cached credentials on auth failure
      secretsManagerService.clearCache();

      throw new FileMakerError(
        'Failed to authenticate with FileMaker',
        'AUTH_FAILED',
        response.status
      );
    }

    const data: FileMakerTokenResponse = await response.json();
    const newToken = data.response.token;

    // Token expires in 10 minutes (600 seconds)
    const newExpiry = Date.now() + 10 * 60 * 1000;

    // Cache in memory
    cachedToken = newToken;
    tokenExpiry = newExpiry;

    // Store in localStorage
    localStorage.setItem(STORAGE_KEYS.FM_TOKEN, newToken);
    localStorage.setItem(STORAGE_KEYS.FM_TOKEN_EXPIRY, newExpiry.toString());

    console.log('[FileMaker] Session token obtained');

    return newToken;
  },

  // ===== GET BASE URL =====
  async getBaseUrl(): Promise<string> {
    if (cachedBaseUrl) {
      return cachedBaseUrl;
    }

    const credentials = await secretsManagerService.getFileMakerCredentials();
    cachedBaseUrl = credentials.baseUrl;
    return cachedBaseUrl;
  },

  // ===== VALIDATE USER IN FILEMAKER =====
  /**
   * Validates a user exists in FileMaker after Cognito authentication
   * This is called after successful Cognito sign-in
   *
   * @param email - User's email from Cognito
   * @param companyId - Company ID from Cognito custom:customerId attribute
   * @returns User data from FileMaker
   */
  async validateUser(email: string, companyId: string): Promise<FileMakerUser> {
    console.log('[FileMaker] Validating user:', { email, companyId });

    const token = await this.getToken();
    const baseUrl = await this.getBaseUrl();

    // FileMaker _find endpoint for @Usuarios layout
    const url = `${baseUrl}/layouts/@Usuarios/_find`;

    // Build query - FileMaker exact match syntax: ==value
    const findRequest: FileMakerFindRequest = {
      query: [
        { Email: `==${email}` }
      ]
    };

    // Optionally add company filter (currently disabled for flexibility)
    // if (companyId) {
    //   findRequest.query[0].idEmpresa = `==${companyId}`;
    // }

    console.log('[FileMaker] Find request:', JSON.stringify(findRequest));

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(findRequest),
    });

    console.log('[FileMaker] Response status:', response.status);

    // Handle 401 - token expired
    if (response.status === 401) {
      this.clearToken();
      throw new FileMakerError('Session expired', 'TOKEN_EXPIRED', 401);
    }

    // Handle errors
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      console.error('[FileMaker] Error response:', errorData);

      // FileMaker returns 400 with code "401" when no records found
      if (errorData.messages?.[0]?.code === '401') {
        throw new FileMakerError(
          'User not found in database',
          'USER_NOT_FOUND',
          400
        );
      }

      throw new FileMakerError(
        'Failed to validate user',
        errorData.messages?.[0]?.code || 'UNKNOWN',
        response.status
      );
    }

    const data: FileMakerRecordsResponse<FileMakerUserFieldData> = await response.json();

    if (!data.response.data || data.response.data.length === 0) {
      throw new FileMakerError(
        'User not found in database',
        'USER_NOT_FOUND',
        404
      );
    }

    // Get first matching record
    const record = data.response.data[0];
    const fieldData = record.fieldData;

    // Parse full name into first/last
    const fullName = fieldData.nombreCompleto || '';
    const nameParts = fullName.split(' ');
    const firstName = nameParts[0] || '';
    const lastName = nameParts.slice(1).join(' ');

    const user: FileMakerUser = {
      id: fieldData.idUsuario?.toString() || record.recordId,
      firstName,
      lastName,
      email: fieldData.Email || email,
      companyId: fieldData.idEmpresa || companyId,
      userType: fieldData.tipo || 'Usuario',
      username: fieldData.usuario || '',
      phone: fieldData.celular || undefined,
      recordId: record.recordId,
    };

    console.log('[FileMaker] User validated:', user.firstName, user.lastName, user.userType);

    // Refresh token expiry on successful call
    this.refreshTokenExpiry();

    return user;
  },

  // ===== UPDATE LOGIN TIME (Optional) =====
  async updateLoginTime(recordId: string): Promise<void> {
    try {
      const token = await this.getToken();
      const baseUrl = await this.getBaseUrl();

      const url = `${baseUrl}/layouts/_webappSalesContacts/records/${recordId}`;

      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          fieldData: {
            LastLoginTime: new Date().toISOString(),
          },
        }),
      });

      if (!response.ok) {
        console.warn('[FileMaker] Failed to update login time');
      }
    } catch (error) {
      // Non-critical - don't throw
      console.warn('[FileMaker] Error updating login time:', error);
    }
  },

  // ===== REFRESH TOKEN EXPIRY =====
  refreshTokenExpiry(): void {
    const newExpiry = Date.now() + 10 * 60 * 1000; // 10 minutes
    tokenExpiry = newExpiry;
    localStorage.setItem(STORAGE_KEYS.FM_TOKEN_EXPIRY, newExpiry.toString());
  },

  // ===== CLEAR TOKEN =====
  clearToken(): void {
    cachedToken = null;
    tokenExpiry = null;
    cachedBaseUrl = null;
    localStorage.removeItem(STORAGE_KEYS.FM_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.FM_TOKEN_EXPIRY);
  },

  // ===== CHECK IF TOKEN IS VALID =====
  hasValidToken(): boolean {
    const expiry = tokenExpiry || parseInt(
      localStorage.getItem(STORAGE_KEYS.FM_TOKEN_EXPIRY) || '0',
      10
    );
    return expiry > Date.now();
  },
};

export default fileMakerService;
```

### 9.3 FileMaker API Reference

#### Session Token Endpoint

```
POST {baseUrl}/sessions

Headers:
  Authorization: Basic {base64(username:password)}
  Content-Type: application/json

Body:
  {}

Response (200):
  {
    "response": {
      "token": "abc123..."
    },
    "messages": [
      { "code": "0", "message": "OK" }
    ]
  }
```

#### Find Records Endpoint (@Usuarios)

```
POST {baseUrl}/layouts/@Usuarios/_find

Headers:
  Authorization: Bearer {fileMakerToken}
  Content-Type: application/json

Body:
  {
    "query": [
      { "Email": "==user@example.com" }
    ]
  }

Response (200):
  {
    "response": {
      "data": [
        {
          "fieldData": {
            "id": 123,
            "nombreCompleto": "John Doe",
            "Email": "user@example.com",
            "idEmpresa": "2",
            "idUsuario": 456,
            "tipo": "Administrador",
            "usuario": "jdoe",
            "celular": "5551234567",
            "fechaRegistro": "01/15/2024"
          },
          "recordId": "789",
          "modId": "1"
        }
      ],
      "dataInfo": {
        "foundCount": 1,
        "returnedCount": 1
      }
    },
    "messages": [
      { "code": "0", "message": "OK" }
    ]
  }

Error Response (400 - No records found):
  {
    "messages": [
      { "code": "401", "message": "No records match the request" }
    ]
  }
```

#### FileMaker Field Mappings (@Usuarios Layout)

| FileMaker Field | TypeScript Property | Description |
|-----------------|---------------------|-------------|
| `id` | `id` | Record ID (integer) |
| `nombreCompleto` | `firstName`, `lastName` | Full name (parsed) |
| `Email` | `email` | User email address |
| `idEmpresa` | `companyId` | Company/tenant ID |
| `idUsuario` | `id` | User ID |
| `tipo` | `userType` | User type (Administrador, Usuario) |
| `usuario` | `username` | Username |
| `celular` | `phone` | Phone number |
| `fechaRegistro` | - | Registration date |

### 9.4 FileMaker Error Codes

| Code | Meaning | Handling |
|------|---------|----------|
| `0` | Success | Continue |
| `401` | No records found | User doesn't exist in FileMaker |
| `952` | Invalid token | Call `clearToken()` and retry |
| `401` (HTTP) | Unauthorized | Token expired, get new token |
| `500` | Server error | Retry or show error |

---

## 10. Auth State Management

### 10.1 React Context (Updated with FileMaker Validation)

Create `src/context/AuthContext.tsx`:

```tsx
'use client';

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useMemo,
} from 'react';

import { cognitoService } from '@/services/cognitoService';
import { awsCredentialsService } from '@/services/awsCredentialsService';
import { secretsManagerService } from '@/services/secretsManagerService';
import { fileMakerService } from '@/services/fileMakerService';
import { tokenStorage } from '@/services/tokenStorage';
import { CognitoUserAttributes, AuthError } from '@/types/aws';
import { FileMakerUser, FileMakerError } from '@/types/filemaker';

// ===== TYPES =====

// Combined user type with both Cognito and FileMaker data
interface User extends FileMakerUser {
  cognitoAttributes: CognitoUserAttributes;
}

interface AuthState {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: User | null;
  error: string | null;
}

interface AuthContextValue extends AuthState {
  signIn: (username: string, password: string) => Promise<boolean>;
  signOut: () => Promise<void>;
  forgotPassword: (username: string) => Promise<void>;
  confirmForgotPassword: (username: string, code: string, newPassword: string) => Promise<void>;
  clearError: () => void;
}

// ===== CONTEXT =====

const AuthContext = createContext<AuthContextValue | null>(null);

// ===== PROVIDER =====

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    isAuthenticated: false,
    isLoading: true,
    user: null,
    error: null,
  });

  // ===== CHECK EXISTING AUTH ON MOUNT =====
  useEffect(() => {
    const checkAuth = async () => {
      try {
        if (cognitoService.isAuthenticated()) {
          // Try to refresh tokens to ensure still valid
          const refreshed = await cognitoService.refreshTokens();

          if (refreshed) {
            const user = cognitoService.getCurrentUser();
            setState({
              isAuthenticated: true,
              isLoading: false,
              user,
              error: null,
            });
            return;
          }
        }

        setState({
          isAuthenticated: false,
          isLoading: false,
          user: null,
          error: null,
        });
      } catch {
        setState({
          isAuthenticated: false,
          isLoading: false,
          user: null,
          error: null,
        });
      }
    };

    checkAuth();
  }, []);

  // ===== SIGN IN (with FileMaker Validation) =====
  const signIn = useCallback(async (username: string, password: string): Promise<boolean> => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      // Step 1: Authenticate with AWS Cognito
      console.log('[Auth] Step 1: Cognito authentication...');
      const cognitoAttributes = await cognitoService.signIn(username, password);
      console.log('[Auth] Cognito auth successful:', cognitoAttributes.email);

      // Step 2: Validate user exists in FileMaker database
      console.log('[Auth] Step 2: FileMaker validation...');
      let fileMakerUser: FileMakerUser;

      try {
        fileMakerUser = await fileMakerService.validateUser(
          cognitoAttributes.email,
          cognitoAttributes.customerId
        );
        console.log('[Auth] FileMaker validation successful:', fileMakerUser.firstName);
      } catch (fmError) {
        // User authenticated in Cognito but not found in FileMaker
        console.error('[Auth] FileMaker validation failed:', fmError);

        // Sign out of Cognito since FileMaker validation failed
        await cognitoService.signOut();

        if (fmError instanceof FileMakerError && fmError.code === 'USER_NOT_FOUND') {
          throw new AuthError('User not found in system', 'USER_NOT_FOUND');
        }
        throw new AuthError('Failed to validate user', 'VALIDATION_FAILED');
      }

      // Step 3: Combine user data from both sources
      const user: User = {
        ...fileMakerUser,
        cognitoAttributes,
      };

      // Step 4: Optionally save username for "Remember Me"
      if (tokenStorage.getRememberUsername()) {
        tokenStorage.setUsername(username);
      }

      // Step 5: Optionally update last login time in FileMaker
      if (fileMakerUser.recordId) {
        fileMakerService.updateLoginTime(fileMakerUser.recordId).catch(() => {
          // Non-critical, ignore errors
        });
      }

      setState({
        isAuthenticated: true,
        isLoading: false,
        user,
        error: null,
      });

      console.log('[Auth] Sign in complete!');
      return true;

    } catch (error) {
      console.error('[Auth] Sign in failed:', error);

      let message = 'Authentication failed';

      if (error instanceof AuthError) {
        message = error.message;
      } else if (error instanceof FileMakerError) {
        message = error.message;
      }

      setState(prev => ({
        ...prev,
        isLoading: false,
        error: message,
      }));

      return false;
    }
  }, []);

  // ===== SIGN OUT =====
  const signOut = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true }));

    try {
      await cognitoService.signOut();

      // Clear all cached data from all services
      awsCredentialsService.clearCredentials();
      secretsManagerService.clearCache();
      fileMakerService.clearToken();

    } finally {
      setState({
        isAuthenticated: false,
        isLoading: false,
        user: null,
        error: null,
      });
    }
  }, []);

  // ===== FORGOT PASSWORD =====
  const forgotPassword = useCallback(async (username: string) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      await cognitoService.forgotPassword(username);
      setState(prev => ({ ...prev, isLoading: false }));

    } catch (error) {
      const message = error instanceof AuthError
        ? error.message
        : 'Failed to send reset code';

      setState(prev => ({ ...prev, isLoading: false, error: message }));
      throw error;
    }
  }, []);

  // ===== CONFIRM FORGOT PASSWORD =====
  const confirmForgotPassword = useCallback(async (
    username: string,
    code: string,
    newPassword: string
  ) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      await cognitoService.confirmForgotPassword(username, code, newPassword);
      setState(prev => ({ ...prev, isLoading: false }));

    } catch (error) {
      const message = error instanceof AuthError
        ? error.message
        : 'Failed to reset password';

      setState(prev => ({ ...prev, isLoading: false, error: message }));
      throw error;
    }
  }, []);

  // ===== CLEAR ERROR =====
  const clearError = useCallback(() => {
    setState(prev => ({ ...prev, error: null }));
  }, []);

  // ===== MEMOIZED VALUE =====
  const value = useMemo<AuthContextValue>(() => ({
    ...state,
    signIn,
    signOut,
    forgotPassword,
    confirmForgotPassword,
    clearError,
  }), [state, signIn, signOut, forgotPassword, confirmForgotPassword, clearError]);

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

// ===== HOOK =====

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }

  return context;
}

// ===== PROTECTED ROUTE COMPONENT =====

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <div>Loading...</div>; // Replace with your loading component
  }

  if (!isAuthenticated) {
    // Redirect to login or show login component
    return <div>Please sign in</div>; // Replace with redirect logic
  }

  return <>{children}</>;
}
```

### 9.2 Usage in App

```tsx
// src/app/layout.tsx (Next.js)
import { AuthProvider } from '@/context/AuthContext';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
```

---

## 10. UI Components

### 10.1 Login Form

Create `src/components/auth/LoginForm.tsx`:

```tsx
'use client';

import React, { useState, FormEvent } from 'react';
import { useAuth } from '@/context/AuthContext';
import { tokenStorage } from '@/services/tokenStorage';

export function LoginForm() {
  const { signIn, isLoading, error, clearError } = useAuth();

  const [username, setUsername] = useState(() =>
    tokenStorage.getRememberUsername()
      ? tokenStorage.getUsername() || ''
      : ''
  );
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(() =>
    tokenStorage.getRememberUsername()
  );
  const [showForgotPassword, setShowForgotPassword] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    clearError();

    // Update remember preference
    tokenStorage.setRememberUsername(rememberMe);

    const success = await signIn(username.trim(), password);

    if (success) {
      // Redirect or handle success
      window.location.href = '/dashboard';
    }
  };

  if (showForgotPassword) {
    return <ForgotPasswordForm onBack={() => setShowForgotPassword(false)} />;
  }

  return (
    <div className="login-form">
      <h2>Sign In</h2>

      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="username">Email</label>
          <input
            id="username"
            type="email"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Enter your email"
            required
            disabled={isLoading}
          />
        </div>

        <div className="form-group">
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter your password"
            required
            disabled={isLoading}
          />
        </div>

        <div className="form-group checkbox">
          <label>
            <input
              type="checkbox"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              disabled={isLoading}
            />
            Remember me
          </label>
        </div>

        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        <button type="submit" disabled={isLoading}>
          {isLoading ? 'Signing in...' : 'Sign In'}
        </button>

        <button
          type="button"
          className="link-button"
          onClick={() => setShowForgotPassword(true)}
        >
          Forgot Password?
        </button>
      </form>
    </div>
  );
}
```

### 10.2 Forgot Password Form

Create `src/components/auth/ForgotPasswordForm.tsx`:

```tsx
'use client';

import React, { useState, FormEvent } from 'react';
import { useAuth } from '@/context/AuthContext';

interface Props {
  onBack: () => void;
}

type Step = 'email' | 'code' | 'success';

export function ForgotPasswordForm({ onBack }: Props) {
  const { forgotPassword, confirmForgotPassword, isLoading, error, clearError } = useAuth();

  const [step, setStep] = useState<Step>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [localError, setLocalError] = useState('');

  const handleSendCode = async (e: FormEvent) => {
    e.preventDefault();
    clearError();
    setLocalError('');

    try {
      await forgotPassword(email.trim());
      setStep('code');
    } catch {
      // Error is handled by context
    }
  };

  const handleResetPassword = async (e: FormEvent) => {
    e.preventDefault();
    clearError();
    setLocalError('');

    if (newPassword !== confirmPassword) {
      setLocalError('Passwords do not match');
      return;
    }

    if (newPassword.length < 8) {
      setLocalError('Password must be at least 8 characters');
      return;
    }

    try {
      await confirmForgotPassword(email.trim(), code.trim(), newPassword);
      setStep('success');
    } catch {
      // Error is handled by context
    }
  };

  const displayError = localError || error;

  // Step 1: Enter Email
  if (step === 'email') {
    return (
      <div className="forgot-password-form">
        <h2>Reset Password</h2>
        <p>Enter your email to receive a verification code.</p>

        <form onSubmit={handleSendCode}>
          <div className="form-group">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              required
              disabled={isLoading}
            />
          </div>

          {displayError && <div className="error-message">{displayError}</div>}

          <button type="submit" disabled={isLoading}>
            {isLoading ? 'Sending...' : 'Send Code'}
          </button>

          <button type="button" className="link-button" onClick={onBack}>
            Back to Sign In
          </button>
        </form>
      </div>
    );
  }

  // Step 2: Enter Code & New Password
  if (step === 'code') {
    return (
      <div className="forgot-password-form">
        <h2>Enter Verification Code</h2>
        <p>We sent a code to {email}</p>

        <form onSubmit={handleResetPassword}>
          <div className="form-group">
            <label htmlFor="code">Verification Code</label>
            <input
              id="code"
              type="text"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="Enter 6-digit code"
              required
              disabled={isLoading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="newPassword">New Password</label>
            <input
              id="newPassword"
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="Enter new password"
              required
              minLength={8}
              disabled={isLoading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="confirmPassword">Confirm Password</label>
            <input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Confirm new password"
              required
              disabled={isLoading}
            />
          </div>

          {displayError && <div className="error-message">{displayError}</div>}

          <button type="submit" disabled={isLoading}>
            {isLoading ? 'Resetting...' : 'Reset Password'}
          </button>

          <button type="button" className="link-button" onClick={() => setStep('email')}>
            Use different email
          </button>
        </form>
      </div>
    );
  }

  // Step 3: Success
  return (
    <div className="forgot-password-form success">
      <h2>Password Reset Successful!</h2>
      <p>You can now sign in with your new password.</p>

      <button onClick={onBack}>
        Back to Sign In
      </button>
    </div>
  );
}
```

### 10.3 User Menu / Profile

Create `src/components/auth/UserMenu.tsx`:

```tsx
'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';

export function UserMenu() {
  const { user, signOut, isLoading } = useAuth();
  const [isOpen, setIsOpen] = useState(false);

  if (!user) return null;

  const handleSignOut = async () => {
    await signOut();
    window.location.href = '/login';
  };

  return (
    <div className="user-menu">
      <button
        className="user-menu-trigger"
        onClick={() => setIsOpen(!isOpen)}
      >
        {user.firstName} {user.lastName}
      </button>

      {isOpen && (
        <div className="user-menu-dropdown">
          <div className="user-info">
            <strong>{user.firstName} {user.lastName}</strong>
            <span>{user.email}</span>
            <span>{user.storeName}</span>
          </div>

          <hr />

          <button
            onClick={handleSignOut}
            disabled={isLoading}
          >
            {isLoading ? 'Signing out...' : 'Sign Out'}
          </button>
        </div>
      )}
    </div>
  );
}
```

---

## 11. Password Reset Flow

### Complete Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    FORGOT PASSWORD FLOW                       │
└──────────────────────────────────────────────────────────────┘

Step 1: User enters email
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  cognitoService.forgotPassword(email)                        │
│  → Cognito sends verification code to email                  │
└──────────────────────────────────────────────────────────────┘
         │
         ▼
Step 2: User enters code + new password
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  cognitoService.confirmForgotPassword(email, code, password) │
│  → Cognito validates code and updates password               │
└──────────────────────────────────────────────────────────────┘
         │
         ▼
Step 3: Success! User can sign in with new password
```

---

## 12. Security Best Practices

### 12.1 Token Security

```typescript
// ⚠️ IMPORTANT: Choose the right storage strategy

// Option 1: localStorage (Persistent but vulnerable to XSS)
// - Tokens persist across browser sessions
// - Vulnerable to XSS attacks
// - Use for "Remember Me" functionality

// Option 2: sessionStorage (More secure, session-only)
// - Tokens cleared when tab closes
// - Still vulnerable to XSS but limited exposure
// - Better for sensitive applications

// Option 3: HttpOnly Cookies (Most secure, requires backend)
// - Not accessible via JavaScript
// - Requires backend proxy for Cognito calls
// - Recommended for production applications
```

### 12.2 Security Checklist

- [ ] **Never expose client secret in frontend code**
  - If your app client has a secret, use a backend proxy

- [ ] **Use HTTPS everywhere**
  - All Cognito and API calls must be over HTTPS

- [ ] **Implement token refresh**
  - Automatically refresh tokens before expiry

- [ ] **Clear tokens on sign out**
  - Call GlobalSignOut to invalidate server-side
  - Clear all local storage

- [ ] **Validate tokens server-side**
  - Don't trust client-side token validation alone

- [ ] **Implement proper error handling**
  - Don't expose internal error details to users

- [ ] **Use Content Security Policy (CSP)**
  - Prevent XSS attacks

### 12.3 Client Secret Handling

```typescript
// ⚠️ WARNING: Client secrets should NOT be in frontend code!

// If your Cognito App Client has a client secret:
// 1. Create a new App Client WITHOUT a client secret, OR
// 2. Use a backend proxy to handle authentication

// Backend proxy example (Next.js API route):
// src/pages/api/auth/signin.ts

import type { NextApiRequest, NextApiResponse } from 'next';
import {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
} from '@aws-sdk/client-cognito-identity-provider';
import crypto from 'crypto';

const cognitoClient = new CognitoIdentityProviderClient({
  region: process.env.AWS_REGION,
});

function calculateSecretHash(username: string): string {
  const message = username + process.env.COGNITO_CLIENT_ID;
  const hmac = crypto.createHmac('sha256', process.env.COGNITO_CLIENT_SECRET!);
  hmac.update(message);
  return hmac.digest('base64');
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { username, password } = req.body;

  try {
    const command = new InitiateAuthCommand({
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: process.env.COGNITO_CLIENT_ID,
      AuthParameters: {
        USERNAME: username,
        PASSWORD: password,
        SECRET_HASH: calculateSecretHash(username),
      },
    });

    const response = await cognitoClient.send(command);

    // Return tokens (or set HttpOnly cookies)
    res.status(200).json({
      idToken: response.AuthenticationResult?.IdToken,
      accessToken: response.AuthenticationResult?.AccessToken,
      refreshToken: response.AuthenticationResult?.RefreshToken,
      expiresIn: response.AuthenticationResult?.ExpiresIn,
    });

  } catch (error: any) {
    res.status(401).json({
      error: error.name || 'AuthenticationFailed',
      message: 'Invalid credentials',
    });
  }
}
```

---

## 13. Testing

### 13.1 Test Utilities

Create `src/test/authTestUtils.ts`:

```typescript
import { CognitoUserAttributes, CognitoTokens } from '@/types/aws';

export const mockUser: CognitoUserAttributes = {
  email: 'test@example.com',
  firstName: 'Test',
  lastName: 'User',
  storeName: 'Test Store',
  customerId: 'company-123',
  locationStatus: 'Active',
  recordId: 'record-456',
};

export const mockTokens: CognitoTokens = {
  idToken: 'mock-id-token',
  accessToken: 'mock-access-token',
  refreshToken: 'mock-refresh-token',
  expiresAt: Date.now() + 3600000,
};

// Mock cognitoService for testing
export const mockCognitoService = {
  signIn: jest.fn().mockResolvedValue(mockUser),
  signOut: jest.fn().mockResolvedValue(undefined),
  refreshTokens: jest.fn().mockResolvedValue(true),
  forgotPassword: jest.fn().mockResolvedValue(undefined),
  confirmForgotPassword: jest.fn().mockResolvedValue(undefined),
  isAuthenticated: jest.fn().mockReturnValue(true),
  getCurrentUser: jest.fn().mockReturnValue(mockUser),
  getAccessToken: jest.fn().mockReturnValue('mock-access-token'),
};
```

### 13.2 Integration Test Example

```typescript
// src/test/auth.integration.test.ts

import { cognitoService } from '@/services/cognitoService';
import { tokenStorage } from '@/services/tokenStorage';

describe('Cognito Authentication', () => {
  beforeEach(() => {
    tokenStorage.clearTokens();
  });

  describe('signIn', () => {
    it('should authenticate valid credentials', async () => {
      // Use test credentials (from Cognito test user)
      const user = await cognitoService.signIn(
        'test@example.com',
        'TestPassword123!'
      );

      expect(user.email).toBe('test@example.com');
      expect(tokenStorage.getAccessToken()).toBeTruthy();
    });

    it('should reject invalid credentials', async () => {
      await expect(
        cognitoService.signIn('test@example.com', 'wrongpassword')
      ).rejects.toThrow('Invalid email or password');
    });
  });

  describe('tokenRefresh', () => {
    it('should refresh expired tokens', async () => {
      // First sign in
      await cognitoService.signIn('test@example.com', 'TestPassword123!');

      // Then refresh
      const refreshed = await cognitoService.refreshTokens();
      expect(refreshed).toBe(true);
    });
  });
});
```

---

## 14. Troubleshooting

### Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `NotAuthorizedException` | Wrong password or disabled user | Check credentials, verify user status in Cognito |
| `UserNotFoundException` | Email not registered | Verify user exists in User Pool |
| `UserNotConfirmedException` | Email not verified | User needs to confirm email |
| `InvalidParameterException` | Malformed request | Check all required parameters |
| `ResourceNotFoundException` | Wrong User Pool ID | Verify configuration |
| `AccessDeniedException` | IAM policy issue | Check Identity Pool role permissions |
| CORS errors | Missing CORS config | Add domain to Cognito app client |

### Debug Logging

```typescript
// Enable detailed logging for debugging

const DEBUG = process.env.NODE_ENV === 'development';

function debugLog(message: string, data?: any) {
  if (DEBUG) {
    console.log(`[Auth Debug] ${message}`, data || '');
  }
}

// Use in services:
debugLog('Initiating sign in', { username });
debugLog('Sign in successful', { user: user.email });
debugLog('Token refresh', { expiresAt: tokens.expiresAt });
```

### Checking AWS Configuration

```typescript
// Add to your app initialization:

import { validateConfig } from '@/config/aws';

// In your app startup:
try {
  validateConfig();
  console.log('AWS configuration validated successfully');
} catch (error) {
  console.error('AWS configuration error:', error);
  // Show error to user or redirect to config page
}
```

---

## Quick Start Checklist

### Phase 1: Setup
1. [ ] Install required packages (`@aws-sdk/*`, `jwt-decode`)
2. [ ] Create environment variables file (`.env.local`)
3. [ ] Copy AWS configuration values from iOS app

### Phase 2: AWS Services
4. [ ] Create TypeScript types (`src/types/aws.ts`)
5. [ ] Implement `cognitoService.ts` - Cognito authentication
6. [ ] Implement `awsCredentialsService.ts` - Get AWS credentials
7. [ ] Implement `secretsManagerService.ts` - Fetch FileMaker credentials
8. [ ] Implement `tokenStorage.ts` - LocalStorage for tokens

### Phase 3: FileMaker Integration
9. [ ] Create FileMaker types (`src/types/filemaker.ts`)
10. [ ] Implement `fileMakerService.ts` - Session token & user validation
11. [ ] Test FileMaker API connection

### Phase 4: React Integration
12. [ ] Create `AuthContext.tsx` provider (with FileMaker validation)
13. [ ] Wrap app with `AuthProvider`
14. [ ] Create login UI components
15. [ ] Create user menu component

### Phase 5: Testing
16. [ ] Test complete authentication flow (Cognito → FileMaker)
17. [ ] Test password reset flow
18. [ ] Test token refresh (Cognito + FileMaker)
19. [ ] Test sign out (clears all tokens)
20. [ ] Deploy and verify CORS settings

---

## File Structure Summary

```
src/
├── config/
│   └── aws.ts                    # AWS configuration
├── types/
│   ├── aws.ts                    # AWS TypeScript types
│   └── filemaker.ts              # FileMaker TypeScript types
├── services/
│   ├── cognitoService.ts         # Cognito authentication
│   ├── awsCredentialsService.ts  # AWS credentials via Identity Pool
│   ├── secretsManagerService.ts  # Secrets Manager access
│   ├── fileMakerService.ts       # FileMaker API (user validation)
│   └── tokenStorage.ts           # Token storage (localStorage)
├── context/
│   └── AuthContext.tsx           # React auth context (with FM validation)
├── components/
│   └── auth/
│       ├── LoginForm.tsx         # Login form component
│       ├── ForgotPasswordForm.tsx # Password reset
│       └── UserMenu.tsx          # User profile/menu
└── test/
    └── authTestUtils.ts          # Test utilities
```

---

## Need Help?

- **AWS Cognito Docs:** https://docs.aws.amazon.com/cognito/
- **AWS SDK v3 for JavaScript:** https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/
- **JWT Decode:** https://github.com/auth0/jwt-decode

---

*This guide is based on the Ingenes iOS app implementation. All configuration values are taken from your existing AWS setup.*
