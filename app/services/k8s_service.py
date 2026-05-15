"""
K8s Manifest Explainer service.

Supported manifest kinds (interview-ready scope):
  - Deployment    — workload, replicas, image, resource limits, liveness/readiness probes
  - Service       — type (ClusterIP/NodePort/LoadBalancer), selector, ports
  - ConfigMap     — data keys count, namespace
  - Namespace     — basic namespace metadata

Unsupported kinds are handled gracefully with a clear message rather than
an error — the tool documents its own scope boundary.

Design decision: scope is intentionally limited to the 4 most common kinds
encountered in day-to-day DevOps work. StatefulSet, DaemonSet, Ingress etc.
are listed as future improvements.
"""

import yaml
from typing import Any


# Kinds this tool fully understands — expand this set in future iterations
SUPPORTED_KINDS = {"Deployment", "Service", "ConfigMap", "Namespace"}


def _explain_deployment(doc: dict) -> str:
    spec = doc.get("spec", {})
    replicas = spec.get("replicas", 1)
    template = spec.get("template", {})
    containers = template.get("spec", {}).get("containers", [])

    parts = [f"Runs **{replicas}** replica(s)."]

    if containers:
        images = [c.get("image", "unknown") for c in containers]
        parts.append(f"Container image(s): `{'`, `'.join(images)}`.")

        # Liveness / readiness probes
        for c in containers:
            if c.get("livenessProbe"):
                parts.append(f"✅ Liveness probe configured on container `{c.get('name', 'unnamed')}`.")
            else:
                parts.append(f"⚠️ No liveness probe on container `{c.get('name', 'unnamed')}` — Kubernetes cannot detect if the app is deadlocked.")
            if c.get("readinessProbe"):
                parts.append(f"✅ Readiness probe configured on container `{c.get('name', 'unnamed')}`.")
            else:
                parts.append(f"⚠️ No readiness probe on container `{c.get('name', 'unnamed')}` — traffic may be sent before the app is ready.")

            # Resource limits
            resources = c.get("resources", {})
            if resources.get("limits"):
                parts.append(f"Resource limits set: `{resources['limits']}`.")
            else:
                parts.append("⚠️ No resource limits — container can consume unbounded CPU/memory on the node.")

    return " ".join(parts)


def _explain_service(doc: dict) -> str:
    spec = doc.get("spec", {})
    svc_type = spec.get("type", "ClusterIP")
    selector = spec.get("selector", {})
    ports = spec.get("ports", [])

    type_explanations = {
        "ClusterIP": "ClusterIP — internal only, not reachable from outside the cluster.",
        "NodePort": "NodePort — exposed on every node's IP at a static port (dev/testing only).",
        "LoadBalancer": "LoadBalancer — provisions a cloud load balancer (e.g. AWS ALB/NLB).",
        "ExternalName": "ExternalName — maps the service to an external DNS name (no proxying).",
    }

    parts = [f"Type: **{type_explanations.get(svc_type, svc_type)}**"]

    if selector:
        parts.append(f"Selects pods with labels: `{selector}`.")
    else:
        parts.append("⚠️ No selector — this Service will not route to any pods.")

    if ports:
        port_strs = [f"{p.get('port')}→{p.get('targetPort', p.get('port'))} ({p.get('protocol', 'TCP')})" for p in ports]
        parts.append(f"Port mapping(s): {', '.join(port_strs)}.")

    return " ".join(parts)


def _explain_configmap(doc: dict) -> str:
    data = doc.get("data", {})
    binary_data = doc.get("binaryData", {})
    key_count = len(data) + len(binary_data)
    parts = [f"Stores **{key_count}** configuration key(s)."]
    if data:
        parts.append(f"Keys: `{'`, `'.join(data.keys())}`.")
    parts.append("ConfigMaps hold non-secret config — for secrets, use a Secret resource instead.")
    return " ".join(parts)


def _explain_namespace(doc: dict) -> str:
    return (
        "Defines a logical isolation boundary within the cluster. "
        "Resources (Pods, Services, ConfigMaps) are scoped to a Namespace. "
        "Use namespaces to separate environments (dev/staging/prod) or teams."
    )


_EXPLAINERS = {
    "Deployment": _explain_deployment,
    "Service": _explain_service,
    "ConfigMap": _explain_configmap,
    "Namespace": _explain_namespace,
}


def explain_k8s_manifest(manifest_str: str) -> dict[str, Any]:
    """
    Parse and explain one or more Kubernetes manifests from a YAML string.
    Supports: Deployment, Service, ConfigMap, Namespace.
    Unsupported kinds return an informational message (not an error).
    """
    try:
        docs = list(yaml.safe_load_all(manifest_str))
    except yaml.YAMLError as e:
        return {"success": False, "error": f"Invalid YAML: {e}"}

    if not any(docs):
        return {"success": False, "error": "No valid YAML documents found in input."}

    explanations = []

    for doc in docs:
        if not doc or not isinstance(doc, dict):
            continue

        kind = doc.get("kind", "Unknown")
        name = doc.get("metadata", {}).get("name", "unnamed")
        namespace = doc.get("metadata", {}).get("namespace", "default")

        if kind not in SUPPORTED_KINDS:
            explanations.append({
                "kind": kind,
                "name": name,
                "namespace": namespace,
                "supported": False,
                "explanation": (
                    f"**{kind}** is not yet supported by this tool. "
                    f"Supported kinds: {', '.join(sorted(SUPPORTED_KINDS))}. "
                    "Basic metadata was extracted but no field-level explanation is available."
                ),
            })
            continue

        detail = _EXPLAINERS[kind](doc)

        explanations.append({
            "kind": kind,
            "name": name,
            "namespace": namespace,
            "supported": True,
            "explanation": (
                f"This manifest defines a **{kind}** named **`{name}`** "
                f"in the **`{namespace}`** namespace. {detail}"
            ),
        })

    return {"success": True, "explanations": explanations}
