from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path

from services.k8s_service import explain_k8s_manifest

router = APIRouter(prefix="/tools", tags=["k8s"])
templates = Jinja2Templates(directory=str(Path(__file__).parent.parent / "templates"))

@router.get("/k8s", response_class=HTMLResponse)
async def get_k8s(request: Request):
    return templates.TemplateResponse(request, "k8s.html", {"request": request})

@router.post("/k8s", response_class=HTMLResponse)
async def post_k8s(request: Request, manifest: str = Form(...)):
    result = explain_k8s_manifest(manifest)
    return templates.TemplateResponse(request, "k8s.html", {"request": request, "result": result, "manifest": manifest})
