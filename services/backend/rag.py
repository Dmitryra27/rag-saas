from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
import os

qdrant = QdrantClient(host="qdrant", port=6333)

async def store_document(doc_id: int, text: str):
    # Здесь можно использовать Yandex Embeddings API
    # Для упрощения — заглушка
    embedding = [0.1] * 256
    qdrant.upsert(
        collection_name="documents",
        points=[PointStruct(id=doc_id, vector=embedding, payload={"text": text})]
    )

async def search_documents(query: str) -> list:
    # Аналогично — заглушка
    embedding = [0.1] * 256
    hits = qdrant.search(collection_name="documents", query_vector=embedding, limit=3)
    return [hit.payload["text"] for hit in hits]
