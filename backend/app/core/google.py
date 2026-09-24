"""Thin, fakeable Google ID token verification.

In production, verifies against Google's certificates via google-auth.
In tests, this module is monkeypatched to return a controlled result.
"""

from google.auth.transport import requests
from google.oauth2 import id_token


async def verify_google_token(token: str, client_id: str) -> dict:
    """Verify a Google ID token and return its payload.

    Raises InvalidGoogleToken if verification fails.
    """
    try:
        id_info = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            client_id,
        )
        return id_info
    except Exception as e:
        print(f"Google token verification error: {type(e).__name__}: {e}")
        raise InvalidGoogleToken(f"Token verification failed: {e}")


class InvalidGoogleToken(Exception):
    pass
