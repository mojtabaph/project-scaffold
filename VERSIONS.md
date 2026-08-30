# Version Matrix - Current Versions in Script

## Last Updated: August 30, 2026

---

## 🐳 Docker Images

| Image | Version |
|-------|---------|
| golang | 1.23-alpine |
| node | 20-alpine |
| rust | 1.82 |
| alpine | 3.19 |
| debian | bookworm-slim |
| postgres | 16-alpine |
| mysql | 8.0 |
| mongo | 7 |
| redis | 7-alpine |
| nginx | stable-alpine |

---

## 📦 Backend Dependencies

### Go
| Dependency | Version |
|------------|---------|
| go.mod | go 1.23 |
| lib/pq (postgres) | v1.10.9 |
| go-sql-driver/mysql | v1.8.1 |
| mongo-driver | v1.17.3 |
| go-sqlite3 | v0.20.2 |
| templ | v0.3.1020 |

### Node.js
| Dependency | Version |
|------------|---------|
| express | ^4.18.2 |
| cors | ^2.8.5 |
| dotenv | ^16.3.1 |
| jest | ^29.7.0 |
| supertest | ^6.3.3 |

### Rust
| Dependency | Version |
|------------|---------|
| actix-web | 4 |
| actix-rt | 2 |
| serde | 1 |
| tokio | 1 |
| dotenv | 0.15 |

---

## 🎨 Frontend Dependencies

### Core
| Dependency | Version |
|------------|---------|
| react | ^18.2.0 |
| react-dom | ^18.2.0 |
| next | ^14.0.0 |
| vue | ^3.4.0 |
| angular/core | ^17.0.0 |
| svelte | ^4.2.0 |
| typescript | ^5.0.0 |
| vite | ^5.0.0 |

### CSS Frameworks
| Dependency | Version |
|------------|---------|
| tailwindcss | ^3.3.0 |
| bootstrap | 5.3.3 |
| @mui/material | ^5.15.0 |
| @chakra-ui/react | ^2.8.0 |
| antd | ^5.15.0 |

### Testing
| Dependency | Version |
|------------|---------|
| vitest | ^1.6.0 |
| jest | ^29.7.0 |
| @testing-library/react | ^16.0.1 |
| @testing-library/jest-dom | ^6.4.8 |

---

## 🔧 CI/CD

| Component | Version |
|-----------|---------|
| GitHub Actions Go | 1.23 |
| DevContainer base | ubuntu |
| Rust MSRV | 1.75 |
