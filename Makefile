# Freelens Makefile
# Simple commands to build and run Freelens

.PHONY: help setup clean build build-dev build-app rebuild rebuild-dev start dev fresh-dev kill install

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)Freelens Development Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

setup: ## Setup Node.js and pnpm via nvm/corepack
	@echo "$(CYAN)🔧 Setting up Node environment...$(NC)"
	@. ${HOME}/.nvm/nvm.sh && nvm install
	@. ${HOME}/.nvm/nvm.sh && nvm use && corepack enable && corepack prepare pnpm@latest --activate
	@echo "$(GREEN)✓ Setup complete$(NC)"

install: setup ## Install dependencies
	@echo "$(CYAN)📦 Installing dependencies...$(NC)"
	@. ${HOME}/.nvm/nvm.sh && nvm use && pnpm install
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

clean: ## Clean build artifacts
	@echo "$(CYAN)🧹 Cleaning build artifacts...$(NC)"
	@. ${HOME}/.nvm/nvm.sh && nvm use && NODE_ENV=production pnpm clean
	@echo "$(GREEN)✓ Clean complete$(NC)"

build: ## Build all packages (production)
	@echo "$(CYAN)🏗️  Building all packages...$(NC)"
	@. ${HOME}/.nvm/nvm.sh && nvm use && NODE_ENV=production pnpm build
	@echo "$(GREEN)✓ Build complete$(NC)"

build-dev: ## Build all packages (development)
	@echo "$(CYAN)🏗️  Building all packages (dev mode)...$(NC)"
	@. ${HOME}/.nvm/nvm.sh && nvm use && pnpm build:dev
	@echo "$(GREEN)✓ Development build complete$(NC)"

build-app: ## Build the Electron app bundle
	@echo "$(CYAN)📱 Building Electron app bundle...$(NC)"
	@cd freelens && . ${HOME}/.nvm/nvm.sh && nvm use && NODE_ENV=production pnpm build:app dir
	@echo "$(GREEN)✓ App bundle built$(NC)"

rebuild: clean build build-app ## Clean, build packages, and build app bundle
	@echo "$(GREEN)✓ Rebuild complete$(NC)"

rebuild-dev: clean build-dev ## Clean and build packages in development mode
	@echo "$(GREEN)✓ Development rebuild complete$(NC)"

start: ## Start Freelens (requires prior build)
	@echo "$(CYAN)🚀 Starting Freelens...$(NC)"
	@cd freelens && . ${HOME}/.nvm/nvm.sh && nvm use && pnpm start

dev: ## Run in development mode with hot-reloading
	@echo "$(CYAN)💻 Starting development mode...$(NC)"
	@echo "$(YELLOW)Note: Electron will start after initial webpack build completes$(NC)"
	@. ${HOME}/.nvm/nvm.sh && nvm use && pnpm dev

fresh-dev: kill ## Kill processes and start fresh development mode
	@echo "$(CYAN)💻 Starting fresh development mode...$(NC)"
	@sleep 2
	@. ${HOME}/.nvm/nvm.sh && nvm use && pnpm dev

kill: ## Kill all running Freelens processes
	@echo "$(YELLOW)🔪 Killing Freelens processes...$(NC)"
	@pkill -f Freelens || echo "$(YELLOW)No Freelens processes found$(NC)"
	@pkill -f "webpack.*freelens" || true
	@echo "$(GREEN)✓ Processes killed$(NC)"

restart: kill start ## Kill existing processes and start fresh

rebuild-start: rebuild kill start ## Full rebuild and start

# Quick commands
rs: rebuild-start ## Alias for rebuild-start
