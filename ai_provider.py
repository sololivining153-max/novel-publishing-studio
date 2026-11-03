import httpx
from .config import settings

class AIConfigurationError(Exception):
    pass

class AIProviderError(Exception):
    pass

async def generate_text(system_prompt: str, user_prompt: str) -> tuple[str, int, int]:
    if not settings.openai_api_key:
        raise AIConfigurationError(
            "OpenAI is not configured. Add OPENAI_API_KEY to the backend .env file."
        )

    url = f"{settings.openai_base_url.rstrip('/')}/responses"
    payload = {
        "model": settings.openai_model,
        "instructions": system_prompt,
        "input": user_prompt,
        "max_output_tokens": settings.max_outline_tokens,
    }
    headers = {
        "Authorization": f"Bearer {settings.openai_api_key}",
        "Content-Type": "application/json",
    }
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(180.0)) as client:
            response = await client.post(url, headers=headers, json=payload)
    except httpx.HTTPError as exc:
        raise AIProviderError(f"Could not contact AI provider ({exc.__class__.__name__}).") from exc

    if response.status_code >= 400:
        raise AIProviderError(f"AI provider returned HTTP {response.status_code}.")

    data = response.json()
    texts = []
    for item in data.get("output", []):
        if item.get("type") == "message":
            for part in item.get("content", []):
                if part.get("type") == "output_text" and part.get("text"):
                    texts.append(part["text"])
    output = "\n".join(texts).strip()
    if not output:
        raise AIProviderError("The AI provider returned an empty response.")
    usage = data.get("usage", {}) or {}
    return output, int(usage.get("input_tokens", 0)), int(usage.get("output_tokens", 0))
