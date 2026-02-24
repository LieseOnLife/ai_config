---
name: cloud-inventory
description: Cloud Accounts team context and guidelines for working on cloud-inventory. Use when working on cloud-inventory, GCP projects, AWS accounts, or cloud provider organization management.
user-invocable: false
---

# Cloud-Inventory Context

This is the Cloud Accounts team configuration for working on cloud-inventory and related projects.

## Cloud-Inventory Context

The Cloud Accounts team maintains cloud-inventory, a system for discovering, cataloging, and managing cloud resources across multiple providers. This includes:

### Core Responsibilities
- Multi-cloud resource discovery and inventory management
- Cloud provider account onboarding and lifecycle management
- Human access management and organization definitions
- Resource tagging, compliance, and cost optimization
- Cloud provider organization and account structure management

### Key Focus Areas
- **Organization Definitions**: Cloud provider account hierarchies and organizational structures
- **Human Access Patterns**: User access management across cloud providers
- **Resource Discovery**: Automated cataloging of cloud resources
- **Compliance Management**: Policy enforcement and compliance tracking

## Development Guidelines

### Code Organization
- Follow existing patterns in cloud-inventory codebase
- Separate cloud provider logic into distinct modules/packages
- Use factory patterns for multi-cloud abstraction
- Implement consistent error handling across providers

### Organization Structure Management
- Maintain consistent organization definitions across providers
- Document account hierarchy and relationships
- Implement proper access controls for organizational resources
- Track organizational changes and access patterns

### Testing Requirements
- Unit tests for business logic
- Integration tests against real cloud provider APIs (staging environments)
- Mock cloud provider responses for CI/CD pipelines
- Document manual testing procedures for complex scenarios

### Security Standards
- Never commit credentials, secrets, or API keys
- Use environment variables and secure secret management
- Validate and sanitize all cloud provider inputs
- Implement proper IAM roles and permission boundaries
- Regular security reviews of cloud access patterns

## Cloud Provider Configurations

### AWS
- **Organization Structure**: Manage AWS Organizations, accounts, and OUs
- **Human Access**: IAM users, roles, and cross-account access patterns
- **Resource Discovery**: EC2, S3, RDS, Lambda, and other AWS services
- **Naming Conventions**: Follow AWS resource naming and tagging standards

### GCP
- **Organization Structure**: Google Cloud Organization, folders, and projects
- **Human Access**: IAM users, service accounts, and project-level permissions
- **Resource Discovery**: Compute Engine, Cloud Storage, BigQuery, and other GCP services
- **Naming Conventions**: Follow GCP project and resource hierarchy patterns

### Azure
- **Organization Structure**: Azure AD tenants, subscriptions, and resource groups
- **Human Access**: Azure AD users, groups, and role-based access control (RBAC)
- **Resource Discovery**: Virtual machines, storage accounts, databases, and other Azure services

### OCI (Oracle Cloud Infrastructure)
- **Organization Structure**: Tenancies, compartments, and identity domains
- **Human Access**: OCI users, groups, and compartment-based access control
- **Resource Discovery**: Compute instances, object storage, databases, and other OCI services
