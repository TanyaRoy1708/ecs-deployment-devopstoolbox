from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.cron_service import explain_cron

router = APIRouter(prefix="/tools", tags=["cron"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

_cron_cache = {}

@router.get("/cron", response_class=HTMLResponse)
async def get_cron(request: Request):
    return templates.TemplateResponse(request, "cron.html", {"request": request})

@router.post("/cron", response_class=HTMLResponse)
async def post_cron(request: Request, expression: str = Form(...)):
    cache_key = expression.strip()
    cache_hit = False
    
    if cache_key in _cron_cache:
        result = _cron_cache[cache_key]
        cache_hit = True
    else:
        result = explain_cron(cache_key)
        if result.get("success"):
            # Enforce size limit to prevent memory leak (FIFO)
            if len(_cron_cache) >= 100:
                _cron_cache.pop(next(iter(_cron_cache)))
            _cron_cache[cache_key] = result

    return templates.TemplateResponse(
        request, 
        "cron.html", 
        {"request": request, "result": result, "expression": expression, "cache_hit": cache_hit}
    )
