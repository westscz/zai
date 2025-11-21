
all: up
	@echo "Project started successfully!"

TARGET: setup-network
setup-network:
	sh ./scripts/setup-network.sh

TARGET: up
up: setup-network
	docker-compose up -d --build
	@echo ""
	@echo "  Frontend:  http://localhost:3001"
	@echo "  Backend:   http://localhost:8001"
	@echo "  API Docs:  http://localhost:8001/docs"

TARGET: down
down:
	docker-compose down

# Install frontend dependencies
install:
	@echo "Installing frontend dependencies..."
	docker-compose exec frontend npm install

# Reset database (delete all data and recreate)
reset:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "Resetting database..."
	docker-compose down -v
	docker-compose up -d
	@echo "Database reset complete!"

# Open PostgreSQL shell
db-shell:
	docker-compose exec db psql -U zai_user -d zai_db

# Stop services and remove volumes
clean:
	@echo "Stopping services and removing volumes..."
	docker-compose down -v
	@echo "Cleanup complete!"

# Remove all unused Docker resources
prune:
	@echo "Removing unused Docker resources..."
	docker system prune -f
	@echo "Prune complete!"


# Development workflow - restart frontend after code changes
dev-frontend:
	docker-compose restart frontend
	docker-compose logs -f frontend

# Development workflow - restart backend after code changes
dev-backend:
	docker-compose restart backend
	docker-compose logs -f backend

# Export measurements to CSV
export-data:
	@echo "Exporting measurements to measurements.csv..."
	docker-compose exec db psql -U zai_user -d zai_db -c "COPY (SELECT m.id, s.name as series_name, m.value, m.timestamp FROM measurements m JOIN series s ON m.series_id = s.id ORDER BY m.timestamp) TO STDOUT WITH CSV HEADER" > measurements.csv
	@echo "Export complete: measurements.csv"
