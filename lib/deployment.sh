#!/bin/bash
# lib/deployment.sh - Multi-platform deployment

generate_deployment() {
  info "Multi-platform deployment"

  # Kubernetes
  mkdir -p "$PROJECT_PATH/deploy/k8s"
  cat > "$PROJECT_PATH/deploy/k8s/deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: backend:latest
          ports:
            - containerPort: 8080
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
EOF
  log "deploy/k8s/deployment.yaml"

  cat > "$PROJECT_PATH/deploy/k8s/service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
EOF
  log "deploy/k8s/service.yaml"

  # AWS ECS
  mkdir -p "$PROJECT_PATH/deploy/aws"
  cat > "$PROJECT_PATH/deploy/aws/task-definition.json" << 'EOF'
{
  "family": "backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "backend:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "APP_ENV",
          "value": "production"
        }
      ]
    }
  ]
}
EOF
  log "deploy/aws/task-definition.json"

  # Google Cloud Run
  mkdir -p "$PROJECT_PATH/deploy/gcp"
  cat > "$PROJECT_PATH/deploy/gcp/service.yaml" << 'EOF'
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: backend
spec:
  template:
    spec:
      containers:
        - image: backend:latest
          ports:
            - containerPort: 8080
          env:
            - name: APP_ENV
              value: production
          resources:
            limits:
              cpu: 1000m
              memory: 512Mi
EOF
  log "deploy/gcp/service.yaml"

  # Azure Container Apps
  mkdir -p "$PROJECT_PATH/deploy/azure"
  cat > "$PROJECT_PATH/deploy/azure/container-app.json" << 'EOF'
{
  "name": "backend",
  "type": "Microsoft.App/containerApps",
  "properties": {
    "configuration": {
      "ingress": {
        "external": true,
        "targetPort": 8080
      }
    },
    "template": {
      "containers": [
        {
          "name": "backend",
          "image": "backend:latest",
          "resources": {
            "cpu": 0.5,
            "memory": "1Gi"
          }
        }
      ],
      "scale": {
        "minReplicas": 1,
        "maxReplicas": 10
      }
    }
  }
}
EOF
  log "deploy/azure/container-app.json"
}
