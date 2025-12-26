import httpx
import os

async def get_gigachat_token():
    async with httpx.AsyncClient() as client:
        r = await client.post(
            "https://ngw.devices.sberbank.ru:9443/api/v2/oauth",
            auth=(os.getenv("GIGACHAT_CLIENT_ID"), os.getenv("GIGACHAT_SECRET")),
            headers={"Content-Type": "application/x-www-form-urlencoded", "RqUID": "any-uuid"},
            data="scope=GIGACHAT_API_PUB"
        )
        return r.json()["access_token"]

async def gigachat_query(prompt: str) -> str:
    token = await get_gigachat_token()
    async with httpx.AsyncClient() as client:
        r = await client.post(
            "https://gigachat.devices.sberbank.ru/api/v1/chat/completions",
            headers={"Authorization": f"Bearer {token}"},
            json={"model": "GigaChat", "messages": [{"role": "user", "content": prompt}]}
        )
        return r.json()["choices"][0]["message"]["content"]
