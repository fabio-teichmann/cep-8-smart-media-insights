from pydantic import BaseModel
from uuid import UUID

class MediaMeta(BaseModel):
    request_id: UUID
    created_at: str
    status: str
    media_type: str

class MediaUploadResponse(BaseModel):
    request_id: str
    status: str = "accepted"