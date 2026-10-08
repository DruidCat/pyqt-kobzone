import re


def _razbit_na_abzaci(text: str) -> list[str]:
    return [x.strip() for x in re.split(r"\n\s*\n", text) if x.strip()]


def _razbit_na_predlozheniya(text: str) -> list[str]:
    # Делим по окончанию предложения: . ! ?
    # Сохраняем знаки в тексте (они остаются в предложении)
    parts = re.split(r"(?<=[.!?])\s+", text.strip())
    return [p.strip() for p in parts if p and p.strip()]


def _razbit_na_slova(text: str) -> list[str]:
    # Простое разбиение по пробелам, но схлопываем множественные пробелы
    parts = re.split(r"\s+", text.strip())
    return [p for p in parts if p]


def _narezka_po_simvolam(text: str, chunk_razmer: int) -> list[str]:
    if chunk_razmer <= 0:
        return []
    text = text.strip()
    if not text:
        return []
    return [text[i:i + chunk_razmer].strip() for i in range(0, len(text), chunk_razmer) if text[i:i + chunk_razmer].strip()]


def _sobrat_chanki_iz_kuskov(kuski: list[str], razdelitel: str, chunk_razmer: int, chunk_overlap: int,
                            fn_razbit_krupnii_kusok) -> list[str]:
    """
    Собираем чанки из кусочков, стараясь не превышать chunk_razmer.
    Если один кусок больше chunk_razmer — дробим его более мелким методом (fn_razbit_krupnii_kusok).
    """
    chanki: list[str] = []
    tek = ""

    def dobavit_chank(ch: str):
        ch = ch.strip()
        if ch:
            chanki.append(ch)

    for kusok in kuski:
        kusok = kusok.strip()
        if not kusok:
            continue

        # Если кусок сам по себе больше chunk_razmer — дробим глубже
        if len(kusok) > chunk_razmer:
            # Сначала закрываем текущий накопленный
            if tek.strip():
                dobavit_chank(tek)
                tek = ""

            # Дробим большой кусок на более мелкие части
            melkie = fn_razbit_krupnii_kusok(kusok)
            for m in melkie:
                m = m.strip()
                if not m:
                    continue
                if len(m) <= chunk_razmer:
                    dobavit_chank(m)
                else:
                    # последняя страховка
                    for hard in _narezka_po_simvolam(m, chunk_razmer):
                        dobavit_chank(hard)
            continue

        # Пытаемся добавить кусок в текущий чанк
        if not tek:
            nov = kusok
        else:
            nov = tek + razdelitel + kusok

        if len(nov) <= chunk_razmer:
            tek = nov
        else:
            # Закрываем текущий
            dobavit_chank(tek)

            # Делаем overlap
            if chunk_overlap > 0:
                hvost = tek[-chunk_overlap:]
                hvost = hvost.strip()
                tek = hvost
                if tek:
                    nov2 = tek + razdelitel + kusok
                else:
                    nov2 = kusok
            else:
                tek = ""
                nov2 = kusok

            # Если всё равно не влезло — значит кусок крупный (или overlap слишком большой)
            if len(nov2) <= chunk_razmer:
                tek = nov2
            else:
                # Кусок не влезает даже один — дробим глубже
                melkie = fn_razbit_krupnii_kusok(kusok)
                for m in melkie:
                    m = m.strip()
                    if not m:
                        continue
                    if len(m) <= chunk_razmer:
                        dobavit_chank(m)
                    else:
                        for hard in _narezka_po_simvolam(m, chunk_razmer):
                            dobavit_chank(hard)
                tek = ""

    if tek.strip():
        dobavit_chank(tek)

    return chanki


def poluchit_chanki(text: str, chunk_razmer: int, chunk_overlap: int) -> list[str]:
    """
    Рекурсивный чанкинг по символам:
    абзацы -> предложения -> слова -> жёсткая нарезка по символам.

    chunk_razmer / chunk_overlap — в символах.
    """
    text = (text or "").strip()
    if not text:
        return []

    if chunk_razmer <= 0:
        return [text]

    if chunk_overlap < 0:
        chunk_overlap = 0
    if chunk_overlap >= chunk_razmer:
        chunk_overlap = max(0, chunk_razmer // 5)

    # Уровень 1: абзацы
    abzaci = _razbit_na_abzaci(text)

    def razbit_predlozheniyami(t: str) -> list[str]:
        predl = _razbit_na_predlozheniya(t)

        def razbit_slovami(tt: str) -> list[str]:
            slova = _razbit_na_slova(tt)

            def hard(ttt: str) -> list[str]:
                return _narezka_po_simvolam(ttt, chunk_razmer)

            return _sobrat_chanki_iz_kuskov(
                slova,
                razdelitel=" ",
                chunk_razmer=chunk_razmer,
                chunk_overlap=chunk_overlap,
                fn_razbit_krupnii_kusok=hard
            )

        return _sobrat_chanki_iz_kuskov(
            predl,
            razdelitel=" ",
            chunk_razmer=chunk_razmer,
            chunk_overlap=chunk_overlap,
            fn_razbit_krupnii_kusok=razbit_slovami
        )

    return _sobrat_chanki_iz_kuskov(
        abzaci,
        razdelitel="\n\n",
        chunk_razmer=chunk_razmer,
        chunk_overlap=chunk_overlap,
        fn_razbit_krupnii_kusok=razbit_predlozheniyami
    )
