import os 
from fastapi import FastAPI
import logfire

LOGFIRE_PROJECT_NAME = os.getenv("LOGFIRE_PROJECT_NAME")
LOGFIRE_API_KEY = os.getenv("LOGFIRE_API_KEY")

def create_app() -> FastAPI:
    logfire.configure(
        project_name=LOGFIRE_PROJECT_NAME, 
        api_key=LOGFIRE_API_KEY
        )
    app = FastAPI()
    logfire.instrument_fastapi(app)
    return app