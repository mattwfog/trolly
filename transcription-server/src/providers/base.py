from abc import ABC, abstractmethod
from pathlib import Path

from src.models.transcript import TranscriptResult


class TranscriptionProvider(ABC):
    @abstractmethod
    async def transcribe(
        self, file_path: Path, language: str | None = None
    ) -> TranscriptResult: ...
