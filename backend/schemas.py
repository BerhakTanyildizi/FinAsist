from pydantic import BaseModel, EmailStr
from datetime import date, datetime
from typing import Optional
from decimal import Decimal


# ─── Auth ───

class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    created_at: datetime

    model_config = {"from_attributes": True}


class Token(BaseModel):
    access_token: str
    token_type: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ─── Category ───

class CategoryCreate(BaseModel):
    name: str
    icon_name: Optional[str] = None
    type: str  # 'income' or 'expense'

class CategoryResponse(BaseModel):
    id: int
    name: str
    icon_name: Optional[str] = None
    type: str

    model_config = {"from_attributes": True}


# ─── Transaction ───

class TransactionCreate(BaseModel):
    category_id: int
    amount: Decimal
    type: str  # 'income' or 'expense'
    merchant: Optional[str] = None
    description: Optional[str] = None
    transaction_date: date


class TransactionUpdate(BaseModel):
    category_id: Optional[int] = None
    amount: Optional[Decimal] = None
    type: Optional[str] = None
    merchant: Optional[str] = None
    description: Optional[str] = None
    transaction_date: Optional[date] = None


class TransactionResponse(BaseModel):
    id: int
    user_id: int
    category_id: int
    amount: Decimal
    type: str
    merchant: Optional[str] = None
    description: Optional[str] = None
    transaction_date: date
    created_at: datetime
    category: CategoryResponse

    model_config = {"from_attributes": True}

# ─── Recurring Transaction ───

class RecurringTransactionCreate(BaseModel):
    category_id: int
    amount: Decimal
    type: str
    frequency: str
    start_date: date
    end_date: Optional[date] = None
    description: Optional[str] = None


class RecurringTransactionUpdate(BaseModel):
    amount: Optional[Decimal] = None
    end_date: Optional[date] = None
    description: Optional[str] = None


class RecurringTransactionResponse(BaseModel):
    id: int
    user_id: int
    category_id: int
    amount: Decimal
    type: str
    frequency: str
    start_date: date
    end_date: Optional[date] = None
    next_date: date
    description: Optional[str] = None
    created_at: datetime
    category: CategoryResponse

    model_config = {"from_attributes": True}
