#!/bin/bash
# lib/backend.sh - Backend generation (Go/Node/Rust)

generate_backend() {
  info "Building Backend ($BACKEND)"

  case $BACKEND in
    go)     generate_go_backend ;;
    nodejs) generate_nodejs_backend ;;
    rust)   generate_rust_backend ;;
  esac
}

generate_go_backend() {
  case $DB in
    postgres) GO_DRIVER='github.com/lib/pq v1.10.9' ;;
    mysql)    GO_DRIVER='github.com/go-sql-driver/mysql v1.8.1' ;;
    mongodb)  GO_DRIVER='go.mongodb.org/mongo-driver v1.17.3' ;;
    sqlite)   GO_DRIVER='github.com/ncruces/go-sqlite3 v0.20.2' ;;
    *)        GO_DRIVER='github.com/lib/pq v1.10.9' ;;
  esac

  cat > "$PROJECT_PATH/backend/go.mod" << EOF
module github.com/yourname/$PROJECT_NAME/backend

go 1.23

require $GO_DRIVER
EOF

  if [ "$FRONTEND" = "templ" ]; then
    echo 'require github.com/a-h/templ v0.3.1020' >> "$PROJECT_PATH/backend/go.mod"
  fi

  cat > "$PROJECT_PATH/backend/main.go" << 'EOF'
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"ok"}`)
}

func main() {
	http.HandleFunc("/api/health", healthHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Server running on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
EOF
  log "backend/main.go"

  cat > "$PROJECT_PATH/backend/Dockerfile" << 'EOF'
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/server .
EXPOSE 8080
CMD ["./server"]
EOF
  log "backend/Dockerfile"

  # Test skeleton
  cat > "$PROJECT_PATH/backend/main_test.go" << 'EOF'
package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealth(t *testing.T) {
	// Arrange
	req := httptest.NewRequest(http.MethodGet, "/api/health", nil)
	w := httptest.NewRecorder()

	// Act
	healthHandler(w, req)

	// Assert
	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}
}

func TestHealthContentType(t *testing.T) {
	// Arrange
	req := httptest.NewRequest(http.MethodGet, "/api/health", nil)
	w := httptest.NewRecorder()

	// Act
	healthHandler(w, req)

	// Assert
	ct := w.Header().Get("Content-Type")
	if ct != "application/json" {
		t.Errorf("expected Content-Type application/json, got %s", ct)
	}
}

func TestHealthReturnsJSON(t *testing.T) {
	// Arrange
	req := httptest.NewRequest(http.MethodGet, "/api/health", nil)
	w := httptest.NewRecorder()

	// Act
	healthHandler(w, req)

	// Assert
	body := w.Body.String()
	if !strings.Contains(body, `"status":"ok"`) {
		t.Errorf("expected body to contain status:ok, got %s", body)
	}
}
EOF
  log "backend/main_test.go"
}

generate_nodejs_backend() {
  cat > "$PROJECT_PATH/backend/package.json" << EOF
{
  "name": "$PROJECT_NAME-backend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "node index.js",
    "start": "node index.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "supertest": "^6.3.3"
  }
}
EOF
  log "backend/package.json"

  cat > "$PROJECT_PATH/backend/index.js" << 'EOF'
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

if (require.main === module) {
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
EOF
  log "backend/index.js"

  cat > "$PROJECT_PATH/backend/Dockerfile" << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8080
CMD ["node", "index.js"]
EOF
  log "backend/Dockerfile"

  # Test config
  cat > "$PROJECT_PATH/backend/jest.config.js" << 'EOF'
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: ['index.js'],
};
EOF
  log "backend/jest.config.js"

  # Test skeleton
  mkdir -p "$PROJECT_PATH/backend/__tests__"
  cat > "$PROJECT_PATH/backend/__tests__/health.test.js" << 'EOF'
const request = require('supertest');
const app = require('../index');

describe('Health API', () => {
  describe('GET /api/health', () => {
    it('should return HTTP 200', async () => {
      const res = await request(app).get('/api/health');
      expect(res.status).toBe(200);
    });

    it('should return JSON content type', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['content-type']).toMatch(/json/);
    });

    it('should return status ok', async () => {
      const res = await request(app).get('/api/health');
      expect(res.body.status).toBe('ok');
    });
  });
});
EOF
  log "backend/__tests__/health.test.js"
}

generate_rust_backend() {
  cat > "$PROJECT_PATH/backend/Cargo.toml" << EOF
[package]
name = "$PROJECT_NAME"
version = "0.1.0"
edition = "2021"

[dependencies]
actix-web = "4"
actix-rt = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["full"] }
dotenv = "0.15"

[dev-dependencies]
actix-test = "0.1"
serde_json = "1"
EOF
  log "backend/Cargo.toml"

  cat > "$PROJECT_PATH/backend/src/main.rs" << 'EOF'
use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use serde::Serialize;

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: String,
}

pub async fn health() -> HttpResponse {
    HttpResponse::Ok().json(HealthResponse {
        status: "ok".to_string(),
    })
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv::dotenv().ok();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{}", port);

    println!("Server running on {}", addr);

    HttpServer::new(|| {
        App::new()
            .route("/api/health", web::get().to(health))
    })
    .bind(&addr)?
    .run()
    .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, web};

    #[actix_web::test]
    async fn test_health_returns_200() {
        let app = test::init_service(
            App::new().route("/api/health", web::get().to(health))
        ).await;

        let req = test::TestRequest::get().uri("/api/health").to_request();
        let resp = test::call_service(&app, req).await;

        assert_eq!(resp.status(), 200);
    }

    #[actix_web::test]
    async fn test_health_returns_json() {
        let app = test::init_service(
            App::new().route("/api/health", web::get().to(health))
        ).await;

        let req = test::TestRequest::get().uri("/api/health").to_request();
        let resp = test::call_service(&app, req).await;

        assert_eq!(
            resp.headers().get("content-type").unwrap(),
            "application/json"
        );
    }

    #[actix_web::test]
    async fn test_health_body() {
        let app = test::init_service(
            App::new().route("/api/health", web::get().to(health))
        ).await;

        let req = test::TestRequest::get().uri("/api/health").to_request();
        let resp = test::call_service(&app, req).await;

        let body = test::read_body(resp).await;
        let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
        assert_eq!(json["status"], "ok");
    }
}
EOF
  log "backend/src/main.rs"

  cat > "$PROJECT_PATH/backend/Dockerfile" << 'EOF'
FROM rust:1.82 AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/server /usr/local/bin/server
EXPOSE 8080
CMD ["server"]
EOF
  log "backend/Dockerfile"
}
