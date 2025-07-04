from fastapi import FastAPI
from app.routes import router
from app.db import create_tables

app = FastAPI(title="ClickHouse Backend")

@app.on_event("startup")
def startup():
    create_tables()

app.include_router(router)
