"""FastAPI integration routes for Novel Writer Engine.

The host app passes its database dependency and Story Intelligence model map.
Authentication/ownership checks must be added before public deployment.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session
from typing import Optional
from .novel_writer_engine import build_scene_context, compose_scene_prompt, check_draft_continuity

class SceneContextRequest(BaseModel):
    scene_goal: str = Field(min_length=1)
    pov_character: Optional[str] = None
    scene_time: Optional[str] = None
    location: Optional[str] = None
    style_guide: Optional[str] = None
    secret_reveal_rules: dict[str, str] = {}

class DraftCheckRequest(BaseModel):
    draft: str = Field(min_length=1)
    required_terms: list[str] = []

def build_novel_writer_router(get_db, Project, models):
    router = APIRouter(prefix="/v1/projects/{project_id}/writer", tags=["Novel Writer"])
    Character = models["Character"]
    CanonFact = models["CanonFact"]
    StoryEvent = models["StoryEvent"]
    ChapterMemory = models["ChapterMemory"]

    def ensure_project(db, project_id):
        project = db.get(Project, project_id)
        if project is None:
            raise HTTPException(404, "Novel project not found")

    @router.post("/scene-context")
    def scene_context(project_id: str, body: SceneContextRequest, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        facts = list(db.scalars(select(CanonFact).where(CanonFact.project_id == project_id)).all())
        chars = list(db.scalars(select(Character).where(Character.project_id == project_id)).all())
        events = list(db.scalars(select(StoryEvent).where(StoryEvent.project_id == project_id)).all())
        memories = list(db.scalars(select(ChapterMemory).where(ChapterMemory.project_id == project_id)).all())
        bundle = build_scene_context(
            project_id=project_id, scene_goal=body.scene_goal,
            pov_character=body.pov_character, scene_time=body.scene_time,
            location=body.location,
            facts=[{"id":x.id,"subject":x.subject,"predicate":x.predicate,"value":x.value,"status":x.status} for x in facts],
            characters=[{"id":x.id,"name":x.name,"role":x.role,"description":x.description,"goals":x.goals,"arc":x.arc} for x in chars],
            events=[{"id":x.id,"title":x.title,"story_time":x.story_time,"location":x.location,"description":x.description} for x in events],
            chapter_memories=[{"chapter_number":x.chapter_number,"summary":x.summary,"open_threads":x.open_threads} for x in memories],
            secret_reveal_rules=body.secret_reveal_rules,
        )
        return {"context":bundle.to_dict(), "prompt":compose_scene_prompt(bundle, body.style_guide or "")}

    @router.post("/check-draft")
    def check_draft(project_id: str, body: DraftCheckRequest, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        facts = list(db.scalars(select(CanonFact).where(CanonFact.project_id == project_id)).all())
        approved = [{"id":x.id,"subject":x.subject,"predicate":x.predicate,"value":x.value}
                    for x in facts if x.status == "approved"]
        secrets = [{"id":x.id,"subject":x.subject,"predicate":x.predicate,"value":x.value}
                   for x in facts if x.status == "secret"]
        return check_draft_continuity(body.draft, approved_facts=approved,
                                      withheld_secrets=secrets, required_terms=body.required_terms)

    return router
