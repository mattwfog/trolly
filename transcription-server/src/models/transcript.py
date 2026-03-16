from pydantic import BaseModel


class TranscriptSegment(BaseModel):
    start: float
    end: float
    text: str


class TranscriptResult(BaseModel):
    text: str
    segments: list[TranscriptSegment]
    language: str
    duration: float


class TranscribeURLRequest(BaseModel):
    file_path: str
    language: str | None = None
