"""FastAPI router for the Story Intelligence module.

The host app must provide:
  * SQLAlchemy Session dependency `get_db`
  * declarative Base and project table `projects`
  * `register_story_intelligence_models(Base)` called before schema creation.

This router intentionally does not include authentication. Do not expose it
publicly until project ownership checks are added to every endpoint.
"""
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.orm import Session

router = APIRouter(prefix="/v1/projects/{project_id}/intelligence", tags=["Story Intelligence"])
FACT_STATUSES = {"approved", "provisional", "disputed", "secret"}

def build_router(get_db, Project, models):
    Character = models["Character"]
    Relationship = models["CharacterRelationship"]
    CanonFact = models["CanonFact"]
    StoryEvent = models["StoryEvent"]
    ChapterMemory = models["ChapterMemory"]
    StoryDecision = models["StoryDecision"]

    class CharacterIn(BaseModel):
        name: str = Field(min_length=1, max_length=160)
        role: Optional[str] = None
        description: Optional[str] = None
        goals: Optional[str] = None
        arc: Optional[str] = None

    class RelationshipIn(BaseModel):
        source_character_id: str
        target_character_id: str
        relationship_type: str = Field(min_length=1, max_length=100)
        notes: Optional[str] = None

    class FactIn(BaseModel):
        subject: str = Field(min_length=1, max_length=180)
        predicate: str = Field(min_length=1, max_length=120)
        value: str = Field(min_length=1)
        status: str = "provisional"
        source_ref: Optional[str] = None
        notes: Optional[str] = None

    class StatusIn(BaseModel):
        status: str

    class EventIn(BaseModel):
        title: str = Field(min_length=1, max_length=200)
        story_time: Optional[str] = None
        location: Optional[str] = None
        description: str = Field(min_length=1)
        importance: str = "normal"

    class ChapterMemoryIn(BaseModel):
        chapter_number: int = Field(ge=1)
        title: Optional[str] = None
        summary: str = Field(min_length=1)
        open_threads: Optional[str] = None

    class DecisionIn(BaseModel):
        decision: str = Field(min_length=1)
        rationale: Optional[str] = None

    def ensure_project(db, project_id):
        project = db.get(Project, project_id)
        if project is None:
            raise HTTPException(404, "Novel project not found")
        return project

    @router.get("/dashboard")
    def dashboard(project_id: str, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        def count(model):
            return db.scalar(select(func.count()).select_from(model).where(model.project_id == project_id)) or 0
        facts = list(db.scalars(select(CanonFact).where(CanonFact.project_id == project_id)).all())
        return {
            "characters": count(Character), "relationships": count(Relationship),
            "facts": len(facts), "approved": sum(x.status == "approved" for x in facts),
            "provisional": sum(x.status == "provisional" for x in facts),
            "disputed": sum(x.status == "disputed" for x in facts),
            "secrets": sum(x.status == "secret" for x in facts),
            "events": count(StoryEvent), "chapter_memories": count(ChapterMemory)
        }

    @router.get("/characters")
    def list_characters(project_id: str, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        return list(db.scalars(select(Character).where(Character.project_id == project_id).order_by(Character.name)).all())

    @router.post("/characters", status_code=201)
    def create_character(project_id: str, body: CharacterIn, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        item = Character(project_id=project_id, **body.model_dump())
        db.add(item); db.commit(); db.refresh(item)
        return item

    @router.post("/relationships", status_code=201)
    def create_relationship(project_id: str, body: RelationshipIn, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        a, b = db.get(Character, body.source_character_id), db.get(Character, body.target_character_id)
        if not a or not b or a.project_id != project_id or b.project_id != project_id:
            raise HTTPException(400, "Both characters must belong to this novel.")
        if a.id == b.id:
            raise HTTPException(400, "A character cannot be related to itself.")
        item = Relationship(project_id=project_id, **body.model_dump())
        db.add(item); db.commit(); db.refresh(item)
        return item

    @router.get("/relationships")
    def list_relationships(project_id: str, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        return list(db.scalars(select(Relationship).where(Relationship.project_id == project_id)).all())

    @router.get("/canon")
    def list_facts(project_id: str, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        return list(db.scalars(select(CanonFact).where(CanonFact.project_id == project_id).order_by(CanonFact.created_at.desc())).all())

    @router.post("/canon", status_code=201)
    def propose_fact(project_id: str, body: FactIn, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        if body.status not in FACT_STATUSES:
            raise HTTPException(400, f"status must be one of {sorted(FACT_STATUSES)}")
        data = body.model_dump()
        # API never allows a new fact to self-approve, even if client asks.
        data["status"] = "provisional"
        item = CanonFact(project_id=project_id, **data)
        db.add(item); db.commit(); db.refresh(item)
        return item

    @router.patch("/canon/{fact_id}/status")
    def review_fact(project_id: str, fact_id: str, body: StatusIn, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        if body.status not in FACT_STATUSES:
            raise HTTPException(400, f"status must be one of {sorted(FACT_STATUSES)}")
        item = db.get(CanonFact, fact_id)
        if not item or item.project_id != project_id:
            raise HTTPException(404, "Canon fact not found")
        item.status = body.status
        item.updated_at = datetime.now(timezone.utc)
        db.commit(); db.refresh(item)
        return item

    @router.get("/canon/conflicts")
    def conflicts(project_id: str, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        rows = list(db.scalars(select(CanonFact).where(CanonFact.project_id == project_id)).all())
        groups = {}
        for row in rows:
            key = (row.subject.strip().casefold(), row.predicate.strip().casefold())
            groups.setdefault(key, []).append(row)
        result = []
        for group in groups.values():
            values = {x.value.strip().casefold() for x in group}
            if len(values) > 1:
                result.append({
                    "subject": group[0].subject, "predicate": group[0].predicate,
                    "facts": [{"id": x.id, "value": x.value, "status": x.status} for x in group],
                    "note": "Potential conflict. Context may explain the difference; author review required."
                })
        return {"conflicts": result}

    @router.get("/events")
    def list_events(project_id: str, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        return list(db.scalars(select(StoryEvent).where(StoryEvent.project_id == project_id)).all())

    @router.post("/events", status_code=201)
    def create_event(project_id: str, body: EventIn, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        item = StoryEvent(project_id=project_id, **body.model_dump())
        db.add(item); db.commit(); db.refresh(item)
        return item

    @router.get("/chapters")
    def list_chapter_memory(project_id: str, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        return list(db.scalars(select(ChapterMemory).where(ChapterMemory.project_id == project_id).order_by(ChapterMemory.chapter_number)).all())

    @router.post("/chapters", status_code=201)
    def create_chapter_memory(project_id: str, body: ChapterMemoryIn, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        item = ChapterMemory(project_id=project_id, **body.model_dump(), approved=False)
        db.add(item); db.commit(); db.refresh(item)
        return item

    @router.post("/decisions", status_code=201)
    def create_decision(project_id: str, body: DecisionIn, db: Session = Depends(get_db)):
        ensure_project(db, project_id)
        item = StoryDecision(project_id=project_id, **body.model_dump())
        db.add(item); db.commit(); db.refresh(item)
        return item

    return router
