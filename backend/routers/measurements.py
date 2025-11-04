from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import List, Optional
from datetime import datetime
from database import get_db
from schemas import MeasurementCreate, MeasurementUpdate, MeasurementResponse
from models import Measurement, Series, User
from dependencies import get_current_user, get_current_admin_user

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
