"""
Test suite for the DevOps Toolbox FastAPI application.

HOW TESTING WORKS HERE (plain English):
-----------------------------------------
We use two tools:
  1. pytest      — the test runner (finds functions named test_* and runs them)
  2. TestClient  — a fake browser built into FastAPI that sends HTTP requests
                   to the app WITHOUT needing a real running server.

Each test function:
  - Sends an HTTP request via `client`
  - Gets back a `response` object (status code, body, headers)
  - Uses `assert` to check that the response is what we expect.
  - If the assert fails → the test FAILS (pytest marks it red )
  - If all asserts pass  → the test PASSES (pytest marks it green )

WHY THIS MATTERS FOR DEVOPS:
  In CI/CD, `pytest` runs automatically before deployment.
  If any test fails, the pipeline stops — broken code never reaches production.
"""

import sys
import os

# ---------------------------------------------------------------------------
# PATH FIX: tells Python where to find our app code (main.py, services/, etc.)
# Without this, imports like `from main import app` would fail because Python
# doesn't automatically look in the parent directory.
# ---------------------------------------------------------------------------
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi.testclient import TestClient
from main import app

# ---------------------------------------------------------------------------
# TestClient wraps the FastAPI app.
# Think of it as a fake browser — it sends GET/POST requests directly to the
# app in memory (no network, no port, no server process needed).
# ---------------------------------------------------------------------------
client = TestClient(app)


# ===========================================================================
# SECTION 1: Health Endpoint Tests
# These test the GET /health route — which ALB uses as a liveness probe.
# If /health breaks, ALB stops sending traffic to the container.
# ===========================================================================

def test_health_returns_200():
    """
    WHAT: Calls GET /health and checks the HTTP status code is 200 (OK).

    WHY IT MATTERS:
      The ALB Target Group health check hits this exact endpoint every 30s.
      If it returns anything other than 200, ECS marks the task as unhealthy
      and replaces it. This test catches any regression that would break that.
    """
    response = client.get("/health")
    assert response.status_code == 200


def test_health_response_has_status_ok():
    """
    WHAT: Checks that the JSON body contains {"status": "ok"}.

    WHY IT MATTERS:
      The status code being 200 is not enough — we also need the body to be
      correct. Imagine someone refactors the route and accidentally returns
      {"status": "error"} with a 200 code. This test catches that.
    """
    response = client.get("/health")
    data = response.json()
    assert data["status"] == "ok"


def test_health_response_has_required_fields():
    """
    WHAT: Checks that the health response includes 'service' and 'version' keys.

    WHY IT MATTERS:
      These fields are used by monitoring dashboards and log aggregators to
      identify which service and version is running. If they go missing,
      observability breaks silently. This test ensures the contract is kept.
    """
    response = client.get("/health")
    data = response.json()
    assert "service" in data, "Missing 'service' field in health response"
    assert "version" in data, "Missing 'version' field in health response"
    assert data["service"] == "devops-toolbox"


# ===========================================================================
# SECTION 2: Home Page Test
# Tests the GET / route that serves the main HTML dashboard.
# ===========================================================================

def test_home_returns_200():
    """
    WHAT: Checks that the home page loads successfully.

    WHY IT MATTERS:
      If the Jinja2 template is missing or has a syntax error, this route
      throws a 500 Internal Server Error. This test acts as a smoke test —
      "does the app start and render the main page without crashing?"
    """
    response = client.get("/")
    assert response.status_code == 200


def test_home_returns_html_content():
    """
    WHAT: Checks that the Content-Type header says 'text/html'.

    WHY IT MATTERS:
      If the route accidentally returns JSON instead of HTML (e.g., after a
      refactor), browsers would show raw text instead of the rendered page.
      Checking the Content-Type ensures we're actually serving a web page.
    """
    response = client.get("/")
    assert "text/html" in response.headers["content-type"]


# ===========================================================================
# SECTION 3: Tool Page Availability Tests
# Each tool (/tools/cidr, /tools/cron) should load its HTML form.
# ===========================================================================

def test_cidr_tool_page_loads():
    """
    WHAT: Checks that GET /tools/cidr returns 200.

    WHY IT MATTERS:
      This is a smoke test for the CIDR calculator tool. If the router is
      broken or the template is missing, this returns 500. Catching it here
      means the pipeline fails before bad code reaches ECS.
    """
    response = client.get("/tools/cidr")
    assert response.status_code == 200


def test_cron_tool_page_loads():
    """
    WHAT: Checks that GET /tools/cron returns 200.

    WHY IT MATTERS:
      Same reasoning as the CIDR test — verifies the cron explainer page
      is reachable and its template renders without errors.
    """
    response = client.get("/tools/cron")
    assert response.status_code == 200





# ===========================================================================
# SECTION 4: Service / Business Logic Unit Tests
# These test the Python functions directly — no HTTP request needed.
# This is the fastest kind of test (no network overhead at all).
# ===========================================================================

def test_cidr_service_valid_input():
    """
    WHAT: Calls calculate_cidr() directly with a valid CIDR and checks output.

    WHY IT MATTERS:
      Unit tests the core logic WITHOUT going through the HTTP layer.
      10.0.0.0/24 is a standard /24 subnet — it should have 254 usable hosts.
      If someone breaks the maths in cidr_service.py, this catches it instantly.
    """
    from services.cidr_service import calculate_cidr

    result = calculate_cidr("10.0.0.0/24")  # NOSONAR

    assert result["success"] is True
    assert result["network_address"] == "10.0.0.0"  # NOSONAR
    assert result["broadcast_address"] == "10.0.0.255"  # NOSONAR
    assert result["num_hosts"] == 254          # 256 - network - broadcast
    assert result["first_host"] == "10.0.0.1"  # NOSONAR
    assert result["last_host"] == "10.0.0.254"  # NOSONAR


def test_cidr_service_invalid_input():
    """
    WHAT: Passes garbage input to calculate_cidr() and checks it fails gracefully.

    WHY IT MATTERS:
      Users WILL submit invalid data. The service must return {"success": False}
      with an error message — NOT raise an unhandled exception (which would
      cause a 500 error and crash the request). This tests the error path.
    """
    from services.cidr_service import calculate_cidr

    result = calculate_cidr("not-a-cidr")

    assert result["success"] is False
    assert "error" in result             # must explain WHY it failed


def test_cron_service_valid_expression():
    """
    WHAT: Calls explain_cron() with "* * * * *" (every minute) and checks output.

    WHY IT MATTERS:
      Verifies the cron-descriptor library is working and returns a human-
      readable string. "* * * * *" is the simplest possible cron expression —
      if this breaks, the whole tool is broken.
    """
    from services.cron_service import explain_cron

    result = explain_cron("* * * * *")

    assert result["success"] is True
    assert "description" in result
    assert len(result["description"]) > 0   # must return a non-empty string


def test_cron_service_invalid_expression():
    """
    WHAT: Passes an invalid cron expression and checks graceful failure.

    WHY IT MATTERS:
      Invalid cron expressions must not crash the server — they should return
      {"success": False}. This is especially important because the cron tool
      is user-facing and bad input is expected.
    """
    from services.cron_service import explain_cron

    result = explain_cron("not a cron")

    assert result["success"] is False
    assert "error" in result



