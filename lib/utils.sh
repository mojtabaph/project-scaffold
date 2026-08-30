#!/bin/bash
# lib/utils.sh - Shared helpers

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Functions
info() { echo -e "${CYAN}>>${NC} $1"; }
log()  { echo -e "${GREEN}  [OK]${NC} $1"; }
warn() { echo -e "${YELLOW}  [!]${NC} $1"; }
error() { echo -e "${RED}  [X]${NC} $1"; }
