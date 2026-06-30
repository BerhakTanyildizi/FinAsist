"""
AI Finansal Danışman Servisi
==============================
Kullanıcının son 30 günlük gelir/gider verilerini özetler ve bu özeti
bağlam (context) olarak vererek Groq LLM ile sohbet eder.

Mimari Tercih:
- Groq (Llama 3.3 70B) kullanılıyor — zaten fiş tarama pipeline'ında
  entegre, ücretsiz, hızlı (saniyeler içinde yanıt) ve Türkçe'de başarılı.
- Her istekte güncel finansal özet DB'den taze çekilir (önbellek yok,
  kişisel kullanım ölçeğinde gereksiz karmaşıklık).
- Konuşma geçmişi (history) istemciden gelir — backend stateless kalır,
  ayrı bir "sohbet" tablosu gerekmez.
"""

import logging
import re
from datetime import date, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_

from models import Transaction

from .llm_parser import GROQ_API_KEY, GROQ_MODEL

logger = logging.getLogger("advisor_service")

ANALYSIS_WINDOW_DAYS = 30
MAX_HISTORY_TURNS = 10  # Groq context'ini şişirmemek için son N mesaj

# Çok dilli Llama modeli nadiren Türkçe üretirken CJK (Çince/Japonca/Korece)
# karakterleri yanlışlıkla araya sıkıştırabiliyor (ör. "daha稳i" yerine "daha iyi").
# Prompt talimatı bunu büyük ölçüde azaltıyor ama garanti etmiyor — bu yüzden
# yanıt döndürülmeden önce bu script aralıkları deterministik olarak temizlenir.
#  Aralıklar kod noktası (code point) tamsayılarıyla tanımlanır ve chr() ile
#  derlenir — bu, kaynak dosyada yanlışlıkla bozulabilecek literal Unicode
#  karakterleri yazma riskini ortadan kaldırır.
_CJK_CODEPOINT_RANGES = [
    (0x3000, 0x303F),  # CJK noktalama
    (0x3040, 0x30FF),  # Hiragana, Katakana
    (0x3400, 0x4DBF),  # CJK Uzantı A
    (0x4E00, 0x9FFF),  # CJK Birleşik İdeogramlar
    (0xAC00, 0xD7AF),  # Hangul (Korece)
    (0xFF00, 0xFFEF),  # Tam genişlik formları
]
_CJK_PATTERN = re.compile(
    "[" + "".join(f"{chr(lo)}-{chr(hi)}" for lo, hi in _CJK_CODEPOINT_RANGES) + "]+"
)


def _strip_non_turkish_scripts(text: str) -> str:
    """CJK script karakterlerini metinden temizler."""
    return _CJK_PATTERN.sub("", text)


def build_financial_summary(db: Session, user_id: int) -> str:
    """
    Kullanıcının son 30 günlük gelir/gider durumunu LLM'in anlayacağı
    düz metin (markdown benzeri) bir özet olarak üretir.
    """
    start_date = date.today() - timedelta(days=ANALYSIS_WINDOW_DAYS)

    txs = (
        db.query(Transaction)
        .filter(
            and_(
                Transaction.user_id == user_id,
                Transaction.transaction_date >= start_date,
            )
        )
        .all()
    )

    if not txs:
        return (
            "Kullanıcının son 30 günde hiç kayıtlı işlemi yok. "
            "Henüz analiz edilecek veri olmadığını belirt ve işlem eklemesini öner."
        )

    total_income = sum(float(t.amount) for t in txs if t.type == "income")
    total_expense = sum(float(t.amount) for t in txs if t.type == "expense")
    net = total_income - total_expense

    category_totals: dict[str, float] = {}
    for t in txs:
        if t.type == "expense":
            cat_name = t.category.name if t.category else "Diğer"
            category_totals[cat_name] = category_totals.get(cat_name, 0.0) + float(t.amount)

    sorted_categories = sorted(category_totals.items(), key=lambda x: -x[1])

    lines = [
        f"Son {ANALYSIS_WINDOW_DAYS} günlük finansal özet ({len(txs)} işlem):",
        f"- Toplam Gelir: {total_income:.2f} TL",
        f"- Toplam Gider: {total_expense:.2f} TL",
        f"- Net Durum: {net:.2f} TL ({'tasarruf/fazla' if net >= 0 else 'açık/eksi'})",
    ]

    if sorted_categories:
        lines.append("- Kategori Bazında Giderler (büyükten küçüğe):")
        for cat, amt in sorted_categories[:8]:
            pct = (amt / total_expense * 100) if total_expense > 0 else 0
            lines.append(f"  • {cat}: {amt:.2f} TL (giderin %{pct:.0f}'i)")

    return "\n".join(lines)


ADVISOR_SYSTEM_PROMPT = """Sen Finasist uygulamasının yapay zeka finansal danışmanısın. \
Türkçe konuşuyorsun; samimi, destekleyici ama net ve profesyonel bir üslubun var.

Görevlerin:
- Kullanıcının gelir/gider verilerini DETAYLI yorumlayarak somut, uygulanabilir tasarruf
  önerileri sunmak. Yüzeysel geçme — rakamları analiz et, nedenini açıkla, örnek senaryolar ver.
- Gelir ile gider arasında fark (açık) varsa, hangi kategorilerde ne kadar kısıntı yapılabileceğini
  yüzde VE tutar bazlı somut örneklerle, gerekirse adım adım bir aksiyon planıyla önermek.
- Kategori dağılımını yorumla: hangi kategori orantısız büyük, neden olabilir, alternatif öner.
- Kullanıcı genel bir finans sorusu sorarsa (yatırım, bütçeleme, birikim, acil durum fonu vb.)
  kapsamlı bir danışman gibi sohbet et — sadece tek cümlelik geçiştirme yapma, bağlam ve
  gerekçelendirme ekle.
- Yanıt uzunluğu: Kısa selamlaşma/teşekkür mesajlarına kısa karşılık ver, ama analiz veya
  tavsiye istendiğinde DETAYLI yanıt ver (birden fazla paragraf veya madde işaretli liste olabilir).
  Tek cümlelik yüzeysel cevaplardan kaçın.
- Madde işaretleri ve alt başlıklar kullanarak okunabilirliği artır.
- Az miktarda emoji kullanabilirsin, abartma.
- Kesin yatırım tavsiyesi verme ("şu hisseyi al" gibi); genel ilkeler, risk farkındalığı ve
  gerekçeli öneriler sun.
- Aşağıdaki finansal özet GÜNCEL ve GERÇEK veridir, yanıtlarını buna dayandır. Veri yoksa
  bunu kullanıcıya söyle ve işlem eklemesini öner.
- SADECE düzgün Türkçe kelimeler kullan; başka dillerden (İngilizce, Endonezce vb.) kelime
  karıştırma.

{financial_summary}
"""


async def chat_with_advisor(message: str, history: list[dict], financial_summary: str) -> str:
    """
    Groq (Llama 3.3 70B) ile finansal danışman sohbeti yürütür.
    history: [{"role": "user"|"assistant", "content": "..."}] formatında, eskiden yeniye sıralı.
    """
    if not GROQ_API_KEY:
        raise ValueError("GROQ_API_KEY tanımlı değil — AI danışman kullanılamıyor.")

    import httpx

    messages = [
        {"role": "system", "content": ADVISOR_SYSTEM_PROMPT.format(financial_summary=financial_summary)}
    ]
    for turn in history[-MAX_HISTORY_TURNS:]:
        role = turn.get("role")
        content = turn.get("content", "")
        if role in ("user", "assistant") and content:
            messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": message})

    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {"Authorization": f"Bearer {GROQ_API_KEY}", "Content-Type": "application/json"}
    payload = {
        "model": GROQ_MODEL,
        "messages": messages,
        # Daha düşük sıcaklık: çok dilli model sapmasının (CJK karakter sızıntısı)
        # görülme sıklığını azaltır, yanıt kalitesini büyük ölçüde etkilemez.
        "temperature": 0.4,
        "max_tokens": 1400,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, json=payload, headers=headers)
        response.raise_for_status()

    data = response.json()
    reply = data["choices"][0]["message"]["content"]
    reply = _strip_non_turkish_scripts(reply)
    logger.info("Advisor yanıtı üretildi (%d karakter).", len(reply))
    return reply.strip()
