# ZAI Measurement Data Collection System - Makefile
# Usage: make [target]

.PHONY: help up down restart logs build clean reset install test status shell-backend shell-frontend shell-db

# Default target
help:
	@echo "ZAI Project Management Commands"
	@echo "================================"
	@echo ""
	@echo "Basic Commands:"
	@echo "  make up        - Start all services"
	@echo "  make down      - Stop all services"
	@echo "  make restart   - Restart all services"
	@echo "  make logs      - Show logs from all services"
	@echo "  make status    - Show service status"
	@echo ""
	@echo "Build & Install:"
	@echo "  make build     - Build/rebuild containers"
	@echo "  make install   - Install frontend dependencies"
	@echo ""
	@echo "Database:"
	@echo "  make reset     - Reset database (delete all data)"
	@echo "  make db-shell  - Open PostgreSQL shell"
	@echo ""
	@echo "Development:"
	@echo "  make shell-backend   - Open shell in backend container"
	@echo "  make shell-frontend  - Open shell in frontend container"
	@echo "  make logs-backend    - Show backend logs"
	@echo "  make logs-frontend   - Show frontend logs"
	@echo "  make logs-db         - Show database logs"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean     - Stop services and remove volumes"
	@echo "  make prune     - Remove all unused Docker resources"
	@echo ""
	@echo "URLs:"
	@echo "  Frontend:  http://localhost:3000"
	@echo "  Backend:   http://localhost:8000"
	@echo "  API Docs:  http://localhost:8000/docs"

# Start all services
up:
	@echo "Starting all services..."
	docker-compose up -d
	@echo ""
	@echo "Services started!"
	@echo "  Frontend:  http://localhost:3000"
	@echo "  Backend:   http://localhost:8000"
	@echo "  API Docs:  http://localhost:8000/docs"

# Stop all services
down:
	@echo "Stopping all services..."
	docker-compose down

# Restart all services
restart:
	@echo "Restarting all services..."
	docker-compose restart

# Show logs from all services
logs:
	docker-compose logs -f

# Show logs from specific services
logs-backend:
	docker-compose logs -f backend

logs-frontend:
	docker-compose logs -f frontend

logs-db:
	docker-compose logs -f db

# Build/rebuild containers
build:
	@echo "Building containers..."
	docker-compose build

# Install frontend dependencies
install:
	@echo "Installing frontend dependencies..."
	docker-compose exec frontend npm install

# Show service status
status:
	docker-compose ps

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

# Open shell in backend container
shell-backend:
	docker-compose exec backend /bin/sh

# Open shell in frontend container
shell-frontend:
	docker-compose exec frontend /bin/sh

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

# Quick start (build and run)
start: build up
	@echo "Project started successfully!"

# Development workflow - restart frontend after code changes
dev-frontend:
	docker-compose restart frontend
	docker-compose logs -f frontend

# Development workflow - restart backend after code changes
dev-backend:
	docker-compose restart backend
	docker-compose logs -f backend

# Show database statistics
db-stats:
	@echo "Database Statistics:"
	@echo "==================="
	docker-compose exec db psql -U zai_user -d zai_db -c "SELECT 'Users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'Series', COUNT(*) FROM series UNION ALL SELECT 'Measurements', COUNT(*) FROM measurements UNION ALL SELECT 'Sensors', COUNT(*) FROM sensors;"

# Export measurements to CSV
export-data:
	@echo "Exporting measurements to measurements.csv..."
	docker-compose exec db psql -U zai_user -d zai_db -c "COPY (SELECT m.id, s.name as series_name, m.value, m.timestamp FROM measurements m JOIN series s ON m.series_id = s.id ORDER BY m.timestamp) TO STDOUT WITH CSV HEADER" > measurements.csv
	@echo "Export complete: measurements.csv"

# Health check
health:
	@echo "Health Check:"
	@echo "============="
	@curl -s http://localhost:8000/api/health | python3 -c "import sys, json; data=json.load(sys.stdin); print('Backend: ' + data.get('status', 'unknown'))" 2>/dev/null || echo "Backend: not responding"
	@curl -s http://localhost:3000 > /dev/null 2>&1 && echo "Frontend: healthy" || echo "Frontend: not responding"
	@docker-compose exec db pg_isready -U zai_user -d zai_db > /dev/null 2>&1 && echo "Database: healthy" || echo "Database: not responding"
