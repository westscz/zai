
all: up
	@echo "Project started successfully!"

setup-network:
	sh ./scripts/setup-network.sh

up: setup-network
	docker-compose up -d --build
	@echo ""
	@echo "  Frontend:  http://localhost:3001"
	@echo "  Backend:   http://localhost:8001"
	@echo "  API Docs:  http://localhost:8001/docs"

down:
	docker-compose down

reset:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "Resetting database..."
	docker-compose down -v
	docker-compose up -d
	@echo "Database reset complete!"

clean:
	docker-compose down -v

prune: clean
	docker system prune -f
