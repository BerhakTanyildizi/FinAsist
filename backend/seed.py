import os
from sqlalchemy.orm import Session
from database import SessionLocal, engine, Base
from models import User, Category
from routers.auth import hash_password

def seed_database():
    print("Database seeding started...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # 1. Create Test User
        test_user = db.query(User).filter(User.email == "test@finasist.com").first()
        if not test_user:
            print("Creating test user...")
            test_user = User(
                full_name="Test Kullanıcı",
                email="test@finasist.com",
                hashed_password=hash_password("123456")
            )
            db.add(test_user)
            db.commit()
            db.refresh(test_user)
        else:
            print("Test user already exists.")

        # 2. Create Categories
        categories = [
            {"name": "Gıda/Market", "icon_name": "cart", "type": "expense"},
            {"name": "Maaş", "icon_name": "money", "type": "income"},
            {"name": "Kira/Fatura", "icon_name": "home", "type": "expense"},
            {"name": "Eğlence", "icon_name": "smile", "type": "expense"},
            {"name": "Tahsilat", "icon_name": "download", "type": "income"}
        ]
        
        for cat_data in categories:
            existing_cat = db.query(Category).filter(Category.name == cat_data["name"]).first()
            if not existing_cat:
                print(f"Creating category: {cat_data['name']}...")
                new_cat = Category(**cat_data)
                db.add(new_cat)
        
        db.commit()
        print("Database seeding completed.")
    except Exception as e:
        print(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
