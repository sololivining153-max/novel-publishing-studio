from contextlib import asynccontextmanager
from datetime import datetime, timezone
from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from .ai_provider import AIConfigurationError, AIProviderError, generate_text
from .config import settings
from .database import Base, engine, get_db
from .models import AIJob, AIUsage, Project
from .prompts import STORY_ARCHITECT_PROMPT_VERSION, STORY_ARCHITECT_SYSTEM
from .schemas import AIJobRead, OutlineGenerateRequest, OutlineGenerateResponse, ProjectCreate, ProjectRead
from .story_intelligence_models import register_story_intelligence_models
from .story_intelligence_router import build_router as build_intelligence_router
from .novel_writer_router import build_novel_writer_router
from .literary_editor_router import build_router as build_editor_router

STORY_MODELS = register_story_intelligence_models(Base)

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield

app = FastAPI(title="NOVEL FORGE AI API", version="0.4.0", lifespan=lifespan)
app.include_router(build_intelligence_router(get_db, Project, STORY_MODELS))
app.include_router(build_novel_writer_router(get_db, Project, STORY_MODELS))
app.include_router(build_editor_router())

@app.get("/health")
def health():
    return {"status": "ok", "service": "novel-forge-ai-api"}

@app.get("/v1/projects", response_model=list[ProjectRead])
def list_projects(db: Session = Depends(get_db)):
    return list(db.scalars(select(Project).order_by(Project.created_at.desc())).all())

@app.post("/v1/projects", response_model=ProjectRead, status_code=201)
def create_project(payload: ProjectCreate, db: Session = Depends(get_db)):
    project = Project(**payload.model_dump())
    db.add(project)
    db.commit()
    db.refresh(project)
    return project

@app.post("/v1/projects/{project_id}/generate-outline", response_model=OutlineGenerateResponse)
async def generate_outline(project_id: str, payload: OutlineGenerateRequest, db: Session = Depends(get_db)):
    project = db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    job = AIJob(
        project_id=project_id,
        status="running",
        model_name=settings.openai_model,
        prompt_version=STORY_ARCHITECT_PROMPT_VERSION,
        input_summary=f"chapters={payload.target_chapters}; words={payload.target_words}",
    )
    db.add(job)
    db.commit()
    db.refresh(job)

    user_prompt = f'''Build a detailed novel blueprint.

PROJECT TITLE: {project.title}
LANGUAGE: {project.language}
GENRE: {project.genre or "Not specified"}
AUTHOR PREMISE:
{project.premise or "No premise supplied. Suggest possible directions and label them as proposals."}

TARGET LENGTH: approximately {payload.target_words:,} words
TARGET CHAPTERS: {payload.target_chapters}
ADDITIONAL AUTHOR INSTRUCTIONS:
{payload.additional_instructions or "None"}

Make the plan coherent and suitable for author review.'''

    try:
        output, input_tokens, output_tokens = await generate_text(STORY_ARCHITECT_SYSTEM, user_prompt)
        job.status = "completed"
        job.output_text = output
        job.input_tokens = input_tokens
        job.output_tokens = output_tokens
        job.completed_at = datetime.now(timezone.utc)
        db.add(AIUsage(job_id=job.id, provider="openai", model_name=settings.openai_model,
                       input_tokens=input_tokens, output_tokens=output_tokens, estimated_cost_usd=0))
        db.commit()
        return OutlineGenerateResponse(job_id=job.id, project_id=project_id, status="completed",
            model=settings.openai_model, prompt_version=STORY_ARCHITECT_PROMPT_VERSION, outline=output)
    except AIConfigurationError as exc:
        job.status, job.error_message = "failed", str(exc)
        job.completed_at = datetime.now(timezone.utc)
        db.commit()
        raise HTTPException(status_code=503, detail=str(exc))
    except AIProviderError as exc:
        job.status, job.error_message = "failed", str(exc)
        job.completed_at = datetime.now(timezone.utc)
        db.commit()
        raise HTTPException(status_code=502, detail=str(exc))
    except Exception:
        job.status, job.error_message = "failed", "Unexpected generation failure."
        job.completed_at = datetime.now(timezone.utc)
        db.commit()
        raise HTTPException(status_code=500, detail="Outline generation failed.")

@app.get("/v1/ai-jobs/{job_id}", response_model=AIJobRead)
def get_ai_job(job_id: str, db: Session = Depends(get_db)):
    job = db.get(AIJob, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="AI job not found")
    return job
