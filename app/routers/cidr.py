from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.cidr_service import calculate_cidr

router = APIRouter(prefix="/tools", tags=["cidr"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

_cidr_cache = {}

@router.get("/cidr", response_class=HTMLResponse)
async def get_cidr(request: Request):
    return templates.TemplateResponse(request, "cidr.html", {"request": request})

@router.post("/cidr", response_class=HTMLResponse)
async def post_cidr(request: Request, cidr: str = Form(...)):
    cache_key = cidr.strip()
    cache_hit = False
    
    if cache_key in _cidr_cache:
        result = _cidr_cache[cache_key]
        cache_hit = True
    else:
        result = calculate_cidr(cache_key)
        if result.get("success"):
            # Enforce size limit to prevent memory leak (FIFO)
            if len(_cidr_cache) >= 100:
                _cidr_cache.pop(next(iter(_cidr_cache)))
            _cidr_cache[cache_key] = result

    return templates.TemplateResponse(
        request, 
        "cidr.html", 
        {"request": request, "result": result, "cidr": cidr, "cache_hit": cache_hit}
    )


