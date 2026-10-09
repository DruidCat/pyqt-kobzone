import re
from pathlib import Path


def ochistit_text(tekst: str) -> str:
    if not tekst:
        return ""

    tekst = tekst.replace("\x00", " ")
    tekst = tekst.replace("\r", "\n")

    # Схлопываем мусорные пробелы и пустые строки
    tekst = re.sub(r"[ \t]+\n", "\n", tekst)
    tekst = re.sub(r"\n{3,}", "\n\n", tekst)
    tekst = re.sub(r"[ \t]{2,}", " ", tekst)

    return tekst.strip()


def izvlech_text_iz_pdf_po_stranicam(put_pdf: str) -> list[str]:
    """
    Возвращает список строк: текст по страницам (1 элемент = 1 страница).
    Если PDF сканированный без текстового слоя — страницы будут пустыми.
    """
    from pypdf import PdfReader

    pdf_path = Path(put_pdf)
    if not pdf_path.exists():
        raise FileNotFoundError(f"PDF не найден: {put_pdf}")

    reader = PdfReader(str(pdf_path))

    # Если зашифрован — пробуем пустой пароль
    if getattr(reader, "is_encrypted", False):
        try:
            reader.decrypt("")  # type: ignore[attr-defined]
        except Exception:
            pass

    spisok_stranic: list[str] = []

    for nt_stranica, stranica in enumerate(reader.pages, 1):
        try:
            tekst = stranica.extract_text() or ""
        except Exception:
            tekst = ""

        tekst = ochistit_text(tekst)
        spisok_stranic.append(tekst)

        # ---- ОТЛАДКА (по запросу) ----
        # print(f"\n--- PDF: {pdf_path.name} | страница: {nt_stranica} ---", flush=True)
        # print(tekst[:1500], flush=True)  # первые 1500 символов страницы

    return spisok_stranic
