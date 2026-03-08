"""
Veritabanına varsayılan kategorileri ekler.
Tek seferlik çalıştırılır: python seed_data.py
"""
from database import SessionLocal
from models import Category

EXPENSE_CATEGORIES = [
    {"name": "Market & Gıda", "icon_name": "shopping_cart", "type": "expense"},
    {"name": "Faturalar", "icon_name": "receipt_long", "type": "expense"},
    {"name": "Ulaşım", "icon_name": "directions_car", "type": "expense"},
    {"name": "Eğlence", "icon_name": "movie", "type": "expense"},
    {"name": "Sağlık", "icon_name": "local_hospital", "type": "expense"},
    {"name": "Eğitim", "icon_name": "school", "type": "expense"},
    {"name": "Giyim", "icon_name": "checkroom", "type": "expense"},
    {"name": "Diğer", "icon_name": "more_horiz", "type": "expense"},
]

INCOME_CATEGORIES = [
    {"name": "Maaş", "icon_name": "account_balance", "type": "income"},
    {"name": "Freelance", "icon_name": "laptop", "type": "income"},
    {"name": "Yatırım", "icon_name": "trending_up", "type": "income"},
    {"name": "Hediye", "icon_name": "card_giftcard", "type": "income"},
    {"name": "Diğer", "icon_name": "more_horiz", "type": "income"},
]


def seed():
    db = SessionLocal()
    try:
        existing = db.query(Category).count()
        if existing > 0:
            print(f"Kategoriler zaten mevcut ({existing} adet). Atlanıyor.")
            return

        for cat in EXPENSE_CATEGORIES + INCOME_CATEGORIES:
            db.add(Category(**cat))
        db.commit()
        print(f"[OK] {len(EXPENSE_CATEGORIES) + len(INCOME_CATEGORIES)} kategori basariyla eklendi!")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
