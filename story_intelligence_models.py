"""Story Intelligence SQLAlchemy models.

Integration:
    from .story_intelligence_models import register_story_intelligence_models
    register_story_intelligence_models(Base)

Call register_story_intelligence_models(Base) after defining/importing your
existing SQLAlchemy declarative Base and before create_all().
"""
from datetime import datetime, timezone
from uuid import uuid4
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

def _id():
    return str(uuid4())

def register_story_intelligence_models(Base):
    class Character(Base):
        __tablename__ = "si_characters"
        id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_id)
        project_id: Mapped[str] = mapped_column(String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True)
        name: Mapped[str] = mapped_column(String(160), nullable=False)
        role: Mapped[str | None] = mapped_column(String(100))
        description: Mapped[str | None] = mapped_column(Text)
        goals: Mapped[str | None] = mapped_column(Text)
        arc: Mapped[str | None] = mapped_column(Text)
        status: Mapped[str] = mapped_column(String(24), default="active")
        created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    class CharacterRelationship(Base):
        __tablename__ = "si_relationships"
        id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_id)
        project_id: Mapped[str] = mapped_column(String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True)
        source_character_id: Mapped[str] = mapped_column(String(36), ForeignKey("si_characters.id", ondelete="CASCADE"))
        target_character_id: Mapped[str] = mapped_column(String(36), ForeignKey("si_characters.id", ondelete="CASCADE"))
        relationship_type: Mapped[str] = mapped_column(String(100), nullable=False)
        notes: Mapped[str | None] = mapped_column(Text)

    class CanonFact(Base):
        __tablename__ = "si_canon_facts"
        id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_id)
        project_id: Mapped[str] = mapped_column(String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True)
        subject: Mapped[str] = mapped_column(String(180), nullable=False, index=True)
        predicate: Mapped[str] = mapped_column(String(120), nullable=False, index=True)
        value: Mapped[str] = mapped_column(Text, nullable=False)
        status: Mapped[str] = mapped_column(String(24), default="provisional", index=True)
        source_ref: Mapped[str | None] = mapped_column(String(240))
        notes: Mapped[str | None] = mapped_column(Text)
        created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
        updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
        __table_args__ = (UniqueConstraint("project_id", "subject", "predicate", "value", name="uq_si_fact"),)

    class StoryEvent(Base):
        __tablename__ = "si_events"
        id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_id)
        project_id: Mapped[str] = mapped_column(String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True)
        title: Mapped[str] = mapped_column(String(200), nullable=False)
        story_time: Mapped[str | None] = mapped_column(String(120))
        location: Mapped[str | None] = mapped_column(String(180))
        description: Mapped[str] = mapped_column(Text, nullable=False)
        importance: Mapped[str] = mapped_column(String(24), default="normal")

    class ChapterMemory(Base):
        __tablename__ = "si_chapter_memory"
        id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_id)
        project_id: Mapped[str] = mapped_column(String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True)
        chapter_number: Mapped[int] = mapped_column(Integer, nullable=False)
        title: Mapped[str | None] = mapped_column(String(200))
        summary: Mapped[str] = mapped_column(Text, nullable=False)
        open_threads: Mapped[str | None] = mapped_column(Text)
        approved: Mapped[bool] = mapped_column(Boolean, default=False)

    class StoryDecision(Base):
        __tablename__ = "si_decisions"
        id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_id)
        project_id: Mapped[str] = mapped_column(String(36), ForeignKey("projects.id", ondelete="CASCADE"), index=True)
        decision: Mapped[str] = mapped_column(Text, nullable=False)
        rationale: Mapped[str | None] = mapped_column(Text)
        created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    return {
        "Character": Character,
        "CharacterRelationship": CharacterRelationship,
        "CanonFact": CanonFact,
        "StoryEvent": StoryEvent,
        "ChapterMemory": ChapterMemory,
        "StoryDecision": StoryDecision,
    }
