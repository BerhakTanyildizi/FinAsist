import logging

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import AdvisorChatRequest, AdvisorChatResponse
from routers.auth import get_current_user
from services.advisor_service import build_financial_summary, chat_with_advisor

logger = logging.getLogger("advisor_router")

router = APIRouter(prefix="/advisor", tags=["AI Danışman"])


@router.post("/chat", response_model=AdvisorChatResponse)
async def chat(
    data: AdvisorChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Kullanıcının finansal verilerine dayalı AI danışman sohbeti."""
    summary = build_financial_summary(db, current_user.id)
    history = [turn.model_dump() for turn in data.history]

    try:
        reply = await chat_with_advisor(data.message, history, summary)
    except Exception:
        # Ham exception metni istemciye döndürülmez (iç API detayları sızdırılmaz).
        logger.exception("AI danışman yanıt üretemedi (user_id=%s).", current_user.id)
        raise HTTPException(
            status_code=503,
            detail="AI danışman şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.",
        )

    return AdvisorChatResponse(reply=reply)
