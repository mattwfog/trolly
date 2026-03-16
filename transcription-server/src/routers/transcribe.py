import tempfile
from pathlib import Path

from fastapi import APIRouter, HTTPException, UploadFile

from src.models.transcript import TranscribeURLRequest, TranscriptResult
from src.providers.base import TranscriptionProvider

router = APIRouter()

_provider: TranscriptionProvider | None = None


def set_provider(provider: TranscriptionProvider) -> None:
    global _provider
    _provider = provider


def _get_provider() -> TranscriptionProvider:
    if _provider is None:
        raise HTTPException(
            status_code=503,
            detail="Transcription provider not initialized",
        )
    return _provider


@router.post("/transcribe", response_model=TranscriptResult)
async def transcribe_upload(
    file: UploadFile,
    language: str | None = None,
) -> TranscriptResult:
    provider = _get_provider()

    suffix = Path(file.filename or "upload.mp4").suffix or ".mp4"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = Path(tmp.name)

    try:
        return await provider.transcribe(tmp_path, language=language)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Transcription failed: {exc}",
        ) from exc
    finally:
        tmp_path.unlink(missing_ok=True)


@router.post("/transcribe/url", response_model=TranscriptResult)
async def transcribe_url(request: TranscribeURLRequest) -> TranscriptResult:
    provider = _get_provider()

    file_path = Path(request.file_path)
    if not file_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"File not found: {request.file_path}",
        )
    if not file_path.is_file():
        raise HTTPException(
            status_code=400,
            detail=f"Path is not a file: {request.file_path}",
        )

    try:
        return await provider.transcribe(file_path, language=request.language)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Transcription failed: {exc}",
        ) from exc
