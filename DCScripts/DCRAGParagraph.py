import re

def razbit_na_abzaci(text: str) -> list[str]:
    """
    Paragraph-based Chunking:
    1 абзац = 1 чанк.
    Абзац определяется как блок текста между пустыми строками.
    """
    if not text:
        return []
    abzaci = [x.strip() for x in re.split(r"\n\s*\n", text) if x.strip()]
    return abzaci


def poluchit_chanki(text: str) -> list[str]:
    """Публичная функция для режима 1."""
    return razbit_na_abzaci(text)
