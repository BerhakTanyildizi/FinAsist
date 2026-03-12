from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List

from database import get_db
from models import Category, User
from schemas import CategoryResponse, CategoryCreate
from routers.auth import get_current_user

router = APIRouter(prefix="/categories", tags=["Kategoriler"])

@router.get("/", response_model=List[CategoryResponse])
def get_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Hem global (herkesin gördüğü) kategorileri, hem de kullanıcının kendi yarattığı özel kategorileri döndürür."""
    return db.query(Category).filter(
        or_(Category.user_id == None, Category.user_id == current_user.id)
    ).all()


@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    data: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Kullanıcıya özel yeni bir kategori oluşturur."""
    new_cat = Category(
        user_id=current_user.id,
        name=data.name,
        icon_name=data.icon_name,
        type=data.type
    )
    db.add(new_cat)
    db.commit()
    db.refresh(new_cat)
    return new_cat


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Kullanıcının kendi yarattığı özel bir kategoriyi siler."""
    category = db.query(Category).filter(Category.id == category_id).first()
    
    if not category:
        raise HTTPException(status_code=404, detail="Kategori bulunamadı.")
        
    if category.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Sadece kendi oluşturduğunuz kategorileri silebilirsiniz.")

    db.delete(category)
    db.commit()
