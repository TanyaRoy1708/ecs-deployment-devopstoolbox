from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pathlib import Path

from routers import cron, cidr, k8s, dockerfile_router

app = FastAPI(title="DevOps Toolbox")

# Mount static files
static_dir = Path(__file__).parent / "static"
static_dir.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

# Templates
templates_dir = Path(__file__).parent / "templates"
templates_dir.mkdir(parents=True, exist_ok=True)
templates = Jinja2Templates(directory=str(templates_dir))

# Include routers
app.include_router(cron.router)

app.include_router(cidr.router)
app.include_router(k8s.router)
app.include_router(dockerfile_router.router)

@app.get("/health")
async def health():
    """Liveness probe — used by ALB target group and Docker HEALTHCHECK."""
    return {"status": "ok", "service": "devops-toolbox", "version": "1.0.0"}


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse(request, "index.html", {
        "request": request
    })
