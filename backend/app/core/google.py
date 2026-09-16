"""Thin, fakeable Google ID token verification.

In production, verifies against Google's JWKS.
In tests, this module is monkeypatched to return a controlled result.
"""

import httpx
from jwt import decode, InvalidTokenError


GOOGLE_JWKS_URL = "https://www.googleapis.com/oauth2/v3/certs"


async def verify_google_token(id_token: str, client_id: str) -> dict:
    """Verify a Google ID token and return its payload.

    Raises InvalidGoogleToken if verification fails.
    """
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(GOOGLE_JWKS_URL)
            resp.raise_for_status()
            jwks = resp.json()

        from jwt import PyJWKSet
        signing_keys = PyJWKSet.from_dict(jwks).keys

        payload = decode(
            id_token,
            key=signing_keys,
            algorithms=["RS256"],
            audience=client_id,
            options={"verify_exp": True},
        )
        return payload
    except (InvalidTokenError, Exception) as e:
        raise InvalidGoogleToken(str(e))


class InvalidGoogleToken(Exception):
    pass
