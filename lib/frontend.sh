#!/bin/bash
# lib/frontend.sh - Frontend generation (6 frameworks)

generate_frontend() {
  info "Building Frontend ($FRONTEND)"

  # CDN fallback for frameworks without full npm support
  CDN_LINK=""
  case $CSS_FW in
    bootstrap)  CDN_LINK='<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">' ;;
    ant-design) CDN_LINK='<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/antd@4.24.15/dist/antd.min.css">' ;;
    material-ui|chakra-ui)
      CDN_LINK='<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">'
      warn "$CSS_FW on $FRONTEND replaced with Bootstrap CDN (npm import only in Next.js/React)"
      CSS_FW="bootstrap"
      ;;
    *) CDN_LINK="" ;;
  esac

  case $FRONTEND in
    nextjs) generate_nextjs ;;
    react)  generate_react ;;
    vue)    generate_vue ;;
    angular) generate_angular ;;
    svelte) generate_svelte ;;
    templ)  generate_templ ;;
  esac
}

generate_nextjs() {
  if [ "$FRONTEND_TESTING" = "jest" ]; then
    FRONT_TEST_SCRIPT="jest"
    FRONT_DEVDEPS=$',\n    "jest": "^29.7.0",\n    "jest-environment-jsdom": "^29.7.0",\n    "@testing-library/react": "^16.0.1",\n    "@testing-library/jest-dom": "^6.4.8",\n    "@types/jest": "^29.5.13"'
  else
    FRONT_TEST_SCRIPT=""
    FRONT_DEVDEPS=""
  fi

  cat > "$PROJECT_PATH/frontend/package.json" << EOF
{
  "name": "$PROJECT_NAME-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "$FRONT_TEST_SCRIPT"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "next": "^14.0.0"
EOF

  case $CSS_FW in
    material-ui) echo '    ,"@mui/material": "^5.15.0", "@emotion/react": "^11.11.0", "@emotion/styled": "^11.11.0"' ;;
    chakra-ui)   echo '    ,"@chakra-ui/react": "^2.8.0", "@emotion/react": "^11.11.0", "@emotion/styled": "^11.11.0", "framer-motion": "^11.0.0"' ;;
    ant-design)  echo '    ,"antd": "^5.15.0"' ;;
  esac >> "$PROJECT_PATH/frontend/package.json"

  cat >> "$PROJECT_PATH/frontend/package.json" << EOF
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0",
    "tailwindcss": "^3.3.0"$FRONT_DEVDEPS
  }
}
EOF
  log "frontend/package.json"

  cat > "$PROJECT_PATH/frontend/next.config.js" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
}
module.exports = nextConfig
EOF
  log "frontend/next.config.js"

  mkdir -p "$PROJECT_PATH/frontend/pages"
  cat > "$PROJECT_PATH/frontend/pages/index.js" << EOF
export default function Home() {
  return (
    <div>
      <h1>$PROJECT_NAME</h1>
      <p>Frontend is running</p>
    </div>
  )
}
EOF
  log "frontend/pages/index.js"

  # Test skeleton for Next.js
  if [ "$FRONTEND_TESTING" = "jest" ]; then
    cat > "$PROJECT_PATH/frontend/jest.config.mjs" << 'EOF'
import nextJest from 'next/jest.js'

const createJestConfig = nextJest({ dir: './' })

const config = {
  testEnvironment: 'jest-environment-jsdom',
  setupFilesAfterSetup: ['<rootDir>/jest.setup.js'],
}

export default createJestConfig(config)
EOF
    log "frontend/jest.config.mjs"

    cat > "$PROJECT_PATH/frontend/jest.setup.js" << 'EOF'
import '@testing-library/jest-dom'
EOF
    log "frontend/jest.setup.js"

    mkdir -p "$PROJECT_PATH/frontend/__tests__"
    cat > "$PROJECT_PATH/frontend/__tests__/index.test.js" << 'EOF'
import { render, screen } from '@testing-library/react'
import Home from '../pages/index'

describe('Home Page', () => {
  it('renders the project name', () => {
    render(<Home />)
    expect(screen.getByText(/frontend/i)).toBeInTheDocument()
  })

  it('renders the welcome message', () => {
    render(<Home />)
    expect(screen.getByText(/Frontend is running/)).toBeInTheDocument()
  })

  it('has correct page structure', () => {
    const { container } = render(<Home />)
    expect(container.querySelector('h1')).toBeTruthy()
  })
})
EOF
    log "frontend/__tests__/index.test.js"
  fi

  # Dockerfile
  cat > "$PROJECT_PATH/frontend/Dockerfile" << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["npm", "start"]
EOF
  log "frontend/Dockerfile"
}

generate_react() {
  if [ "$FRONTEND_TESTING" = "vitest" ]; then
    FRONT_TEST_SCRIPT="vitest run"
    FRONT_DEVDEPS=$',\n    "vitest": "^1.6.0",\n    "@testing-library/react": "^16.0.1",\n    "@testing-library/jest-dom": "^6.4.8",\n    "@testing-library/user-event": "^14.5.0",\n    "jsdom": "^24.0.0"'
  elif [ "$FRONTEND_TESTING" = "jest" ]; then
    FRONT_TEST_SCRIPT="jest"
    FRONT_DEVDEPS=$',\n    "jest": "^29.7.0",\n    "jest-environment-jsdom": "^29.7.0",\n    "@testing-library/react": "^16.0.1",\n    "@testing-library/jest-dom": "^6.4.8",\n    "@types/jest": "^29.5.13"'
  else
    FRONT_TEST_SCRIPT=""
    FRONT_DEVDEPS=""
  fi

  cat > "$PROJECT_PATH/frontend/package.json" << EOF
{
  "name": "$PROJECT_NAME-frontend",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "$FRONT_TEST_SCRIPT"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.0",
    "vite": "^5.0.0"$FRONT_DEVDEPS
  }
}
EOF
  log "frontend/package.json"

  cat > "$PROJECT_PATH/frontend/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF
  log "frontend/index.html"

  cat > "$PROJECT_PATH/frontend/vite.config.js" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
EOF
  log "frontend/vite.config.js"

  mkdir -p "$PROJECT_PATH/frontend/src"
  cat > "$PROJECT_PATH/frontend/src/main.jsx" << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF
  log "frontend/src/main.jsx"

  cat > "$PROJECT_PATH/frontend/src/App.jsx" << EOF
function App() {
  return (
    <div>
      <h1>$PROJECT_NAME</h1>
      <p>Frontend is running</p>
    </div>
  )
}

export default App
EOF
  log "frontend/src/App.jsx"

  cat > "$PROJECT_PATH/frontend/src/index.css" << 'EOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  padding: 2rem;
}
EOF
  log "frontend/src/index.css"

  # Test skeleton for React
  if [ "$FRONTEND_TESTING" = "vitest" ]; then
    cat > "$PROJECT_PATH/frontend/vitest.config.js" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.js'],
  },
})
EOF
    log "frontend/vitest.config.js"

    mkdir -p "$PROJECT_PATH/frontend/src/test"
    cat > "$PROJECT_PATH/frontend/src/test/setup.js" << 'EOF'
import '@testing-library/jest-dom'
EOF
    log "frontend/src/test/setup.js"

    mkdir -p "$PROJECT_PATH/frontend/src/__tests__"
    cat > "$PROJECT_PATH/frontend/src/__tests__/App.test.jsx" << 'EOF'
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import App from '../App'

describe('App Component', () => {
  it('renders without crashing', () => {
    const { container } = render(<App />)
    expect(container).toBeTruthy()
  })

  it('displays the title', () => {
    render(<App />)
    expect(screen.getByText(/frontend/i)).toBeInTheDocument()
  })

  it('displays the welcome message', () => {
    render(<App />)
    expect(screen.getByText('Frontend is running')).toBeInTheDocument()
  })
})
EOF
    log "frontend/src/__tests__/App.test.jsx"
  elif [ "$FRONTEND_TESTING" = "jest" ]; then
    cat > "$PROJECT_PATH/frontend/jest.config.js" << 'EOF'
module.exports = {
  testEnvironment: 'jest-environment-jsdom',
  setupFilesAfterSetup: ['<rootDir>/src/test/setup.js'],
}
EOF
    log "frontend/jest.config.js"

    mkdir -p "$PROJECT_PATH/frontend/src/test"
    cat > "$PROJECT_PATH/frontend/src/test/setup.js" << 'EOF'
import '@testing-library/jest-dom'
EOF
    log "frontend/src/test/setup.js"

    mkdir -p "$PROJECT_PATH/frontend/src/__tests__"
    cat > "$PROJECT_PATH/frontend/src/__tests__/App.test.jsx" << 'EOF'
const { render, screen } = require('@testing-library/react')
const App = require('../App')

describe('App Component', () => {
  it('renders without crashing', () => {
    const { container } = render(<App />)
    expect(container).toBeTruthy()
  })

  it('displays the title', () => {
    render(<App />)
    expect(screen.getByText(/frontend/i)).toBeInTheDocument()
  })
})
EOF
    log "frontend/src/__tests__/App.test.jsx"
  fi

  # Dockerfile
  cat > "$PROJECT_PATH/frontend/Dockerfile" << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
  log "frontend/Dockerfile"
}

generate_vue() {
  if [ "$FRONTEND_TESTING" = "vitest" ]; then
    FRONT_TEST_SCRIPT="vitest run"
    FRONT_DEVDEPS=$',\n    "vitest": "^1.6.0",\n    "@vue/test-utils": "^2.4.6",\n    "jsdom": "^24.0.0"'
  elif [ "$FRONTEND_TESTING" = "jest" ]; then
    FRONT_TEST_SCRIPT="jest"
    FRONT_DEVDEPS=$',\n    "jest": "^29.7.0",\n    "@vue/test-utils": "^2.4.6",\n    "@vue/vue3-jest": "^29.2.0",\n    "babel-jest": "^29.7.0"'
  else
    FRONT_TEST_SCRIPT=""
    FRONT_DEVDEPS=""
  fi

  cat > "$PROJECT_PATH/frontend/package.json" << EOF
{
  "name": "$PROJECT_NAME-frontend",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "$FRONT_TEST_SCRIPT"
  },
  "dependencies": {
    "vue": "^3.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "vite": "^5.0.0"$FRONT_DEVDEPS
  }
}
EOF
  log "frontend/package.json"

  cat > "$PROJECT_PATH/frontend/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>App</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF
  log "frontend/index.html"

  cat > "$PROJECT_PATH/frontend/vite.config.js" << 'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
})
EOF
  log "frontend/vite.config.js"

  mkdir -p "$PROJECT_PATH/frontend/src"
  cat > "$PROJECT_PATH/frontend/src/main.js" << 'EOF'
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
EOF
  log "frontend/src/main.js"

  cat > "$PROJECT_PATH/frontend/src/App.vue" << EOF
<template>
  <div>
    <h1>$PROJECT_NAME</h1>
    <p>Frontend is running</p>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>
EOF
  log "frontend/src/App.vue"

  # Test skeleton for Vue
  if [ "$FRONTEND_TESTING" = "vitest" ]; then
    cat > "$PROJECT_PATH/frontend/vitest.config.js" << 'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    globals: true,
    environment: 'jsdom',
  },
})
EOF
    log "frontend/vitest.config.js"

    mkdir -p "$PROJECT_PATH/frontend/src/__tests__"
    cat > "$PROJECT_PATH/frontend/src/__tests__/App.test.js" << 'EOF'
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import App from '../App.vue'

describe('App Component', () => {
  it('renders the app title', () => {
    const wrapper = mount(App)
    expect(wrapper.text()).toContain('Frontend is running')
  })

  it('renders the welcome message', () => {
    const wrapper = mount(App)
    expect(wrapper.text()).toContain('Frontend is running')
  })

  it('has correct structure', () => {
    const wrapper = mount(App)
    expect(wrapper.find('h1').exists()).toBe(true)
  })
})
EOF
    log "frontend/src/__tests__/App.test.js"
  elif [ "$FRONTEND_TESTING" = "jest" ]; then
    cat > "$PROJECT_PATH/frontend/jest.config.js" << 'EOF'
module.exports = {
  testEnvironment: 'jsdom',
  transform: {
    '^.+\\.vue$': '@vue/vue3-jest',
    '^.+\\.js$': 'babel-jest',
  },
}
EOF
    log "frontend/jest.config.js"

    mkdir -p "$PROJECT_PATH/frontend/src/__tests__"
    cat > "$PROJECT_PATH/frontend/src/__tests__/App.test.js" << 'EOF'
const { mount } = require('@vue/test-utils')
const App = require('../App.vue')

describe('App Component', () => {
  it('renders the welcome message', () => {
    const wrapper = mount(App)
    expect(wrapper.text()).toContain('Frontend is running')
  })
})
EOF
    log "frontend/src/__tests__/App.test.js"
  fi

  # Dockerfile
  cat > "$PROJECT_PATH/frontend/Dockerfile" << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
  log "frontend/Dockerfile"
}

generate_angular() {
  cat > "$PROJECT_PATH/frontend/package.json" << EOF
{
  "name": "$PROJECT_NAME-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build",
    "test": "ng test"
  },
  "dependencies": {
    "@angular/core": "^17.0.0",
    "@angular/platform-browser": "^17.0.0",
    "@angular/platform-browser-dynamic": "^17.0.0",
    "rxjs": "~7.8.0",
    "tslib": "^2.6.0",
    "zone.js": "~0.14.0"
  },
  "devDependencies": {
    "@angular/cli": "^17.0.0",
    "@angular/compiler": "^17.0.0",
    "@angular/compiler-cli": "^17.0.0",
    "jasmine-core": "~5.1.0",
    "karma": "~6.4.0",
    "karma-chrome-launcher": "~3.2.0",
    "karma-jasmine": "~5.1.0",
    "karma-jasmine-html-reporter": "~2.1.0",
    "karma-coverage": "~2.2.0",
    "@angular-devkit/build-angular": "^17.0.0",
    "typescript": "~5.2.0"
  }
}
EOF
  log "frontend/package.json"

  cat > "$PROJECT_PATH/frontend/karma.conf.js" << 'EOF'
module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage'),
      require('@angular-devkit/build-angular/plugins/karma'),
    ],
    client: {
      jasmine: {},
      clearContext: false,
    },
    jasmineHtmlReporter: {
      suppressAll: true,
    },
    coverageReporter: {
      dir: require('path').join(__dirname, './coverage/frontend'),
      subdir: '.',
      reporters: [{ type: 'html' }, { type: 'text-summary' }],
    },
    reporters: ['progress', 'kjhtml'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['Chrome'],
    singleRun: false,
    restartOnFileChange: true,
  })
}
EOF
  log "frontend/karma.conf.js"

  cat > "$PROJECT_PATH/frontend/tsconfig.spec.json" << 'EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./out-tsc/spec",
    "types": ["jasmine"]
  },
  "files": ["src/test.ts"],
  "include": ["src/**/*.spec.ts", "src/**/*.d.ts"]
}
EOF
  log "frontend/tsconfig.spec.json"

  mkdir -p "$PROJECT_PATH/frontend/src/app"
  cat > "$PROJECT_PATH/frontend/src/app/app.component.ts" << EOF
import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = '$PROJECT_NAME';
}
EOF
  log "frontend/src/app/app.component.ts"

  cat > "$PROJECT_PATH/frontend/src/app/app.component.html" << 'EOF'
<div>
  <h1>{{ title }}</h1>
  <p>Frontend is running</p>
</div>
EOF
  log "frontend/src/app/app.component.html"

  cat > "$PROJECT_PATH/frontend/src/app/app.component.css" << 'EOF'
EOF
  log "frontend/src/app/app.component.css"

  cat > "$PROJECT_PATH/frontend/src/app/app.module.ts" << 'EOF'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppComponent } from './app.component';

@NgModule({
  declarations: [AppComponent],
  imports: [BrowserModule],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {}
EOF
  log "frontend/src/app/app.module.ts"

  cat > "$PROJECT_PATH/frontend/src/main.ts" << 'EOF'
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

platformBrowserDynamic().bootstrapModule(AppModule)
  .catch(err => console.error(err));
EOF
  log "frontend/src/main.ts"

  cat > "$PROJECT_PATH/frontend/src/index.html" << 'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Frontend</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <app-root></app-root>
</body>
</html>
EOF
  log "frontend/src/index.html"

  # Test skeleton for Angular
  cat > "$PROJECT_PATH/frontend/src/app/app.component.spec.ts" << 'EOF'
import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';

describe('AppComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [AppComponent],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should have as title', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app.title).toBeTruthy();
  });

  it('should render the title in a h1 tag', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toBeTruthy();
  });
});
EOF
  log "frontend/src/app/app.component.spec.ts"

  cat > "$PROJECT_PATH/frontend/src/test.ts" << 'EOF'
import 'zone.js/testing';
import { getTestBed } from '@angular/core/testing';
import {
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting
} from '@angular/platform-browser-dynamic/testing';

getTestBed().initTestEnvironment(
  BrowserDynamicTestingModule,
  platformBrowserDynamicTesting(),
);
EOF
  log "frontend/src/test.ts"

  # Dockerfile
  cat > "$PROJECT_PATH/frontend/Dockerfile" << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=builder /app/dist/frontend /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
  log "frontend/Dockerfile"
}

generate_svelte() {
  if [ "$FRONTEND_TESTING" = "vitest" ]; then
    FRONT_TEST_SCRIPT="vitest run"
    FRONT_DEVDEPS=$',\n    "vitest": "^1.6.0",\n    "@testing-library/svelte": "^4.1.0",\n    "jsdom": "^24.0.0"'
  else
    FRONT_TEST_SCRIPT=""
    FRONT_DEVDEPS=""
  fi

  cat > "$PROJECT_PATH/frontend/package.json" << EOF
{
  "name": "$PROJECT_NAME-frontend",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview",
    "test": "$FRONT_TEST_SCRIPT"
  },
  "dependencies": {
    "svelte": "^4.2.0"
  },
  "devDependencies": {
    "@sveltejs/vite-plugin-svelte": "^3.0.0",
    "vite": "^5.0.0"$FRONT_DEVDEPS
  }
}
EOF
  log "frontend/package.json"

  cat > "$PROJECT_PATH/frontend/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>App</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF
  log "frontend/index.html"

  cat > "$PROJECT_PATH/frontend/vite.config.js" << 'EOF'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [svelte()],
})
EOF
  log "frontend/vite.config.js"

  cat > "$PROJECT_PATH/frontend/svelte.config.js" << 'EOF'
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte'

export default {
  preprocess: vitePreprocess(),
}
EOF
  log "frontend/svelte.config.js"

  mkdir -p "$PROJECT_PATH/frontend/src"
  cat > "$PROJECT_PATH/frontend/src/main.js" << 'EOF'
import App from './App.svelte'

const app = new App({
  target: document.getElementById('app'),
})

export default app
EOF
  log "frontend/src/main.js"

  cat > "$PROJECT_PATH/frontend/src/App.svelte" << EOF
<script>
  let title = '$PROJECT_NAME'
</script>

<main>
  <h1>{title}</h1>
  <p>Frontend is running</p>
</main>

<style>
  main {
    text-align: center;
    padding: 2rem;
  }
</style>
EOF
  log "frontend/src/App.svelte"

  # Test skeleton for Svelte
  if [ "$FRONTEND_TESTING" = "vitest" ]; then
    cat > "$PROJECT_PATH/frontend/vitest.config.js" << 'EOF'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [svelte({ hot: !process.env.VITEST })],
  test: {
    globals: true,
    environment: 'jsdom',
    include: ['src/**/*.{test,spec}.{js,ts}'],
  },
})
EOF
    log "frontend/vitest.config.js"

    mkdir -p "$PROJECT_PATH/frontend/src/__tests__"
    cat > "$PROJECT_PATH/frontend/src/__tests__/App.test.js" << 'EOF'
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/svelte'
import App from '../App.svelte'

describe('App Component', () => {
  it('renders the title', () => {
    render(App)
    expect(screen.getByText('Frontend is running')).toBeTruthy()
  })

  it('renders the welcome text', () => {
    render(App)
    expect(screen.getByText('Frontend is running')).toBeTruthy()
  })
})
EOF
    log "frontend/src/__tests__/App.test.js"
  fi

  # Dockerfile
  cat > "$PROJECT_PATH/frontend/Dockerfile" << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
  log "frontend/Dockerfile"
}

generate_templ() {
  cat > "$PROJECT_PATH/frontend/go.mod" << EOF
module github.com/yourname/$PROJECT_NAME/frontend

go 1.23

require github.com/a-h/templ v0.3.1020
EOF
  log "frontend/go.mod"
}
