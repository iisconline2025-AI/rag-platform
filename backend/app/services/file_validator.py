"""File upload validator — MIME-type + magic-bytes + size enforcement.

Used by /admin/documents/upload (admin web) and the WhatsApp webhook
(ephemeral). Defense-in-depth: do NOT trust the client-supplied Content-Type
header alone. Always sniff the magic bytes.
"""
from __future__ import annotations

from dataclasses import dataclass

from fastapi import HTTPException
from app.core.config import settings


# Magic-byte signatures (first N bytes) for the file types we accept.
# Reference: https://en.wikipedia.org/wiki/List_of_file_signatures
_MAGIC: dict[str, list[bytes]] = {
    "application/pdf": [b"%PDF-"],
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": [b"PK\x03\x04"],
    "text/plain": [],  # text has no reliable magic; size + extension check only
    "image/png": [b"\x89PNG\r\n\x1a\n"],
    "image/jpeg": [b"\xff\xd8\xff"],
}


@dataclass
class ValidatedUpload:
    filename: str
    content: bytes
    mime_type: str
    size_bytes: int


def validate_upload(
    *,
    filename: str,
    content: bytes,
    declared_mime: str | None = None,
    max_bytes: int | None = None,
) -> ValidatedUpload:
    """Raise HTTPException(400/413/415) on bad uploads.  Returns ValidatedUpload."""
    cap = max_bytes if max_bytes is not None else settings.MAX_UPLOAD_BYTES
    if len(content) == 0:
        raise HTTPException(400, "Empty file upload")
    if len(content) > cap:
        raise HTTPException(413, f"File exceeds {cap} bytes")

    allowed = settings.allowed_mime_set
    mime = (declared_mime or "").lower().strip()
    if mime not in allowed:
        raise HTTPException(415, f"Disallowed MIME type: {declared_mime!r}. Allowed: {sorted(allowed)}")

    # Verify magic bytes match declared MIME (skip for text/plain — no signature).
    signatures = _MAGIC.get(mime, [])
    if signatures:
        head = content[:16]
        if not any(head.startswith(sig) for sig in signatures):
            raise HTTPException(
                415,
                f"File contents do not match declared type {mime}. "
                "Magic-byte check failed (possible spoofed upload).",
            )

    return ValidatedUpload(
        filename=filename,
        content=content,
        mime_type=mime,
        size_bytes=len(content),
    )
