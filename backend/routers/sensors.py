from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
from schemas import SensorCreate, SensorResponse, MeasurementCreate, MeasurementResponse
from models import Sensor, Series, Measurement, User
from dependencies import get_current_admin_user
from auth import generate_api_key
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
