# 📏 measures

Full-stack application for collecting, storing, and visualizing measurement data from multiple series with user authentication, CRUD operations, interactive charts, and sensor API support.

## 📋 Features

### Core Functionality
- **Multi-Series Data Management** - Create and manage multiple measurement series with customizable parameters
- **Real-time Data Visualization** - Interactive Chart.js charts with time-range selection (24h, 7d, 30d, all)
- **User Authentication** - JWT-based auth with role-based access control (Admin/Reader)
- **RESTful API** - Level 2 REST API with comprehensive Swagger documentation
- **Sensor Integration** - API endpoints for IoT sensors to submit measurements via API keys
- **Print-Friendly Reports** - CSS media queries for professional printed reports

### User Roles
- **Admin** - Full CRUD access to series, measurements, and sensors
- **Reader** - Read-only access to view data and charts
- **Public** - Access to view charts and data tables (no authentication required)

## 🛠 Technology Stack

### Backend
- **Python 3.11** with FastAPI
- **PostgreSQL 16** for data persistence
- **SQLAlchemy** ORM with Pydantic validation
- **JWT Authentication** with bcrypt password hashing
- **Docker** containerization

### Frontend
- **Vue.js 3** with Composition API
- **Vite** for fast development and building
- **Tailwind CSS 3** for responsive design
- **Chart.js** for data visualization
- **Pinia** for state management
- **Axios** for HTTP requests

## 🚀 Quick Start

### Prerequisites
- Docker
- Docker Compose

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd zai
```

2. Start all services:
```bash
docker-compose up --build
```

3. Access the applications:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

### Default Credentials

**Admin Account:**
```
Username: admin
Password: admin123
```

**Reader Account:**
```
Username: reader
Password: admin123
```

## 📚 User Guide

### For All Users (Public Access)

#### Viewing Data
1. Navigate to http://localhost:3000/
2. Use the **series filter** checkboxes to select which series to display
3. Choose a **time range** (24h, 7d, 30d, or All)
4. View the **interactive chart** with tooltips
5. Browse the **data table** with pagination
6. Click **"Print Report"** to generate a printer-friendly version

### For Readers (Authenticated)

#### Logging In
1. Click **"Login"** in the navigation bar
2. Enter your credentials
3. Access your profile to change email or password

### For Admins (Full Access)

#### Managing Series
1. Log in as admin
2. Navigate to **Dashboard**
3. In the **Series Management** panel:
   - Click **"+ Create Series"** to add a new series
   - Fill in:
     * Name (e.g., "Temperature Sensor 1")
     * Description (optional)
     * Min/Max values for validation
     * Color (use color picker)
     * Unit (e.g., °C, %, hPa)
     * Icon name (optional)
   - Click **"Edit"** to modify existing series
   - Click **"Delete"** to remove a series (⚠️ also deletes all measurements)

#### Managing Measurements
1. In the **Measurement Management** panel:
   - Click **"+ Add Measurement"** to add data manually
   - Use **filters** to find specific measurements:
     * Filter by series
     * Filter by date range
   - Click **"Edit"** to modify values or timestamps
   - Click **"Delete"** to remove measurements
   - Use **pagination** to browse large datasets

#### Managing Sensors (IoT Integration)
1. In the **Sensors Management** panel:
   - Click **"+ Register Sensor"** to create a new sensor
   - Select the series this sensor will submit data to
   - **Save the API key** - it's shown only once!
   - Click **"API Doc"** to view integration examples:
     * cURL example
     * Python example
     * Request/response format
   - Toggle **eye icon** to show/hide API keys
   - Click **copy icon** to copy API key to clipboard
   - Click **"Delete"** to remove a sensor

## 🔌 API Usage

### Authentication

#### Register New User
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "email": "user@example.com",
    "password": "securepass123"
  }'
```

#### Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

Response:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer"
}
```

### Sensor Data Submission

Once you've registered a sensor and obtained an API key:

```bash
curl -X POST http://localhost:8000/api/sensors/data \
  -H "X-API-Key: YOUR_SENSOR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "value": 23.5,
    "timestamp": "2025-01-04T12:00:00Z"
  }'
```

**Python Example:**
```python
import requests
from datetime import datetime

# Submit measurement
response = requests.post(
    'http://localhost:8000/api/sensors/data',
    headers={'X-API-Key': 'YOUR_SENSOR_API_KEY'},
    json={
        'value': 23.5,
        'timestamp': datetime.utcnow().isoformat() + 'Z'  # Optional
    }
)

print(response.json())
```

**Arduino/ESP32 Example:**
```cpp
#include <HTTPClient.h>
#include <ArduinoJson.h>

void sendMeasurement(float value) {
  HTTPClient http;
  http.begin("http://YOUR_SERVER:8000/api/sensors/data");
  http.addHeader("X-API-Key", "YOUR_SENSOR_API_KEY");
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<200> doc;
  doc["value"] = value;

  String requestBody;
  serializeJson(doc, requestBody);

  int httpResponseCode = http.POST(requestBody);
  http.end();
}
```

### API Documentation

Complete API documentation is available at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🗄 Database Schema

### Tables

#### users
- `id` - Primary key
- `username` - Unique username
- `email` - Unique email
- `hashed_password` - Bcrypt hashed password
- `is_admin` - Admin flag
- `created_at` - Creation timestamp

#### series
- `id` - Primary key
- `name` - Series name
- `description` - Optional description
- `min_value` / `max_value` - Value range for validation
- `color` - Hex color code for charts (#RRGGBB)
- `icon` - Icon identifier
- `unit` - Unit of measurement
- `created_by` - Foreign key to users
- `created_at` - Creation timestamp

#### measurements
- `id` - Primary key
- `series_id` - Foreign key to series
- `value` - Measurement value (validated against series range)
- `timestamp` - Measurement timestamp
- `created_by` - Foreign key to users (null for sensor submissions)

#### sensors
- `id` - Primary key
- `name` - Sensor identifier
- `api_key` - Unique API key for authentication
- `series_id` - Foreign key to series
- `is_active` - Active status
- `created_at` - Registration timestamp

## 🧪 Testing

### Manual Testing Checklist

**Public Access:**
- [ ] Load homepage without login
- [ ] View charts and tables
- [ ] Filter by series (checkboxes)
- [ ] Change time range
- [ ] Print report (Ctrl+P / Cmd+P)

**Authentication:**
- [ ] Register new user
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (should fail)
- [ ] Update profile (email/password)
- [ ] Logout

**Admin - Series:**
- [ ] Create new series
- [ ] Edit existing series
- [ ] Delete series
- [ ] Validate min < max value

**Admin - Measurements:**
- [ ] Add measurement manually
- [ ] Edit measurement
- [ ] Delete measurement
- [ ] Filter by series
- [ ] Filter by date range
- [ ] Pagination works

**Admin - Sensors:**
- [ ] Register new sensor
- [ ] Copy API key
- [ ] View API documentation
- [ ] Submit data via API (use cURL or Python)
- [ ] Delete sensor

## 🔧 Development

### Project Structure
```
zai/
├── backend/
│   ├── routers/          # API route handlers
│   │   ├── auth.py       # Authentication endpoints
│   │   ├── series.py     # Series CRUD
│   │   ├── measurements.py  # Measurements CRUD
│   │   └── sensors.py    # Sensor management
│   ├── models.py         # SQLAlchemy models
│   ├── schemas.py        # Pydantic schemas
│   ├── database.py       # Database connection
│   ├── auth.py           # JWT utilities
│   ├── dependencies.py   # Dependency injection
│   ├── main.py           # FastAPI app
│   ├── requirements.txt  # Python dependencies
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── components/   # Vue components
│   │   │   ├── MeasurementChart.vue
│   │   │   ├── MeasurementTable.vue
│   │   │   ├── SeriesFilter.vue
│   │   │   ├── SeriesManagement.vue
│   │   │   ├── MeasurementManagement.vue
│   │   │   └── SensorsManagement.vue
│   │   ├── views/        # Page components
│   │   │   ├── HomeView.vue
│   │   │   ├── DashboardView.vue
│   │   │   ├── LoginView.vue
│   │   │   ├── RegisterView.vue
│   │   │   └── ProfileView.vue
│   │   ├── stores/       # Pinia stores
│   │   │   ├── auth.js   # Authentication state
│   │   │   └── data.js   # Data management
│   │   ├── router/       # Vue Router
│   │   ├── utils/        # Utilities
│   │   │   └── api.js    # Axios configuration
│   │   ├── style.css     # Tailwind CSS
│   │   ├── print.css     # Print media queries
│   │   └── main.js       # Entry point
│   ├── package.json
│   └── Dockerfile
├── database/
│   ├── init.sql          # Database initialization
│   └── seed_data.sql     # Sample data
├── docker-compose.yml
└── README.md
```

### Running Without Docker

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

**Database:**
Set up PostgreSQL locally and update `DATABASE_URL` in backend/.env

### Environment Variables

Create `.env` file in backend/:
```env
DATABASE_URL=postgresql://measures_user:measures_password@measures-db:5432/measures_db
SECRET_KEY=your-secret-key-change-in-production
```

## 📊 Sample Data

The application comes with pre-populated sample data:

- **3 Series:**
  - Temperature Sensor 1 (-20°C to 50°C)
  - Humidity Sensor 1 (0% to 100%)
  - Pressure Sensor (900 hPa to 1100 hPa)

- **~500 Measurements** (169 per series, covering last 7 days)

- **2 Users:**
  - admin (admin privileges)
  - reader (read-only access)

## 🛡 Security Features

- **Password Hashing** - Bcrypt with salt
- **JWT Tokens** - Secure token-based authentication
- **API Key Authentication** - Separate auth for sensors
- **CORS Configuration** - Configurable cross-origin policies
- **Input Validation** - Pydantic schemas for all inputs
- **SQL Injection Protection** - SQLAlchemy ORM
- **XSS Protection** - Vue.js automatic escaping

## 🚢 Production Deployment

### Recommendations

1. **Security:**
   - Change default admin password
   - Use strong SECRET_KEY (32+ random characters)
   - Enable HTTPS/SSL
   - Configure CORS to allow only specific origins
   - Use environment variables for sensitive data

2. **Database:**
   - Use managed PostgreSQL (AWS RDS, Azure Database, etc.)
   - Enable automated backups
   - Configure connection pooling

3. **Application:**
   - Use production WSGI server (Gunicorn/Uvicorn workers)
   - Enable logging and monitoring
   - Set up reverse proxy (Nginx/Traefik)
   - Configure rate limiting

4. **Infrastructure:**
   - Use container orchestration (Kubernetes/Docker Swarm)
   - Set up load balancing
   - Configure auto-scaling
   - Enable health checks

### Docker Compose Production

Update `docker-compose.yml`:
```yaml
services:
  backend:
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - DATABASE_URL=${DATABASE_URL}
    restart: unless-stopped

  frontend:
    environment:
      - VITE_API_URL=https://your-domain.com
    restart: unless-stopped

  db:
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
```

## 📝 License

This project is for educational purposes (ZAI course project).

## 🤝 Contributing

This is a university project. For questions or suggestions, please contact the project maintainer.

## 📧 Support

For issues or questions:
1. Check the API documentation at http://localhost:8000/docs
2. Review the browser console for frontend errors
3. Check Docker logs: `docker-compose logs -f [service-name]`

---

**Built with ❤️ for ZAI Course 2025**

🤖 Generated with [Claude Code](https://claude.com/claude-code)
