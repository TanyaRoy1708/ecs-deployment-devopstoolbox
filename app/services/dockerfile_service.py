"""
Dockerfile linter service.

Rules checked (interview-ready list):
  DF001  FROM uses 'latest' tag          — unpinned base image, non-reproducible builds
  DF002  No USER instruction             — container runs as root, security risk
  DF003  apt-get install without -y      — blocks on interactive prompt in CI
  DF004  ADD used instead of COPY        — ADD has implicit tar-extraction/URL side-effects
  DF005  No HEALTHCHECK instruction      — Docker and ECS can't detect unhealthy containers
  DF006  Multiple RUN apt-get install    — should be combined to reduce layer count
  DF007  pip install without --no-cache-dir — inflates image with pip cache
  DF008  EXPOSE not present              — port intent is undocumented
  DF009  apt-get without apt-get update  — may install stale package versions
"""

from typing import Any


def lint_dockerfile(dockerfile_content: str) -> dict[str, Any]:
    lines = dockerfile_content.split("\n")
    warnings: list[str] = []

    has_user = False
    has_healthcheck = False
    has_expose = False
    apt_install_count = 0
    apt_update_before_install = False

    for i, raw_line in enumerate(lines, start=1):
        line = raw_line.strip()

        # DF001 — FROM uses 'latest' tag
        if line.startswith("FROM ") and ":latest" in line:
            warnings.append(
                f"[DF001] Line {i}: Avoid 'latest' tag in FROM — pin to a specific "
                "version for reproducible builds (e.g. python:3.11-slim)."
            )

        # DF004 — ADD instead of COPY
        if line.startswith("ADD "):
            warnings.append(
                f"[DF004] Line {i}: Prefer COPY over ADD unless you need automatic "
                "tar-extraction or URL fetching — ADD has implicit side-effects."
            )

        # DF003 — apt-get install without -y
        if "apt-get install" in line and "-y" not in line:
            warnings.append(
                f"[DF003] Line {i}: 'apt-get install' should include '-y' to prevent "
                "interactive prompts blocking CI builds."
            )

        # DF006 — multiple separate apt-get install layers
        if "apt-get install" in line:
            apt_install_count += 1

        # DF009 — apt-get update before install tracking
        if "apt-get update" in line:
            apt_update_before_install = True

        # DF007 — pip install without --no-cache-dir
        if "pip install" in line and "--no-cache-dir" not in line:
            warnings.append(
                f"[DF007] Line {i}: Add '--no-cache-dir' to pip install to avoid "
                "storing the pip cache inside the image layer."
            )

        # Track presence of key instructions
        if line.startswith("USER "):
            has_user = True
        if line.startswith("HEALTHCHECK "):
            has_healthcheck = True
        if line.startswith("EXPOSE "):
            has_expose = True

    # DF002 — no USER instruction
    if not has_user:
        warnings.append(
            "[DF002] No USER instruction found — container will run as root. "
            "Add a non-root user (e.g. RUN adduser --system appuser && USER appuser)."
        )

    # DF005 — no HEALTHCHECK
    if not has_healthcheck:
        warnings.append(
            "[DF005] No HEALTHCHECK instruction — Docker and ECS cannot detect "
            "unhealthy containers without one. "
            "Example: HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1"
        )

    # DF006 — multiple apt-get install RUN commands
    if apt_install_count > 1:
        warnings.append(
            f"[DF006] Found {apt_install_count} separate 'apt-get install' calls — "
            "combine them into a single RUN command to minimise image layers."
        )

    # DF008 — no EXPOSE
    if not has_expose:
        warnings.append(
            "[DF008] No EXPOSE instruction — document the port your service listens on "
            "(e.g. EXPOSE 8000). This is informational but important for clarity."
        )

    # DF009 — apt-get install without prior apt-get update in same run
    if apt_install_count > 0 and not apt_update_before_install:
        warnings.append(
            "[DF009] 'apt-get install' used without 'apt-get update' — stale package "
            "indexes may install outdated or unavailable versions. "
            "Combine as: RUN apt-get update && apt-get install -y <packages>"
        )

    return {
        "success": True,
        "warnings": warnings,
        "passed": len(warnings) == 0,
        "rule_count": 9,
    }
