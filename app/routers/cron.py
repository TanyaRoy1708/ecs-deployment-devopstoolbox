from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.cron_service import explain_cron

router = APIRouter(prefix="/tools", tags=["cron"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

@router.get("/cron", response_class=HTMLResponse)
async def get_cron(request: Request):
    return templates.TemplateResponse(request, "cron.html", {"request": request})

@router.post("/cron", response_class=HTMLResponse)
async def post_cron(request: Request, expression: str = Form(...)):
    # Process Request
    result = explain_cron(expression)

    return templates.TemplateResponse(request, "cron.html", {"request": request, "result": result})
