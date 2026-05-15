from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.jwt_service import decode_jwt

router = APIRouter(prefix="/tools", tags=["jwt"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

@router.get("/jwt", response_class=HTMLResponse)
async def get_jwt(request: Request):
    return templates.TemplateResponse(request, "jwt.html", {"request": request})

@router.post("/jwt", response_class=HTMLResponse)
async def post_jwt(request: Request, token: str = Form(...)):
    # Process Request
    result = decode_jwt(token)

    return templates.TemplateResponse(request, "jwt.html", {"request": request, "result": result, "token": token})
