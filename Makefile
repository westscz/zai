
all: up
	@echo "Project started successfully!"

.PHONY: setup-network
setup-network:
	sh ./scripts/setup-network.sh

.PHONY: up
up: setup-network
	docker-compose up -d --build
	@echo ""
	@echo "  Frontend:  http://localhost:3001"
	@echo "  Backend:   http://localhost:8001"
	@echo "  API Docs:  http://localhost:8001/docs"

.PHONY: down
down:
	docker-compose down

.PHONY: down-all
down-all:
	docker kill $(docker ps -q)

.PHONY: status
status:
	docker-compose ps

.PHONY: reset
reset:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "Resetting database..."
	docker-compose down -v
	docker-compose up -d
	@echo "Database reset complete!"

.PHONY: clean
clean:
# 	docker-compose down -v
	rm -rf backend/__pycache__
	rm -rf frontend/node_modules

.PHONY: prune
prune: clean
	docker system prune -f

.PHONY: docs
docs:
	typst compile docs/docs.typ
