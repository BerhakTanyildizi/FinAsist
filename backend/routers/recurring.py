from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date
from dateutil.relativedelta import relativedelta

from database import get_db
from models import RecurringTransaction, Transaction, User
from schemas import RecurringTransactionCreate, RecurringTransactionUpdate, RecurringTransactionResponse
from routers.auth import get_current_user

router = APIRouter(prefix="/recurring", tags=["Düzenli İşlemler"])


def sync_recurring_transactions(db: Session, user_id: int):
    """
    Kullanıcının tekrarlayan işlemlerini (RecurringTransaction) tarayıp,
    vakti gelmiş olanları normal Transaction tablosuna ekler ve next_date'i öteler.
    """
    today = date.today()
    
    recurrings = (
        db.query(RecurringTransaction)
        .filter(RecurringTransaction.user_id == user_id)
        .all()
    )
    
    for r in recurrings:
        # Bitiş tarihi geçmişse atla
        if r.end_date and r.end_date < today and r.next_date > r.end_date:
            continue
            
        while r.next_date <= today:
            # İşin son tarihi varsa ve next_date ondan büyükse dur
            if r.end_date and r.next_date > r.end_date:
                break
                
            # Normal işleme ekle
            new_tx = Transaction(
                user_id=r.user_id,
                category_id=r.category_id,
                amount=r.amount,
                type=r.type,
                merchant="Sistem",
                description=f"[Oto-Kayıt] {r.description or ''}",
                transaction_date=r.next_date
            )
            db.add(new_tx)
            
            # Tarihi öteler
            if r.frequency == 'Aylık':
                r.next_date = r.next_date + relativedelta(months=1)
            elif r.frequency == 'Haftalık':
                r.next_date = r.next_date + relativedelta(days=7)
            elif r.frequency == 'Yıllık':
                r.next_date = r.next_date + relativedelta(years=1)
            else:
                break # Default fallback
                
        db.commit()


@router.post("/", response_model=RecurringTransactionResponse, status_code=status.HTTP_201_CREATED)
def create_recurring(
    data: RecurringTransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Yeni düzenli işlem / taksit ekler."""
    new_rec = RecurringTransaction(
        user_id=current_user.id,
        category_id=data.category_id,
        amount=data.amount,
        type=data.type,
        frequency=data.frequency,
        start_date=data.start_date,
        end_date=data.end_date,
        next_date=data.start_date,
        description=data.description,
    )
    db.add(new_rec)
    db.commit()
    db.refresh(new_rec)
    
    # Eklendiği anda hemen senkronizasyonu çalıştırarak eğer geçmiş tarihli ise hemen günceli yakalamasını sağla
    sync_recurring_transactions(db, current_user.id)
    
    return new_rec


@router.get("/", response_model=List[RecurringTransactionResponse])
def list_recurrings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Giriş yapan kullanıcının tüm düzenli işlemlerini listeler."""
    return (
        db.query(RecurringTransaction)
        .filter(RecurringTransaction.user_id == current_user.id)
        .all()
    )


@router.delete("/{rec_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_recurring(
    rec_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Bir düzenli işlemi iptal eder/siler."""
    rec = (
        db.query(RecurringTransaction)
        .filter(RecurringTransaction.id == rec_id, RecurringTransaction.user_id == current_user.id)
        .first()
    )
    if not rec:
        raise HTTPException(status_code=404, detail="Düzenli işlem bulunamadı.")
    
    db.delete(rec)
    db.commit()
