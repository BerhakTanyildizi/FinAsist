"""
Basit Bellek-İçi Rate Limiter
===============================
IP başına, belirli bir zaman penceresi içindeki istek sayısını sınırlar.
Özellikle /auth/login ve /auth/register gibi brute-force/spam'e açık
endpoint'leri korumak için kullanılır.

Kapsam Notu:
- Tek process'li (dev / küçük ölçekli) çalıştırma için yeterlidir.
- Çoklu worker/process ile production'da paylaşılan durum gerektiği için
  Redis tabanlı bir çözüme (ör. slowapi + redis) geçilmelidir.
"""

import time
from collections import defaultdict
from fastapi import Request, HTTPException, status

_requests: dict[str, list[float]] = defaultdict(list)


def rate_limit(max_requests: int = 10, window_seconds: int = 60):
    """
    FastAPI dependency factory. Kullanım:
        @router.post("/login", dependencies=[Depends(rate_limit(10, 60))])
    """

    def dependency(request: Request) -> None:
        client_ip = request.client.host if request.client else "unknown"
        key = f"{request.url.path}:{client_ip}"
        now = time.time()

        # Pencere dışına çıkmış eski kayıtları temizle
        timestamps = [t for t in _requests[key] if now - t < window_seconds]

        if len(timestamps) >= max_requests:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Çok fazla deneme yapıldı. Lütfen bir süre sonra tekrar deneyin.",
            )

        timestamps.append(now)
        _requests[key] = timestamps

    return dependency
