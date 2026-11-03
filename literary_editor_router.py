from typing import Any, Callable
from uuid import uuid4
import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from .literary_editor import REVIEW_TYPES, local_checks, build_prompt, validate_report, compare_versions

class ReviewInput(BaseModel):
    manuscript: str = Field(min_length=30,max_length=500000)
    review_type: str
    language: str = "en"
    project_context: str = ""
    canon_context: str = ""
    instructions: str = ""

class CompareInput(BaseModel):
    old_text: str = Field(min_length=1,max_length=500000)
    new_text: str = Field(min_length=1,max_length=500000)

def build_router(ai_generate: Callable[[str],Any] | None = None):
    router=APIRouter(prefix="/v1/editor",tags=["literary-editor"])
    @router.get("/review-types")
    def types():
        return {"review_types":[{"id":k,"description":v} for k,v in REVIEW_TYPES.items()]}
    @router.post("/local-checks")
    def checks(payload: dict):
        text=str(payload.get("manuscript",""))
        if len(text)<30: raise HTTPException(400,"Manuscript must contain at least 30 characters.")
        if len(text)>500000: raise HTTPException(413,"Manuscript too large.")
        return local_checks(text)
    @router.post("/review")
    def review(req: ReviewInput):
        if req.review_type not in REVIEW_TYPES: raise HTTPException(400,"Unsupported review type.")
        prompt=build_prompt(req.manuscript,req.review_type,req.language,req.project_context,req.canon_context,req.instructions)
        if ai_generate is None:
            return {"job_id":str(uuid4()),"status":"prompt_ready","prompt":prompt,
              "local_checks":local_checks(req.manuscript),
              "message":"Connect the server-side AI adapter to execute the review."}
        try:
            result=ai_generate(prompt)
            if isinstance(result,str): result=json.loads(result)
            return {"job_id":str(uuid4()),"status":"completed",
              "report":validate_report(result),"local_checks":local_checks(req.manuscript)}
        except Exception as exc:
            raise HTTPException(502,f"Editorial review failed: {type(exc).__name__}") from exc
    @router.post("/compare")
    def compare(req: CompareInput):
        return compare_versions(req.old_text,req.new_text)
    return router
