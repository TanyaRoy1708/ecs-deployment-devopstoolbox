import jwt
from datetime import datetime

def decode_jwt(token: str) -> dict:
    try:
        header = jwt.get_unverified_header(token)
        payload = jwt.decode(token, options={"verify_signature": False})
        
        expired = False
        if 'exp' in payload:
            exp_date = datetime.fromtimestamp(payload['exp'])
            if datetime.now() > exp_date:
                expired = True
                
        return {
            "success": True, 
            "header": header, 
            "payload": payload,
            "expired": expired
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
