from cron_descriptor import get_description, ExpressionDescriptor

def explain_cron(expression: str) -> dict:
    try:
        description = get_description(expression)
        return {"success": True, "description": description, "expression": expression}
    except Exception as e:
        return {"success": False, "error": str(e), "expression": expression}
