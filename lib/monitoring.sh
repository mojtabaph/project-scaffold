#!/bin/bash
# lib/monitoring.sh - Observability stack

generate_monitoring() {
  info "Observability (monitoring)"

  mkdir -p "$PROJECT_PATH/monitoring"

  # Prometheus configuration
  cat > "$PROJECT_PATH/monitoring/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'backend'
    static_configs:
      - targets: ['backend:8080']
    metrics_path: '/metrics'

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
EOF
  log "monitoring/prometheus.yml"

  # Alert rules
  cat > "$PROJECT_PATH/monitoring/alert_rules.yml" << 'EOF'
groups:
  - name: alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"

      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service is down"
EOF
  log "monitoring/alert_rules.yml"

  # Structured logging (Node.js only)
  if [ "$BACKEND" = "nodejs" ]; then
    cat > "$PROJECT_PATH/backend/logger.js" << 'EOF'
const levels = { error: 0, warn: 1, info: 2, debug: 3 };

const logger = {
  level: levels[process.env.LOG_LEVEL] || levels.info,

  log(level, message, meta = {}) {
    if (levels[level] <= this.level) {
      const entry = {
        timestamp: new Date().toISOString(),
        level,
        message,
        ...meta,
      };
      console.log(JSON.stringify(entry));
    }
  },

  error(message, meta) { this.log('error', message, meta); },
  warn(message, meta) { this.log('warn', message, meta); },
  info(message, meta) { this.log('info', message, meta); },
  debug(message, meta) { this.log('debug', message, meta); },
};

module.exports = logger;
EOF
    log "backend/logger.js"
  fi

  # Health check endpoint (Node.js only)
  if [ "$BACKEND" = "nodejs" ]; then
    cat > "$PROJECT_PATH/backend/health.js" << 'EOF'
const healthCheck = async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {
      database: 'ok',
      memory: process.memoryUsage(),
    },
  };

  res.json(health);
};

module.exports = { healthCheck };
EOF
    log "backend/health.js"
  fi
}
