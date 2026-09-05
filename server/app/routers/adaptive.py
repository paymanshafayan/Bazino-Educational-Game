"""پیکربندی تطبیقی مرحله برای کلاینت Godot."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import require_role
from ..services.adaptive_builder import build_stage_config

router = APIRouter(prefix="/adaptive", tags=["adaptive"])


@router.get("/stage/{child_id}", response_model=schemas.StageConfig)
def next_stage(child_id: int, region: str, season: int = 1, index_no: int = 1,
               db: Session = Depends(get_db),
               _: models.User = Depends(require_role(models.Role.PLAYER, models.Role.STAFF))):
    if not db.get(models.Child, child_id):
        raise HTTPException(404, "فرزند یافت نشد")
    cfg = build_stage_config(db, child_id, region, season, index_no)
    return schemas.StageConfig(**cfg)
