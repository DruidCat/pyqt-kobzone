import re

def razbit_na_abzaci(text: str) -> list[str]:
    # Такая же логика как в Paragraph режиме, нужна для "умной" упаковки абзацев
    if not text:
        return []
    abzaci = [x.strip() for x in re.split(r"\n\s*\n", text) if x.strip()]
    return abzaci

def _razbit_tokeni_oknami(tokenizer, tokeni: list[int], max_tokenov: int, overlap_tokenov: int) -> list[str]:
    if max_tokenov <= 0:
        return []

    if overlap_tokenov < 0:
        overlap_tokenov = 0
    if overlap_tokenov >= max_tokenov:
        overlap_tokenov = max(0, max_tokenov // 5)

    step = max(1, max_tokenov - overlap_tokenov)

    chanki = []
    for start in range(0, len(tokeni), step):
        okno = tokeni[start:start + max_tokenov]
        if not okno:
            break

        text_okna = tokenizer.decode(okno, skip_special_tokens=True).strip()
        if text_okna:
            chanki.append(text_okna)

        if start + max_tokenov >= len(tokeni):
            break

    return chanki

def razbit_text_sliding(text: str, tokenizer, max_tokenov: int, perekritie_proc: float = 0.20) -> list[str]:
    """
    Token-aware Chunking (Sliding Window) с перекрытием.
    Оптимизация: кэшируем длины абзацев в токенах, чтобы не токенизировать одно и то же 5-20 раз.
    """
    abzaci = razbit_na_abzaci(text)
    if not abzaci:
        return []

    overlap_tokenov = int(max_tokenov * perekritie_proc)

    # --- КЭШ: абзац -> длина в токенах ---
    kesh_token_dliny: dict[str, int] = {}

    def tokenov_v_abzace(abzac: str) -> int:
        dlina = kesh_token_dliny.get(abzac)
        if dlina is not None:
            return dlina

        ids = tokenizer(
            abzac,
            add_special_tokens=False,
            truncation=False,
            return_attention_mask=False
        )["input_ids"]
        dlina = len(ids)
        kesh_token_dliny[abzac] = dlina
        return dlina

    chanki: list[str] = []
    tek_abzaci: list[str] = []
    tek_tokenov = 0
    overlap_abzaci: list[str] = []

    def sobrat_overlap(spisok_abzacev: list[str]) -> list[str]:
        if overlap_tokenov <= 0:
            return []
        result = []
        s = 0
        for a in reversed(spisok_abzacev):
            t = tokenov_v_abzace(a)
            result.append(a)
            s += t
            if s >= overlap_tokenov:
                break
        result.reverse()
        return result

    def sbrosit_chank():
        nonlocal tek_abzaci, tek_tokenov, overlap_abzaci
        if tek_abzaci:
            chanki.append("\n\n".join(tek_abzaci).strip())
            overlap_abzaci = sobrat_overlap(tek_abzaci)
        tek_abzaci = []
        tek_tokenov = 0

    for abzac in abzaci:
        if not abzac:
            continue

        # --- ВАЖНО: для гигантского абзаца получаем token ids ОДИН РАЗ ---
        # Чтобы не делать: 1 раз для длины + 2 раз для tokeni
        # Поэтому сначала токенизируем, потом решаем.
        encoded = tokenizer(
            abzac,
            add_special_tokens=False,
            truncation=False,
            return_attention_mask=False
        )
        tokeni = encoded["input_ids"]
        t = len(tokeni)
        kesh_token_dliny[abzac] = t  # кладём в кэш

        # Абзац-гигант режем окнами
        if t > max_tokenov:
            sbrosit_chank()
            okna = _razbit_tokeni_oknami(tokenizer, tokeni, max_tokenov, overlap_tokenov)
            chanki.extend(okna)
            overlap_abzaci = []  # overlap уже есть окнами
            continue

        # При старте нового чанка добавляем overlap-абзацы
        if not tek_abzaci and overlap_abzaci:
            for oa in overlap_abzaci:
                ot = tokenov_v_abzace(oa)
                if tek_tokenov + ot <= max_tokenov:
                    tek_abzaci.append(oa)
                    tek_tokenov += ot
                else:
                    break

        # Влезает — добавляем
        if tek_tokenov + t <= max_tokenov:
            tek_abzaci.append(abzac)
            tek_tokenov += t
        else:
            # Закрываем чанк и начинаем новый
            sbrosit_chank()

            # Новый чанк снова: overlap + текущий абзац
            if overlap_abzaci:
                for oa in overlap_abzaci:
                    ot = tokenov_v_abzace(oa)
                    if tek_tokenov + ot <= max_tokenov:
                        tek_abzaci.append(oa)
                        tek_tokenov += ot
                    else:
                        break

            tek_abzaci.append(abzac)
            tek_tokenov += t

    sbrosit_chank()
    return chanki

def poluchit_chanki(text: str, tokenizer, max_tokenov: int, perekritie_proc: float = 0.20) -> list[str]:
    """Публичная функция для режима 2."""
    return razbit_text_sliding(text, tokenizer, max_tokenov, perekritie_proc=perekritie_proc)
