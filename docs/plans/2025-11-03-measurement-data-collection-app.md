# Measurement Data Collection Application Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a full-stack application for collecting, storing, and visualizing measurement data from multiple series with user authentication, CRUD operations, charts, and optional sensor API support.

**Architecture:** Vue.js SPA frontend with Tailwind CSS for UI, FastAPI backend with REST API (Level 2 maturity), PostgreSQL database for data persistence, JWT authentication, and Chart.js for data visualization. The app supports two user roles (readers/admins) and optional sensor data ingestion via API.

**Tech Stack:**
- Backend: Python 3.11, FastAPI, SQLAlchemy, PostgreSQL, Pydantic, python-jose (JWT), passlib (password hashing)
- Frontend: Vue.js 3, Vite, Tailwind CSS 3, Chart.js, Axios, Pinia (state management)
- Deployment: Docker Compose for local dev, production deployment to cloud (Azure/AWS/GCP)

---

## Phase 1: Database Design & Backend Foundation

### Task 1: Database Schema Design

**Files:**
- Create: `backend/database.py`
- Create: `backend/models.py`
- Create: `backend/schemas.py`
- Create: `database/init.sql`
- Create: `database/seed_data.sql`

**Step 1: Write database models**

Create SQLAlchemy models for users, series, and measurements:

```python
# backend/models.py
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_admin = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class Series(Base):
    __tablename__ = "series"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(String(500))
    min_value = Column(Float, nullable=False)
    max_value = Column(Float, nullable=False)
    color = Column(String(7), default="#3B82F6")  # Hex color code
    icon = Column(String(50), default="chart-line")
    unit = Column(String(20), default="")
    created_at = Column(DateTime, default=datetime.utcnow)
    created_by = Column(Integer, ForeignKey("users.id"))

    measurements = relationship("Measurement", back_populates="series", cascade="all, delete-orphan")
    creator = relationship("User")

class Measurement(Base):
    __tablename__ = "measurements"

    id = Column(Integer, primary_key=True, index=True)
    series_id = Column(Integer, ForeignKey("series.id"), nullable=False, index=True)
    value = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    created_by = Column(Integer, ForeignKey("users.id"))

    series = relationship("Series", back_populates="measurements")
    creator = relationship("User")

class Sensor(Base):
    __tablename__ = "sensors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    api_key = Column(String(64), unique=True, index=True, nullable=False)
    series_id = Column(Integer, ForeignKey("series.id"), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    series = relationship("Series")
```

**Step 2: Create database connection**

```python
# backend/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://zai_user:zai_password@db:5432/zai_db"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

**Step 3: Create Pydantic schemas for validation**

```python
# backend/schemas.py
from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime
from typing import Optional

# User Schemas
class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=100)

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=8, max_length=100)

class UserResponse(UserBase):
    id: int
    is_admin: bool
    created_at: datetime

    class Config:
        from_attributes = True

# Series Schemas
class SeriesBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    min_value: float
    max_value: float
    color: str = Field(default="#3B82F6", pattern="^#[0-9A-Fa-f]{6}$")
    icon: str = Field(default="chart-line", max_length=50)
    unit: str = Field(default="", max_length=20)

    @field_validator('max_value')
    def validate_max_greater_than_min(cls, v, info):
        if 'min_value' in info.data and v <= info.data['min_value']:
            raise ValueError('max_value must be greater than min_value')
        return v

class SeriesCreate(SeriesBase):
    pass

class SeriesUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    color: Optional[str] = Field(None, pattern="^#[0-9A-Fa-f]{6}$")
    icon: Optional[str] = Field(None, max_length=50)
    unit: Optional[str] = Field(None, max_length=20)

class SeriesResponse(SeriesBase):
    id: int
    created_at: datetime
    created_by: Optional[int]

    class Config:
        from_attributes = True

# Measurement Schemas
class MeasurementBase(BaseModel):
    series_id: int
    value: float
    timestamp: Optional[datetime] = None

class MeasurementCreate(MeasurementBase):
    pass

class MeasurementUpdate(BaseModel):
    value: Optional[float] = None
    timestamp: Optional[datetime] = None

class MeasurementResponse(MeasurementBase):
    id: int
    created_by: Optional[int]

    class Config:
        from_attributes = True

# Sensor Schemas
class SensorBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    series_id: int

class SensorCreate(SensorBase):
    pass

class SensorResponse(SensorBase):
    id: int
    api_key: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

# Auth Schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class LoginRequest(BaseModel):
    username: str
    password: str
```

**Step 4: Create SQL initialization scripts**

```sql
-- database/init.sql
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS series (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    min_value FLOAT NOT NULL,
    max_value FLOAT NOT NULL,
    color VARCHAR(7) DEFAULT '#3B82F6',
    icon VARCHAR(50) DEFAULT 'chart-line',
    unit VARCHAR(20) DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS measurements (
    id SERIAL PRIMARY KEY,
    series_id INTEGER NOT NULL REFERENCES series(id) ON DELETE CASCADE,
    value FLOAT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by INTEGER REFERENCES users(id)
);

CREATE INDEX idx_measurements_series_id ON measurements(series_id);
CREATE INDEX idx_measurements_timestamp ON measurements(timestamp);

CREATE TABLE IF NOT EXISTS sensors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    api_key VARCHAR(64) UNIQUE NOT NULL,
    series_id INTEGER NOT NULL REFERENCES series(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sensors_api_key ON sensors(api_key);
```

**Step 5: Create seed data script**

```sql
-- database/seed_data.sql
-- Password is 'admin123' hashed with bcrypt
INSERT INTO users (username, email, hashed_password, is_admin) VALUES
('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYzNBkrJ3zu', TRUE),
('reader', 'reader@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYzNBkrJ3zu', FALSE);

INSERT INTO series (name, description, min_value, max_value, color, icon, unit, created_by) VALUES
('Temperature Sensor 1', 'Living room temperature monitoring', -20.0, 50.0, '#EF4444', 'temperature-high', '°C', 1),
('Humidity Sensor 1', 'Living room humidity monitoring', 0.0, 100.0, '#3B82F6', 'droplet', '%', 1),
('Pressure Sensor', 'Atmospheric pressure', 900.0, 1100.0, '#10B981', 'gauge', 'hPa', 1);

-- Generate sample measurements for last 7 days
INSERT INTO measurements (series_id, value, timestamp, created_by)
SELECT
    1,
    20.0 + (random() * 5),
    NOW() - (interval '1 hour' * generate_series(0, 168)),
    1
FROM generate_series(0, 168);

INSERT INTO measurements (series_id, value, timestamp, created_by)
SELECT
    2,
    45.0 + (random() * 20),
    NOW() - (interval '1 hour' * generate_series(0, 168)),
    1
FROM generate_series(0, 168);

INSERT INTO measurements (series_id, value, timestamp, created_by)
SELECT
    3,
    1013.0 + (random() * 20 - 10),
    NOW() - (interval '1 hour' * generate_series(0, 168)),
    1
FROM generate_series(0, 168);
```

**Step 6: Update requirements.txt**

```txt
# backend/requirements.txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
psycopg2-binary==2.9.9
pydantic[email]==2.5.3
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
```

**Step 7: Commit database schema**

```bash
git add backend/models.py backend/schemas.py backend/database.py database/
git add backend/requirements.txt
git commit -m "feat: add database schema for users, series, measurements, and sensors"
```

---

### Task 2: Authentication & Authorization System

**Files:**
- Create: `backend/auth.py`
- Create: `backend/dependencies.py`
- Modify: `backend/main.py`

**Step 1: Create authentication utilities**

```python
# backend/auth.py
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status
import secrets

SECRET_KEY = secrets.token_urlsafe(32)  # In production, use env variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

def generate_api_key() -> str:
    """Generate a secure API key for sensors"""
    return secrets.token_urlsafe(48)
```

**Step 2: Create dependency functions for auth**

```python
# backend/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import Optional
from backend.database import get_db
from backend.auth import decode_access_token
from backend.models import User

security = HTTPBearer(auto_error=False)

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """Get current user from JWT token (optional - returns None if not authenticated)"""
    if credentials is None:
        return None

    token = credentials.credentials
    payload = decode_access_token(token)
    username: str = payload.get("sub")

    if username is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )

    return user

async def get_current_active_user(
    current_user: Optional[User] = Depends(get_current_user)
) -> User:
    """Require authenticated user"""
    if current_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    return current_user

async def get_current_admin_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """Require admin user"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user
```

**Step 3: Commit authentication system**

```bash
git add backend/auth.py backend/dependencies.py
git commit -m "feat: add JWT authentication and authorization system"
```

---

### Task 3: Backend API Endpoints - Authentication

**Files:**
- Create: `backend/routers/__init__.py`
- Create: `backend/routers/auth.py`
- Modify: `backend/main.py`

**Step 1: Create auth router**

```python
# backend/routers/__init__.py
# Empty file to make routers a package
```

```python
# backend/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.database import get_db
from backend.schemas import UserCreate, UserResponse, LoginRequest, Token, UserUpdate
from backend.models import User
from backend.auth import verify_password, get_password_hash, create_access_token
from backend.dependencies import get_current_active_user
from datetime import timedelta

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user (reader by default)"""
    # Check if username exists
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )

    # Check if email exists
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create new user
    hashed_password = get_password_hash(user_data.password)
    db_user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hashed_password,
        is_admin=False
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user

@router.post("/login", response_model=Token)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """Login and get access token"""
    user = db.query(User).filter(User.username == login_data.username).first()

    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )

    access_token = create_access_token(
        data={"sub": user.username, "admin": user.is_admin}
    )

    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    """Get current user information"""
    return current_user

@router.put("/me", response_model=UserResponse)
def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update current user information (email and/or password)"""
    if user_update.email:
        # Check if email is already taken by another user
        existing = db.query(User).filter(
            User.email == user_update.email,
            User.id != current_user.id
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already in use"
            )
        current_user.email = user_update.email

    if user_update.password:
        current_user.hashed_password = get_password_hash(user_update.password)

    db.commit()
    db.refresh(current_user)

    return current_user
```

**Step 2: Update main.py to include auth router**

```python
# backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.routers import auth

app = FastAPI(
    title="ZAI Measurement Data Collection API",
    description="API for collecting and managing measurement data from multiple series",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)

@app.get("/")
async def root():
    return {"message": "ZAI Measurement Data Collection API"}

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}
```

**Step 3: Commit auth endpoints**

```bash
git add backend/routers/ backend/main.py
git commit -m "feat: add authentication endpoints (register, login, user management)"
```

---

### Task 4: Backend API Endpoints - Series Management

**Files:**
- Create: `backend/routers/series.py`
- Modify: `backend/main.py`

**Step 1: Create series router**

```python
# backend/routers/series.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from backend.database import get_db
from backend.schemas import SeriesCreate, SeriesUpdate, SeriesResponse
from backend.models import Series, User
from backend.dependencies import get_current_user, get_current_admin_user

router = APIRouter(prefix="/api/series", tags=["Series"])

@router.get("/", response_model=List[SeriesResponse])
def get_all_series(
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """Get all series (public endpoint)"""
    series = db.query(Series).order_by(Series.created_at.desc()).all()
    return series

@router.get("/{series_id}", response_model=SeriesResponse)
def get_series_by_id(
    series_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """Get a specific series by ID (public endpoint)"""
    series = db.query(Series).filter(Series.id == series_id).first()
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )
    return series

@router.post("/", response_model=SeriesResponse, status_code=status.HTTP_201_CREATED)
def create_series(
    series_data: SeriesCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Create a new series (admin only)"""
    # Validate min/max
    if series_data.max_value <= series_data.min_value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="max_value must be greater than min_value"
        )

    db_series = Series(
        name=series_data.name,
        description=series_data.description,
        min_value=series_data.min_value,
        max_value=series_data.max_value,
        color=series_data.color,
        icon=series_data.icon,
        unit=series_data.unit,
        created_by=current_user.id
    )
    db.add(db_series)
    db.commit()
    db.refresh(db_series)

    return db_series

@router.put("/{series_id}", response_model=SeriesResponse)
def update_series(
    series_id: int,
    series_update: SeriesUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Update a series (admin only)"""
    series = db.query(Series).filter(Series.id == series_id).first()
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    # Update fields if provided
    update_data = series_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(series, field, value)

    # Validate min/max after update
    if series.max_value <= series.min_value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="max_value must be greater than min_value"
        )

    db.commit()
    db.refresh(series)

    return series

@router.delete("/{series_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_series(
    series_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Delete a series (admin only)"""
    series = db.query(Series).filter(Series.id == series_id).first()
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    db.delete(series)
    db.commit()

    return None
```

**Step 2: Include series router in main.py**

```python
# backend/main.py (add import and include)
from backend.routers import auth, series

# ... existing code ...

app.include_router(auth.router)
app.include_router(series.router)
```

**Step 3: Commit series endpoints**

```bash
git add backend/routers/series.py backend/main.py
git commit -m "feat: add series CRUD endpoints with admin authorization"
```

---

### Task 5: Backend API Endpoints - Measurements Management

**Files:**
- Create: `backend/routers/measurements.py`
- Modify: `backend/main.py`

**Step 1: Create measurements router**

```python
# backend/routers/measurements.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import List, Optional
from datetime import datetime
from backend.database import get_db
from backend.schemas import MeasurementCreate, MeasurementUpdate, MeasurementResponse
from backend.models import Measurement, Series, User
from backend.dependencies import get_current_user, get_current_admin_user

router = APIRouter(prefix="/api/measurements", tags=["Measurements"])

@router.get("/", response_model=List[MeasurementResponse])
def get_measurements(
    series_ids: Optional[str] = Query(None, description="Comma-separated series IDs"),
    start_date: Optional[datetime] = Query(None, description="Start date filter"),
    end_date: Optional[datetime] = Query(None, description="End date filter"),
    limit: int = Query(1000, ge=1, le=10000, description="Maximum number of results"),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """Get measurements with optional filters (public endpoint)"""
    query = db.query(Measurement)

    # Filter by series IDs
    if series_ids:
        ids = [int(id.strip()) for id in series_ids.split(",")]
        query = query.filter(Measurement.series_id.in_(ids))

    # Filter by date range
    if start_date:
        query = query.filter(Measurement.timestamp >= start_date)
    if end_date:
        query = query.filter(Measurement.timestamp <= end_date)

    # Order by timestamp and limit
    measurements = query.order_by(Measurement.timestamp.desc()).limit(limit).all()

    return measurements

@router.get("/{measurement_id}", response_model=MeasurementResponse)
def get_measurement_by_id(
    measurement_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    """Get a specific measurement by ID (public endpoint)"""
    measurement = db.query(Measurement).filter(Measurement.id == measurement_id).first()
    if not measurement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Measurement not found"
        )
    return measurement

@router.post("/", response_model=MeasurementResponse, status_code=status.HTTP_201_CREATED)
def create_measurement(
    measurement_data: MeasurementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Create a new measurement (admin only)"""
    # Validate series exists
    series = db.query(Series).filter(Series.id == measurement_data.series_id).first()
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    # Validate value is within series range
    if not (series.min_value <= measurement_data.value <= series.max_value):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Value must be between {series.min_value} and {series.max_value}"
        )

    db_measurement = Measurement(
        series_id=measurement_data.series_id,
        value=measurement_data.value,
        timestamp=measurement_data.timestamp or datetime.utcnow(),
        created_by=current_user.id
    )
    db.add(db_measurement)
    db.commit()
    db.refresh(db_measurement)

    return db_measurement

@router.put("/{measurement_id}", response_model=MeasurementResponse)
def update_measurement(
    measurement_id: int,
    measurement_update: MeasurementUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Update a measurement (admin only)"""
    measurement = db.query(Measurement).filter(Measurement.id == measurement_id).first()
    if not measurement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Measurement not found"
        )

    # Get series for validation
    series = db.query(Series).filter(Series.id == measurement.series_id).first()

    # Update fields if provided
    if measurement_update.value is not None:
        # Validate value is within series range
        if not (series.min_value <= measurement_update.value <= series.max_value):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Value must be between {series.min_value} and {series.max_value}"
            )
        measurement.value = measurement_update.value

    if measurement_update.timestamp is not None:
        measurement.timestamp = measurement_update.timestamp

    db.commit()
    db.refresh(measurement)

    return measurement

@router.delete("/{measurement_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_measurement(
    measurement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Delete a measurement (admin only)"""
    measurement = db.query(Measurement).filter(Measurement.id == measurement_id).first()
    if not measurement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Measurement not found"
        )

    db.delete(measurement)
    db.commit()

    return None
```

**Step 2: Include measurements router in main.py**

```python
# backend/main.py (add import and include)
from backend.routers import auth, series, measurements

# ... existing code ...

app.include_router(auth.router)
app.include_router(series.router)
app.include_router(measurements.router)
```

**Step 3: Commit measurements endpoints**

```bash
git add backend/routers/measurements.py backend/main.py
git commit -m "feat: add measurements CRUD endpoints with validation"
```

---

### Task 6: Backend API - Sensor Endpoints (Optional Feature)

**Files:**
- Create: `backend/routers/sensors.py`
- Modify: `backend/main.py`

**Step 1: Create sensors router**

```python
# backend/routers/sensors.py
from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from typing import List, Optional
from backend.database import get_db
from backend.schemas import SensorCreate, SensorResponse, MeasurementCreate, MeasurementResponse
from backend.models import Sensor, Series, Measurement, User
from backend.dependencies import get_current_admin_user
from backend.auth import generate_api_key
from datetime import datetime

router = APIRouter(prefix="/api/sensors", tags=["Sensors"])

@router.get("/", response_model=List[SensorResponse])
def get_all_sensors(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Get all registered sensors (admin only)"""
    sensors = db.query(Sensor).order_by(Sensor.created_at.desc()).all()
    return sensors

@router.post("/", response_model=SensorResponse, status_code=status.HTTP_201_CREATED)
def register_sensor(
    sensor_data: SensorCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Register a new sensor (admin only)"""
    # Validate series exists
    series = db.query(Series).filter(Series.id == sensor_data.series_id).first()
    if not series:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Series not found"
        )

    # Generate API key
    api_key = generate_api_key()

    db_sensor = Sensor(
        name=sensor_data.name,
        api_key=api_key,
        series_id=sensor_data.series_id,
        is_active=True
    )
    db.add(db_sensor)
    db.commit()
    db.refresh(db_sensor)

    return db_sensor

@router.delete("/{sensor_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_sensor(
    sensor_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Delete a sensor (admin only)"""
    sensor = db.query(Sensor).filter(Sensor.id == sensor_id).first()
    if not sensor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sensor not found"
        )

    db.delete(sensor)
    db.commit()

    return None

@router.post("/data", response_model=MeasurementResponse, status_code=status.HTTP_201_CREATED)
def submit_sensor_data(
    value: float,
    timestamp: Optional[datetime] = None,
    x_api_key: str = Header(..., alias="X-API-Key"),
    db: Session = Depends(get_db)
):
    """Submit measurement data from sensor (requires API key)"""
    # Validate API key
    sensor = db.query(Sensor).filter(Sensor.api_key == x_api_key).first()
    if not sensor:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key"
        )

    if not sensor.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sensor is not active"
        )

    # Get series for validation
    series = db.query(Series).filter(Series.id == sensor.series_id).first()

    # Validate value is within series range
    if not (series.min_value <= value <= series.max_value):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Value must be between {series.min_value} and {series.max_value}"
        )

    db_measurement = Measurement(
        series_id=sensor.series_id,
        value=value,
        timestamp=timestamp or datetime.utcnow(),
        created_by=None  # Sensor submissions don't have user
    )
    db.add(db_measurement)
    db.commit()
    db.refresh(db_measurement)

    return db_measurement
```

**Step 2: Include sensors router in main.py**

```python
# backend/main.py (add import and include)
from backend.routers import auth, series, measurements, sensors

# ... existing code ...

app.include_router(auth.router)
app.include_router(series.router)
app.include_router(measurements.router)
app.include_router(sensors.router)
```

**Step 3: Commit sensor endpoints**

```bash
git add backend/routers/sensors.py backend/main.py
git commit -m "feat: add sensor registration and data submission endpoints"
```

---

### Task 7: Update Docker Configuration for PostgreSQL

**Files:**
- Modify: `docker-compose.yml`
- Modify: `backend/Dockerfile`
- Create: `.env.example`

**Step 1: Update docker-compose.yml**

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16-alpine
    container_name: zai-postgres
    environment:
      POSTGRES_USER: zai_user
      POSTGRES_PASSWORD: zai_password
      POSTGRES_DB: zai_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/01-init.sql
      - ./database/seed_data.sql:/docker-entrypoint-initdb.d/02-seed.sql
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U zai_user -d zai_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    container_name: fastapi-backend
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    environment:
      - PYTHONUNBUFFERED=1
      - DATABASE_URL=postgresql://zai_user:zai_password@db:5432/zai_db
    networks:
      - app-network
    depends_on:
      db:
        condition: service_healthy

  frontend:
    build: ./frontend
    container_name: vue-frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
```

**Step 2: Create .env.example**

```bash
# .env.example
DATABASE_URL=postgresql://zai_user:zai_password@db:5432/zai_db
SECRET_KEY=your-secret-key-here-change-in-production
```

**Step 3: Commit docker configuration**

```bash
git add docker-compose.yml .env.example
git commit -m "feat: add PostgreSQL database to docker-compose"
```

---

## Phase 2: Frontend Implementation

### Task 8: Frontend Project Setup & Dependencies

**Files:**
- Modify: `frontend/package.json`
- Create: `frontend/src/stores/auth.js`
- Create: `frontend/src/stores/data.js`
- Create: `frontend/src/utils/api.js`
- Create: `frontend/src/router/index.js`

**Step 1: Update package.json with all dependencies**

```json
{
  "name": "frontend",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "dev": "vite --host",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.4.15",
    "axios": "^1.6.5",
    "pinia": "^2.1.7",
    "vue-router": "^4.2.5",
    "chart.js": "^4.4.1",
    "vue-chartjs": "^5.3.0",
    "date-fns": "^3.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.3",
    "vite": "^5.0.11",
    "tailwindcss": "^3.4.1",
    "postcss": "^8.4.33",
    "autoprefixer": "^10.4.17"
  }
}
```

**Step 2: Create API utility with axios configuration**

```javascript
// frontend/src/utils/api.js
import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add token to requests if available
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle 401 errors (token expired)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
```

**Step 3: Create auth store with Pinia**

```javascript
// frontend/src/stores/auth.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../utils/api'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(localStorage.getItem('access_token'))

  const isAuthenticated = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.is_admin || false)

  async function login(username, password) {
    try {
      const response = await api.post('/api/auth/login', { username, password })
      token.value = response.data.access_token
      localStorage.setItem('access_token', token.value)
      await fetchCurrentUser()
      return true
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    }
  }

  async function register(username, email, password) {
    try {
      await api.post('/api/auth/register', { username, email, password })
      return true
    } catch (error) {
      console.error('Registration failed:', error)
      throw error
    }
  }

  async function fetchCurrentUser() {
    try {
      const response = await api.get('/api/auth/me')
      user.value = response.data
      localStorage.setItem('user', JSON.stringify(user.value))
    } catch (error) {
      console.error('Failed to fetch user:', error)
      logout()
    }
  }

  async function updateProfile(updates) {
    try {
      const response = await api.put('/api/auth/me', updates)
      user.value = response.data
      localStorage.setItem('user', JSON.stringify(user.value))
      return true
    } catch (error) {
      console.error('Profile update failed:', error)
      throw error
    }
  }

  function logout() {
    user.value = null
    token.value = null
    localStorage.removeItem('access_token')
    localStorage.removeItem('user')
  }

  // Initialize from localStorage
  const savedUser = localStorage.getItem('user')
  if (savedUser && token.value) {
    try {
      user.value = JSON.parse(savedUser)
      // Verify token is still valid
      fetchCurrentUser().catch(() => logout())
    } catch (e) {
      logout()
    }
  }

  return {
    user,
    token,
    isAuthenticated,
    isAdmin,
    login,
    register,
    logout,
    fetchCurrentUser,
    updateProfile,
  }
})
```

**Step 4: Create data store for series and measurements**

```javascript
// frontend/src/stores/data.js
import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../utils/api'

export const useDataStore = defineStore('data', () => {
  const series = ref([])
  const measurements = ref([])
  const selectedSeriesIds = ref([])
  const dateRange = ref({
    start: null,
    end: null,
  })
  const loading = ref(false)

  async function fetchSeries() {
    try {
      loading.value = true
      const response = await api.get('/api/series/')
      series.value = response.data
      // Select all series by default
      if (selectedSeriesIds.value.length === 0) {
        selectedSeriesIds.value = series.value.map((s) => s.id)
      }
    } catch (error) {
      console.error('Failed to fetch series:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  async function createSeries(seriesData) {
    try {
      const response = await api.post('/api/series/', seriesData)
      series.value.push(response.data)
      return response.data
    } catch (error) {
      console.error('Failed to create series:', error)
      throw error
    }
  }

  async function updateSeries(seriesId, updates) {
    try {
      const response = await api.put(`/api/series/${seriesId}`, updates)
      const index = series.value.findIndex((s) => s.id === seriesId)
      if (index !== -1) {
        series.value[index] = response.data
      }
      return response.data
    } catch (error) {
      console.error('Failed to update series:', error)
      throw error
    }
  }

  async function deleteSeries(seriesId) {
    try {
      await api.delete(`/api/series/${seriesId}`)
      series.value = series.value.filter((s) => s.id !== seriesId)
      selectedSeriesIds.value = selectedSeriesIds.value.filter((id) => id !== seriesId)
    } catch (error) {
      console.error('Failed to delete series:', error)
      throw error
    }
  }

  async function fetchMeasurements() {
    try {
      loading.value = true
      const params = {}

      if (selectedSeriesIds.value.length > 0) {
        params.series_ids = selectedSeriesIds.value.join(',')
      }

      if (dateRange.value.start) {
        params.start_date = dateRange.value.start
      }

      if (dateRange.value.end) {
        params.end_date = dateRange.value.end
      }

      const response = await api.get('/api/measurements/', { params })
      measurements.value = response.data
    } catch (error) {
      console.error('Failed to fetch measurements:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  async function createMeasurement(measurementData) {
    try {
      const response = await api.post('/api/measurements/', measurementData)
      measurements.value.unshift(response.data)
      return response.data
    } catch (error) {
      console.error('Failed to create measurement:', error)
      throw error
    }
  }

  async function updateMeasurement(measurementId, updates) {
    try {
      const response = await api.put(`/api/measurements/${measurementId}`, updates)
      const index = measurements.value.findIndex((m) => m.id === measurementId)
      if (index !== -1) {
        measurements.value[index] = response.data
      }
      return response.data
    } catch (error) {
      console.error('Failed to update measurement:', error)
      throw error
    }
  }

  async function deleteMeasurement(measurementId) {
    try {
      await api.delete(`/api/measurements/${measurementId}`)
      measurements.value = measurements.value.filter((m) => m.id !== measurementId)
    } catch (error) {
      console.error('Failed to delete measurement:', error)
      throw error
    }
  }

  function toggleSeriesSelection(seriesId) {
    const index = selectedSeriesIds.value.indexOf(seriesId)
    if (index === -1) {
      selectedSeriesIds.value.push(seriesId)
    } else {
      selectedSeriesIds.value.splice(index, 1)
    }
  }

  function setDateRange(start, end) {
    dateRange.value = { start, end }
  }

  return {
    series,
    measurements,
    selectedSeriesIds,
    dateRange,
    loading,
    fetchSeries,
    createSeries,
    updateSeries,
    deleteSeries,
    fetchMeasurements,
    createMeasurement,
    updateMeasurement,
    deleteMeasurement,
    toggleSeriesSelection,
    setDateRange,
  }
})
```

**Step 5: Create router configuration**

```javascript
// frontend/src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('../views/HomeView.vue'),
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('../views/RegisterView.vue'),
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('../views/DashboardView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('../views/ProfileView.vue'),
    meta: { requiresAuth: true },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
  } else {
    next()
  }
})

export default router
```

**Step 6: Update main.js**

```javascript
// frontend/src/main.js
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import './style.css'
import App from './App.vue'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.mount('#app')
```

**Step 7: Commit frontend setup**

```bash
git add frontend/package.json frontend/src/stores/ frontend/src/utils/ frontend/src/router/
git add frontend/src/main.js
git commit -m "feat: add frontend stores, router, and API configuration"
```

---

### Task 9: Frontend Components - Authentication Views

**Files:**
- Create: `frontend/src/views/LoginView.vue`
- Create: `frontend/src/views/RegisterView.vue`
- Create: `frontend/src/components/AuthLayout.vue`

**Step 1: Create auth layout component**

```vue
<!-- frontend/src/components/AuthLayout.vue -->
<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 max-w-md w-full">
      <div class="text-center mb-6">
        <h1 class="text-3xl font-bold text-gray-800 mb-2">ZAI Measurements</h1>
        <p class="text-gray-600">{{ subtitle }}</p>
      </div>

      <slot></slot>
    </div>
  </div>
</template>

<script setup>
defineProps({
  subtitle: {
    type: String,
    default: 'Data Collection System',
  },
})
</script>
```

**Step 2: Create login view**

```vue
<!-- frontend/src/views/LoginView.vue -->
<template>
  <AuthLayout subtitle="Sign in to your account">
    <form @submit.prevent="handleLogin" class="space-y-4">
      <div v-if="error" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
        <p class="text-red-800 text-sm">{{ error }}</p>
      </div>

      <div>
        <label for="username" class="block text-sm font-medium text-gray-700 mb-1">
          Username
        </label>
        <input
          id="username"
          v-model="username"
          type="text"
          required
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="Enter your username"
        />
      </div>

      <div>
        <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
          Password
        </label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="Enter your password"
        />
      </div>

      <button
        type="submit"
        :disabled="loading"
        class="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-md transition duration-200"
      >
        {{ loading ? 'Signing in...' : 'Sign In' }}
      </button>

      <div class="text-center text-sm text-gray-600">
        Don't have an account?
        <router-link to="/register" class="text-indigo-600 hover:text-indigo-700 font-medium">
          Register
        </router-link>
      </div>

      <div class="text-center text-sm text-gray-600">
        <router-link to="/" class="text-indigo-600 hover:text-indigo-700 font-medium">
          Continue as guest
        </router-link>
      </div>
    </form>
  </AuthLayout>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AuthLayout from '../components/AuthLayout.vue'

const router = useRouter()
const authStore = useAuthStore()

const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function handleLogin() {
  loading.value = true
  error.value = ''

  try {
    await authStore.login(username.value, password.value)
    router.push('/dashboard')
  } catch (err) {
    error.value = err.response?.data?.detail || 'Login failed. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>
```

**Step 3: Create register view**

```vue
<!-- frontend/src/views/RegisterView.vue -->
<template>
  <AuthLayout subtitle="Create a new account">
    <form @submit.prevent="handleRegister" class="space-y-4">
      <div v-if="error" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
        <p class="text-red-800 text-sm">{{ error }}</p>
      </div>

      <div v-if="success" class="bg-green-50 border-l-4 border-green-500 p-4 rounded">
        <p class="text-green-800 text-sm">Registration successful! Redirecting to login...</p>
      </div>

      <div>
        <label for="username" class="block text-sm font-medium text-gray-700 mb-1">
          Username
        </label>
        <input
          id="username"
          v-model="username"
          type="text"
          required
          minlength="3"
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="Choose a username"
        />
      </div>

      <div>
        <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
          Email
        </label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="your@email.com"
        />
      </div>

      <div>
        <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
          Password
        </label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          minlength="8"
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="At least 8 characters"
        />
      </div>

      <div>
        <label for="confirmPassword" class="block text-sm font-medium text-gray-700 mb-1">
          Confirm Password
        </label>
        <input
          id="confirmPassword"
          v-model="confirmPassword"
          type="password"
          required
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
          placeholder="Repeat your password"
        />
      </div>

      <button
        type="submit"
        :disabled="loading"
        class="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white font-semibold py-3 px-6 rounded-md transition duration-200"
      >
        {{ loading ? 'Creating account...' : 'Create Account' }}
      </button>

      <div class="text-center text-sm text-gray-600">
        Already have an account?
        <router-link to="/login" class="text-indigo-600 hover:text-indigo-700 font-medium">
          Sign in
        </router-link>
      </div>
    </form>
  </AuthLayout>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AuthLayout from '../components/AuthLayout.vue'

const router = useRouter()
const authStore = useAuthStore()

const username = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const error = ref('')
const success = ref(false)

async function handleRegister() {
  loading.value = true
  error.value = ''

  if (password.value !== confirmPassword.value) {
    error.value = 'Passwords do not match'
    loading.value = false
    return
  }

  try {
    await authStore.register(username.value, email.value, password.value)
    success.value = true
    setTimeout(() => {
      router.push('/login')
    }, 2000)
  } catch (err) {
    error.value = err.response?.data?.detail || 'Registration failed. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>
```

**Step 4: Commit authentication views**

```bash
git add frontend/src/views/LoginView.vue frontend/src/views/RegisterView.vue
git add frontend/src/components/AuthLayout.vue
git commit -m "feat: add login and registration views"
```

---

### Task 10: Frontend Components - Main Dashboard Layout

**Files:**
- Create: `frontend/src/views/HomeView.vue`
- Create: `frontend/src/views/DashboardView.vue`
- Create: `frontend/src/components/Navigation.vue`
- Modify: `frontend/src/App.vue`

**Step 1: Create navigation component**

```vue
<!-- frontend/src/components/Navigation.vue -->
<template>
  <nav class="bg-white shadow-md print:hidden">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between h-16">
        <div class="flex items-center">
          <router-link to="/" class="text-xl font-bold text-indigo-600">
            ZAI Measurements
          </router-link>

          <div class="ml-10 flex space-x-4">
            <router-link
              to="/"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              View Data
            </router-link>

            <router-link
              v-if="authStore.isAuthenticated"
              to="/dashboard"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              Dashboard
            </router-link>
          </div>
        </div>

        <div class="flex items-center space-x-4">
          <template v-if="authStore.isAuthenticated">
            <span class="text-sm text-gray-700">
              {{ authStore.user?.username }}
              <span v-if="authStore.isAdmin" class="text-xs bg-indigo-100 text-indigo-800 px-2 py-1 rounded ml-1">
                Admin
              </span>
            </span>

            <router-link
              to="/profile"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              Profile
            </router-link>

            <button
              @click="handleLogout"
              class="bg-gray-200 hover:bg-gray-300 text-gray-800 px-4 py-2 rounded-md text-sm font-medium transition"
            >
              Logout
            </button>
          </template>

          <template v-else>
            <router-link
              to="/login"
              class="text-gray-700 hover:text-indigo-600 px-3 py-2 rounded-md text-sm font-medium"
            >
              Login
            </router-link>

            <router-link
              to="/register"
              class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium transition"
            >
              Register
            </router-link>
          </template>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

function handleLogout() {
  authStore.logout()
  router.push('/')
}
</script>
```

**Step 2: Update App.vue**

```vue
<!-- frontend/src/App.vue -->
<template>
  <div id="app" class="min-h-screen bg-gray-50">
    <Navigation />
    <main>
      <router-view />
    </main>
  </div>
</template>

<script setup>
import Navigation from './components/Navigation.vue'
</script>
```

**Step 3: Create home view (public data viewing)**

```vue
<!-- frontend/src/views/HomeView.vue -->
<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Measurement Data Viewer</h1>
      <p class="text-gray-600">Browse and visualize measurement data from all series</p>
    </div>

    <div v-if="dataStore.loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      <p class="mt-4 text-gray-600">Loading data...</p>
    </div>

    <div v-else>
      <!-- Placeholder for chart and table components (to be created in next tasks) -->
      <div class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Chart will be here</h2>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Table will be here</h2>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useDataStore } from '../stores/data'

const dataStore = useDataStore()

onMounted(async () => {
  await dataStore.fetchSeries()
  await dataStore.fetchMeasurements()
})
</script>
```

**Step 4: Create dashboard view stub**

```vue
<!-- frontend/src/views/DashboardView.vue -->
<template>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Admin Dashboard</h1>
      <p class="text-gray-600">Manage series and measurements</p>
    </div>

    <div v-if="!authStore.isAdmin" class="bg-yellow-50 border-l-4 border-yellow-500 p-4 rounded">
      <p class="text-yellow-800">You need admin privileges to access this page.</p>
    </div>

    <div v-else>
      <!-- Dashboard content will be added in next tasks -->
      <p class="text-gray-600">Dashboard components coming soon...</p>
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
</script>
```

**Step 5: Commit navigation and layout**

```bash
git add frontend/src/components/Navigation.vue frontend/src/App.vue
git add frontend/src/views/HomeView.vue frontend/src/views/DashboardView.vue
git commit -m "feat: add navigation and main layout components"
```

---

This plan continues with Tasks 11-20 covering:
- Chart component with Chart.js
- Data table component
- Series management UI
- Measurement management UI
- Filters and date range selection
- Print styling with CSS media queries
- Profile view
- Sensors management (optional)
- Testing and deployment
- Documentation

Would you like me to continue with the remaining tasks, or would you prefer to start implementing these tasks first?

---

## Plan Completion

Plan saved to `docs/plans/2025-11-03-measurement-data-collection-app.md`.

**Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration with quality gates

**2. Parallel Session (separate)** - Open new session with executing-plans skill, batch execution with review checkpoints

**Which approach would you prefer?**
