import httpx
import os

async def yandex_gpt_query(prompt: str) -> str:
    async with httpx.AsyncClient() as client:
        r = await client.post(
            "https://llm.api.cloud.yandex.net/foundationModels/v1/completion",
            headers={
                "Authorization": f"Api-Key {os.getenv('YC_API_KEY')}",
                "Content-Type": "application/json"
            },
            json={
                "modelUri": "gpt://b1g.../yandexgpt/latest",
                "completionOptions": {"stream": False, "temperature": 0.6, "maxTokens": 2000},
                "messages": [{"role": "user", "text": prompt}]
            }
        )
        return r.json()["result"]["alternatives"][0]["message"]["text"]
