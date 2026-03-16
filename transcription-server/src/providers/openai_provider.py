from pathlib import Path

from openai import AsyncOpenAI

from src.models.transcript import TranscriptResult, TranscriptSegment
from src.providers.base import TranscriptionProvider


class OpenAITranscriptionProvider(TranscriptionProvider):
    def __init__(self, api_key: str) -> None:
        self._client = AsyncOpenAI(api_key=api_key)

    async def transcribe(
        self, file_path: Path, language: str | None = None
    ) -> TranscriptResult:
        with open(file_path, "rb") as audio_file:
            kwargs: dict = {
                "model": "whisper-1",
                "file": audio_file,
                "response_format": "verbose_json",
                "timestamp_granularities": ["segment"],
            }
            if language is not None:
                kwargs["language"] = language

            response = await self._client.audio.transcriptions.create(**kwargs)

        segments = [
            TranscriptSegment(
                start=seg.start,
                end=seg.end,
                text=seg.text.strip(),
            )
            for seg in (response.segments or [])
        ]

        return TranscriptResult(
            text=response.text.strip(),
            segments=segments,
            language=response.language or "en",
            duration=response.duration or 0.0,
        )
