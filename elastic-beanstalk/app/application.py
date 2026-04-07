from fastapi import FastAPI
import os

app = FastAPI(title="EB Hands-on API")


@app.get("/")
def root():
    return {
        "message": "Hello from Elastic Beanstalk!",
        "env": os.getenv("APP_ENV", "local"),
        "log_level": os.getenv("LOG_LEVEL", "debug"),
    }


@app.get("/health")
def health():
    return {"status": "ok"}

