#\!/bin/bash
# Jenkins deployment script

set -e

echo "Starting deployment process..."

# Environment setup
DEPLOY_ENV=${1:-staging}
APP_VERSION=${2:-latest}

echo "Deploying version $APP_VERSION to $DEPLOY_ENV environment"

# Pre-deployment checks
if [ "$DEPLOY_ENV" = "production" ]; then
    echo "Running production pre-deployment checks..."
    # Add production-specific checks here
fi

# Deploy application
echo "Deploying application..."
kubectl apply -f k8s/
kubectl set image deployment/app app=myapp:$APP_VERSION

# Wait for deployment
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/app

# Post-deployment verification
echo "Running post-deployment verification..."
curl -f http://app.example.com/health || exit 1

echo "Deployment completed successfully\!"
EOF < /dev/null