from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
from schemas import SeriesCreate, SeriesUpdate, SeriesResponse
from models import Series, User
from dependencies import get_current_user, get_current_admin_user

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
