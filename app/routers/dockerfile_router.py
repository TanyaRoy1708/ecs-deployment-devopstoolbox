from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.dockerfile_service import lint_dockerfile

router = APIRouter(prefix="/tools", tags=["dockerfile"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

@router.get("/dockerfile", response_class=HTMLResponse)
async def get_dockerfile(request: Request):
    return templates.TemplateResponse(request, "dockerfile.html", {"request": request})

@router.post("/dockerfile", response_class=HTMLResponse)
async def post_dockerfile(request: Request, dockerfile: str = Form(...)):
    result = lint_dockerfile(dockerfile)
    return templates.TemplateResponse(request, "dockerfile.html", {"request": request, "result": result, "dockerfile": dockerfile})
