from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session
from routers import auth, series, measurements
from database import get_db

app = FastAPI(
    title="measures API",
    description="API for collecting and managing measurement data from multiple series",
    version="1.0.0"
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(auth.router)
app.include_router(series.router)
app.include_router(measurements.router)

@app.get("/")
async def root():
    return {"message": "measures API"}

@app.get("/api/health")
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint - verifies API and database connectivity"""
    try:

        db.execute(text("SELECT 1"))
        return {
            "status": "healthy",
            "database": "connected"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }
