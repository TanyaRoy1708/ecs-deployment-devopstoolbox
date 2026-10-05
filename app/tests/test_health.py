"""Integration and unit tests for the DevOps Toolbox application."""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_returns_200():
    response = client.get("/health")
    assert response.status_code == 200


def test_health_response_has_status_ok():
    response = client.get("/health")
    data = response.json()
    assert data["status"] == "ok"


def test_health_response_has_required_fields():
    response = client.get("/health")
    data = response.json()
    assert "service" in data
    assert "version" in data
    assert data["service"] == "devops-toolbox"


def test_home_returns_200():
    response = client.get("/")
    assert response.status_code == 200


def test_home_returns_html_content():
    response = client.get("/")
    assert "text/html" in response.headers["content-type"]


def test_cidr_tool_page_loads():
    response = client.get("/tools/cidr")
    assert response.status_code == 200


def test_cron_tool_page_loads():
    response = client.get("/tools/cron")
    assert response.status_code == 200


def test_cidr_service_valid_input():
    from services.cidr_service import calculate_cidr

    result = calculate_cidr("10.0.0.0/24")  # NOSONAR

    assert result["success"] is True
    assert result["network_address"] == "10.0.0.0"  # NOSONAR
    assert result["broadcast_address"] == "10.0.0.255"  # NOSONAR
    assert result["num_hosts"] == 254
    assert result["first_host"] == "10.0.0.1"  # NOSONAR
    assert result["last_host"] == "10.0.0.254"  # NOSONAR


def test_cidr_service_invalid_input():
    from services.cidr_service import calculate_cidr

    result = calculate_cidr("not-a-cidr")

    assert result["success"] is False
    assert "error" in result


def test_cron_service_valid_expression():
    from services.cron_service import explain_cron

    result = explain_cron("* * * * *")

    assert result["success"] is True
    assert "description" in result
    assert len(result["description"]) > 0


def test_cron_service_invalid_expression():
    from services.cron_service import explain_cron

    result = explain_cron("not a cron")

    assert result["success"] is False
    assert "error" in result
