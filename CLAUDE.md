# DevOps & Platform Engineering Best Practices

## Overview
This document outlines best practices, standards, and guidelines for DevOps and Platform Engineering teams, based on real-world experiences and common pitfalls encountered in CI/CD pipelines and automation workflows.

## Table of Contents
1. [GitHub Actions Best Practices](#github-actions-best-practices)
2. [YAML Standards](#yaml-standards)
3. [Shell Scripting Guidelines](#shell-scripting-guidelines)
4. [CI/CD Pipeline Design](#cicd-pipeline-design)
5. [Security & Secrets Management](#security--secrets-management)
6. [Testing & Validation](#testing--validation)
7. [Monitoring & Observability](#monitoring--observability)
8. [Platform Engineering Standards](#platform-engineering-standards)

---

## GitHub Actions Best Practices

### 1. YAML Syntax & Structure

#### ✅ DO
```yaml
name: Clear, descriptive workflow name
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18'
  REGISTRY: ghcr.io

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
```

#### ❌ DON'T
```yaml
# Avoid unclear names
name: CI
# Avoid inline multiline strings that can break YAML parsing
run: |
  COMMENT="Line 1
  Line 2"  # This can cause YAML parsing errors
```

### 2. Multiline String Handling

#### ✅ DO - Use Heredoc for Complex Strings
```yaml
- name: Create comment
  run: |
    COMMENT=$(cat <<EOF
    ## Summary
    ${DETAILS}
    
    Please review and merge. 🙏
    EOF
    )
    gh pr comment "$PR_URL" --body "$COMMENT"
```

#### ❌ DON'T - Use Complex Inline Strings
```yaml
- name: Create comment
  run: |
    COMMENT="## Summary
    ${DETAILS}
    Please review"  # Can cause parsing issues
```

### 3. Environment Variables & Secrets

#### ✅ DO
```yaml
env:
  NODE_ENV: production
  DATABASE_URL: ${{ secrets.DATABASE_URL }}

steps:
  - name: Deploy
    env:
      API_KEY: ${{ secrets.API_KEY }}
    run: |
      echo "Using API key for deployment"
      # Never echo secrets directly
```

#### ❌ DON'T
```yaml
steps:
  - name: Debug
    run: |
      echo "API_KEY: ${{ secrets.API_KEY }}"  # NEVER log secrets
```

### 4. Conditional Execution

#### ✅ DO
```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: ./deploy.sh

- name: Run tests
  if: success() || failure()  # Run even if previous steps fail
  run: npm test
```

---

## YAML Standards

### 1. Indentation & Formatting
- Use 2 spaces for indentation (never tabs)
- Be consistent with spacing around colons
- Use explicit quotes for strings containing special characters

### 2. Validation
Always validate YAML syntax before committing:
```bash
# Using yamllint
yamllint .github/workflows/

# Using Python
python -c "import yaml; yaml.safe_load(open('workflow.yml'))"

# Using yq
yq eval '.jobs' workflow.yml
```

### 3. Comments & Documentation
```yaml
# Purpose: Deploy application to staging environment
# Triggers: Push to develop branch, manual dispatch
# Dependencies: Build job must complete successfully
name: Deploy to Staging
```

---

## Shell Scripting Guidelines

### 1. Error Handling

#### ✅ DO
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

function cleanup() {
    echo "Cleaning up..."
    rm -f temp_file.txt
}
trap cleanup EXIT

# Function with error handling
deploy_app() {
    local app_name=$1
    local version=$2
    
    if [[ -z "$app_name" || -z "$version" ]]; then
        echo "Error: Missing required parameters" >&2
        return 1
    fi
    
    echo "Deploying $app_name version $version..."
    kubectl apply -f deployment.yaml || {
        echo "Deployment failed" >&2
        return 1
    }
}
```

#### ❌ DON'T
```bash
#!/bin/bash
# No error handling, variables not quoted
deploy_app() {
    kubectl apply -f deployment.yaml
    echo Deployed $1  # Unquoted variable
}
```

### 2. Variable Handling

#### ✅ DO
```bash
# Quote variables to prevent word splitting
local file_path="/path/with spaces/file.txt"
if [[ -f "$file_path" ]]; then
    echo "File exists: $file_path"
fi

# Use arrays for multiple values
declare -a services=("api" "web" "worker")
for service in "${services[@]}"; do
    echo "Deploying $service"
done
```

### 3. Input Validation

#### ✅ DO
```bash
validate_input() {
    local email=$1
    local pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    
    if [[ ! "$email" =~ $pattern ]]; then
        echo "Invalid email format: $email" >&2
        return 1
    fi
}
```

---

## CI/CD Pipeline Design

### 1. Pipeline Structure

#### ✅ DO - Use Job Dependencies
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build application
        run: npm run build

  deploy:
    needs: [test, build]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: ./deploy.sh
```

### 2. Environment Management

#### ✅ DO
```yaml
strategy:
  matrix:
    environment: [staging, production]
    include:
      - environment: staging
        api_url: https://api-staging.example.com
      - environment: production
        api_url: https://api.example.com
```

### 3. Artifact Management

#### ✅ DO
```yaml
- name: Upload build artifacts
  uses: actions/upload-artifact@v3
  with:
    name: build-artifacts-${{ github.sha }}
    path: |
      dist/
      !dist/**/*.map
    retention-days: 7
```

---

## Security & Secrets Management

### 1. Secret Handling

#### ✅ DO
```yaml
steps:
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v2
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: us-east-1

  - name: Deploy with masked output
    run: |
      # Mask sensitive data in logs
      echo "::add-mask::${{ secrets.DATABASE_PASSWORD }}"
      ./deploy.sh
```

### 2. Permissions & Access Control

#### ✅ DO
```yaml
permissions:
  contents: read
  packages: write
  id-token: write  # For OIDC

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Use environment protection rules
```

### 3. Dependency Security

#### ✅ DO
```yaml
- name: Security audit
  run: |
    npm audit --audit-level=high
    npm audit fix --dry-run

- name: Check for known vulnerabilities
  uses: github/super-linter@v4
  env:
    VALIDATE_YAML: true
    VALIDATE_BASH: true
```

---

## Testing & Validation

### 1. Pre-commit Validation

#### ✅ DO
```bash
#!/bin/bash
# pre-commit hook
set -e

echo "Running pre-commit validations..."

# YAML validation
find . -name "*.yml" -o -name "*.yaml" | xargs yamllint

# Shell script validation
find . -name "*.sh" | xargs shellcheck

# Terraform validation
terraform fmt -check=true
terraform validate

echo "All validations passed!"
```

### 2. Integration Testing

#### ✅ DO
```yaml
- name: Integration tests
  run: |
    docker-compose up -d
    sleep 10  # Wait for services to start
    
    # Run health checks
    curl -f http://localhost:8080/health || exit 1
    
    # Run integration tests
    npm run test:integration
  env:
    NODE_ENV: test
```

### 3. Performance Testing

#### ✅ DO
```yaml
- name: Performance tests
  run: |
    # Load testing
    k6 run --vus 10 --duration 30s performance-test.js
    
    # Report results
    if [ $? -eq 0 ]; then
      echo "Performance tests passed"
    else
      echo "Performance tests failed"
      exit 1
    fi
```

---

## Monitoring & Observability

### 1. Workflow Monitoring

#### ✅ DO
```yaml
- name: Report workflow status
  if: always()
  run: |
    STATUS=${{ job.status }}
    WORKFLOW_URL="${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
    
    curl -X POST "$SLACK_WEBHOOK" \
      -d "{\"text\":\"Workflow $STATUS: $WORKFLOW_URL\"}"
  env:
    SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

### 2. Metrics & Logging

#### ✅ DO
```yaml
- name: Collect metrics
  run: |
    # Deployment metrics
    echo "deployment_time=$(date +%s)" >> $GITHUB_OUTPUT
    echo "deployment_version=${{ github.sha }}" >> $GITHUB_OUTPUT
    
    # Send to monitoring system
    curl -X POST "$METRICS_ENDPOINT" \
      -d "deployment_duration=$DURATION" \
      -d "deployment_status=success"
```

---

## Platform Engineering Standards

### 1. Infrastructure as Code

#### ✅ DO
```yaml
# Terraform workflow
- name: Terraform Plan
  run: |
    terraform init
    terraform plan -out=tfplan
    terraform show -json tfplan > plan.json

- name: Security scan
  run: |
    checkov -f plan.json
    tfsec .
```

### 2. Container Standards

#### ✅ DO
```dockerfile
# Multi-stage build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS runtime
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
COPY --from=builder /app/node_modules ./node_modules
USER nextjs
EXPOSE 3000
```

### 3. Service Mesh & Networking

#### ✅ DO
```yaml
# Kubernetes deployment with proper resource limits
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: api
        image: api:latest
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

---

## Common Pitfalls & Solutions

### 1. YAML Parsing Errors
- **Problem**: Complex multiline strings causing parsing issues
- **Solution**: Use heredoc syntax for complex strings
- **Prevention**: Always validate YAML before committing

### 2. Shell Script Failures
- **Problem**: Unhandled errors, unquoted variables
- **Solution**: Use `set -euo pipefail`, quote all variables
- **Prevention**: Use shellcheck for validation

### 3. Secret Exposure
- **Problem**: Accidentally logging secrets
- **Solution**: Use `::add-mask::` to mask sensitive data
- **Prevention**: Never echo secrets, use environment variables

### 4. Resource Limits
- **Problem**: Jobs running out of resources
- **Solution**: Set appropriate resource limits and timeouts
- **Prevention**: Monitor resource usage and set alerts

---

## Conclusion

Following these best practices will help ensure:
- **Reliability**: Workflows that run consistently
- **Security**: Proper handling of secrets and permissions
- **Maintainability**: Code that's easy to understand and modify
- **Scalability**: Pipelines that can grow with your needs

Remember: Always test your workflows in a staging environment before deploying to production, and continuously monitor and improve your processes based on real-world usage.

---

*This document should be regularly updated as new best practices emerge and tools evolve.*