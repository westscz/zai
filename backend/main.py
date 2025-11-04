from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, series, measurements, sensors

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
app.include_router(series.router)
app.include_router(measurements.router)
app.include_router(sensors.router)

@app.get("/")
async def root():
    return {"message": "ZAI Measurement Data Collection API"}

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}
