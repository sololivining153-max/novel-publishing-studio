from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class ProjectCreate(BaseModel):
    title: str = Field(min_length=1, max_length=240)
    language: str = Field(default="en", max_length=8)
    genre: str | None = Field(default=None, max_length=80)
    premise: str | None = None

class ProjectRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    title: str
    language: str
    genre: str | None
    premise: str | None
    status: str
    created_at: datetime

class OutlineGenerateRequest(BaseModel):
    additional_instructions: str | None = Field(default=None, max_length=6000)
    target_chapters: int = Field(default=24, ge=5, le=60)
    target_words: int = Field(default=80000, ge=10000, le=250000)

class OutlineGenerateResponse(BaseModel):
    job_id: str
    project_id: str
    status: str
    model: str
    prompt_version: str
    outline: str

class AIJobRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    project_id: str
    job_type: str
    status: str
    model_name: str
    prompt_version: str
    output_text: str | None
    error_message: str | None
    input_tokens: int
    output_tokens: int
    created_at: datetime
    completed_at: datetime | None
