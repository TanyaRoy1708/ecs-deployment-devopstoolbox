from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.jwt_service import decode_jwt

router = APIRouter(prefix="/tools", tags=["jwt"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

_jwt_cache = {}

@router.get("/jwt", response_class=HTMLResponse)
async def get_jwt(request: Request):
    return templates.TemplateResponse(request, "jwt.html", {"request": request})

@router.post("/jwt", response_class=HTMLResponse)
async def post_jwt(request: Request, token: str = Form(...)):
    cache_key = token.strip()
    cache_hit = False
    
    if cache_key in _jwt_cache:
        result = _jwt_cache[cache_key]
        cache_hit = True
    else:
        result = decode_jwt(cache_key)
        if result.get("success"):
            # Enforce size limit to prevent memory leak (FIFO)
            if len(_jwt_cache) >= 100:
                _jwt_cache.pop(next(iter(_jwt_cache)))
            _jwt_cache[cache_key] = result

    return templates.TemplateResponse(
        request, 
        "jwt.html", 
        {"request": request, "result": result, "token": token, "cache_hit": cache_hit}
    )
