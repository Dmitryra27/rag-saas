from fastapi import FastAPI, File, UploadFile, Form
from rag import store_document, search_documents
from gigachat_api import gigachat_query
from yandex_gpt import yandex_gpt_query
import uuid

app = FastAPI(title="RAG SaaS API")

@app.post("/upload/")
async def upload_doc(file: UploadFile = File(...)):
    content = (await file.read()).decode("utf-8")
    doc_id = hash(str(uuid.uuid4()))
    await store_document(doc_id, content)
    return {"doc_id": doc_id}

@app.post("/query/")
async def rag_query(query: str = Form(...), model: str = Form("yandex")):
    context = await search_documents(query)
    prompt = f"Контекст: {' '.join(context)}\n\nВопрос: {query}"
    if model == "gigachat":
        answer = await gigachat_query(prompt)
    else:
        answer = await yandex_gpt_query(prompt)
    return {"answer": answer}
