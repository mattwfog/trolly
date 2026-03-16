from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.config import get_settings
from src.providers.openai_provider import OpenAITranscriptionProvider
from src.routers import transcribe


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    provider = OpenAITranscriptionProvider(api_key=settings.openai_api_key)
    transcribe.set_provider(provider)
    yield


app = FastAPI(
    title="Trolly Transcription Server",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1", "http://localhost"],
    allow_methods=["POST"],
    allow_headers=["Content-Type"],
)

app.include_router(transcribe.router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
