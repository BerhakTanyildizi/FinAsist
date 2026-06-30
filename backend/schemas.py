from pydantic import BaseModel, EmailStr, Field
from datetime import date, datetime
from typing import Optional, Literal
from decimal import Decimal


# ─── Auth ───

class UserCreate(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    # Güvenlik: zayıf/boş parolaların (ör. tek karakter) kabul edilmesini engeller.
    password: str = Field(min_length=8, max_length=128)


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
    password: str = Field(max_length=128)


# ─── Category ───

class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    icon_name: Optional[str] = Field(default=None, max_length=50)
    type: Literal["income", "expense"]

class CategoryResponse(BaseModel):
    id: int
    user_id: Optional[int] = None
    name: str
    icon_name: Optional[str] = None
    type: str

    model_config = {"from_attributes": True}


# ─── Transaction ───

class TransactionCreate(BaseModel):
    category_id: int
    amount: Decimal = Field(gt=0, le=999_999_999)
    type: Literal["income", "expense"]
    merchant: Optional[str] = Field(default=None, max_length=100)
    description: Optional[str] = Field(default=None, max_length=2000)
    transaction_date: date


class TransactionUpdate(BaseModel):
    category_id: Optional[int] = None
    amount: Optional[Decimal] = Field(default=None, gt=0, le=999_999_999)
    type: Optional[Literal["income", "expense"]] = None
    merchant: Optional[str] = Field(default=None, max_length=100)
    description: Optional[str] = Field(default=None, max_length=2000)
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

# ─── Receipt / Fiş Tarama ───

class ReceiptScanBase64Request(BaseModel):
    """Base64 kodlanmış fiş görüntüsü isteği (Flutter web için)."""
    image_base64: str = Field(max_length=15_000_000)

class ReceiptScanResponse(BaseModel):
    """Fiş tarama sonucu — LLM veya fallback parser çıktısı."""
    kurum_adi: str
    tarih: str
    toplam_tutar: float
    kdv_tutari: float
    kategori: str
    islem_tipi: str
    ocr_text: str


# ─── Recurring Transaction ───

class RecurringTransactionCreate(BaseModel):
    category_id: int
    amount: Decimal = Field(gt=0, le=999_999_999)
    type: Literal["income", "expense"]
    frequency: Literal["Aylık", "Haftalık", "Yıllık"]
    start_date: date
    end_date: Optional[date] = None
    description: Optional[str] = Field(default=None, max_length=2000)


class RecurringTransactionUpdate(BaseModel):
    amount: Optional[Decimal] = Field(default=None, gt=0, le=999_999_999)
    end_date: Optional[date] = None
    description: Optional[str] = Field(default=None, max_length=2000)


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


# ─── AI Danışman / Sohbet ───

class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(max_length=4000)


class AdvisorChatRequest(BaseModel):
    # Güvenlik: Groq API'ye iletilen veri boyutunu sınırlayarak maliyet/DoS
    # amaçlı kötüye kullanımı (aşırı uzun mesaj/geçmiş) engeller.
    message: str = Field(min_length=1, max_length=2000)
    history: list[ChatMessage] = Field(default_factory=list, max_length=50)


class AdvisorChatResponse(BaseModel):
    reply: str
