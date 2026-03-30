# Makefile — Nipanze development shortcuts
# Usage: make <target>

.PHONY: help setup start stop reset test test-unit test-integration \
        gen clean build-apk build-web deploy-functions

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

setup: ## Install Flutter deps + run code gen
	flutter pub get
	dart run build_runner build --delete-conflicting-outputs

start: ## Start Supabase local stack (requires Docker)
	supabase start

stop: ## Stop Supabase local stack
	supabase stop

reset: ## Reset local DB and reload schema + seeds
	supabase db reset
	psql "postgresql://postgres:postgres@localhost:54322/postgres" -f schema.sql
	psql "postgresql://postgres:postgres@localhost:54322/postgres" -f seed.sql
	psql "postgresql://postgres:postgres@localhost:54322/postgres" -f seed_patch.sql
	@echo "✅ Local stack reset and seeded"

apply-migrations: ## Apply all migration files to local stack
	for f in supabase/migrations/*.sql; do \
		echo "Applying $$f..."; \
		psql "postgresql://postgres:postgres@localhost:54322/postgres" -f "$$f"; \
	done

# ---------------------------------------------------------------------------
# Testing
# ---------------------------------------------------------------------------

test: ## Run all unit + widget tests
	flutter test

test-unit: ## Run only unit tests (fast, no local stack needed)
	flutter test test/

test-integration: ## Run integration tests (local stack must be running)
	flutter test integration_test/

test-coverage: ## Run tests with coverage report
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html
	@echo "Coverage report: coverage/html/index.html"

test-bid-validator: ## Run bid validator unit tests only
	flutter test test/features/bids/bid_validator_test.dart

test-auth-bloc: ## Run auth bloc unit tests only
	flutter test test/features/auth/auth_bloc_test.dart

# ---------------------------------------------------------------------------
# Code generation
# ---------------------------------------------------------------------------

gen: ## Run build_runner (generates DI, JSON serialization)
	dart run build_runner build --delete-conflicting-outputs

gen-watch: ## Run build_runner in watch mode
	dart run build_runner watch --delete-conflicting-outputs

# ---------------------------------------------------------------------------
# Linting
# ---------------------------------------------------------------------------

lint: ## Run flutter analyze
	flutter analyze

fix: ## Auto-fix lint issues
	dart fix --apply

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

build-apk: ## Build release APK
	flutter build apk --release

build-web: ## Build release web
	flutter build web --release

build-appbundle: ## Build release App Bundle for Play Store
	flutter build appbundle --release

# ---------------------------------------------------------------------------
# Supabase Edge Functions (Stage 4)
# ---------------------------------------------------------------------------

serve-accept-bid: ## Serve accept-bid function locally
	supabase functions serve accept-bid --env-file .env.local

deploy-accept-bid: ## Deploy accept-bid to production
	supabase functions deploy accept-bid

deploy-functions: ## Deploy all Edge Functions
	supabase functions deploy accept-bid
	supabase functions deploy send-notification
	supabase functions deploy place-bid
	supabase functions deploy mock-top-up

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clean: ## Clean Flutter build artifacts
	flutter clean
	flutter pub get
