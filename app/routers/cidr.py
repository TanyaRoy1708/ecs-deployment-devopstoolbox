from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.cidr_service import calculate_cidr

router = APIRouter(prefix="/tools", tags=["cidr"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

@router.get("/cidr", response_class=HTMLResponse)
async def get_cidr(request: Request):
    return templates.TemplateResponse(request, "cidr.html", {"request": request})

@router.post("/cidr", response_class=HTMLResponse)
async def post_cidr(request: Request, cidr: str = Form(...)):
    # Process Request
    result = calculate_cidr(cidr)

    return templates.TemplateResponse(request, "cidr.html", {"request": request, "result": result, "cidr": cidr})


