
from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime
from typing import Optional


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


class SeriesBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    min_value: float
    max_value: float
    color: str = Field(default="#3B82F6", pattern="^#[0-9A-Fa-f]{6}$")
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
    unit: Optional[str] = Field(None, max_length=20)

class SeriesResponse(SeriesBase):
    id: int
    created_at: datetime
    created_by: Optional[int]

    class Config:
        from_attributes = True


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


class Token(BaseModel):
    access_token: str
    token_type: str

class LoginRequest(BaseModel):
    username: str
    password: str
