# DCScripts/DCLMMmproj.py
"""
Работа с mmproj-частью мультимодальных моделей LM Studio/Bionic.

Поиск папки модели не полагается на точное совпадение имени, полученного
из API (поле `id` в /v1/models) — LM Studio формирует это имя из
внутренних метаданных GGUF-файла, а не из структуры папок на диске
(издатель в имени может не совпадать с папкой-издателем, могут
отсутствовать/добавляться теги вроде "it", "instruct" и т.п.).
Поэтому папка модели ищется через нечёткое сопоставление токенов имени.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, List, Optional

GGUF_EXT = ".gguf"
DISABLED_EXT = ".dc"
MMPROJ_PREFIX = "mmproj"

# Минимальный порог для "неполного" совпадения токенов.
MIN_CHASTICHNOE_SOVPADENIE = 0.75


@dataclass(frozen=True)
class MmprojStatus:
    is_multimodal: bool
    enabled: bool
    model_dir: str = ""
    mmproj_path: str = ""


@dataclass(frozen=True)
class MmprojResult:
    success: bool
    status: MmprojStatus
    error: str = ""


def _tokenizirovat(stroka: str) -> List[str]:
    """Разбивает строку на алфавитно-цифровые токены в нижнем регистре."""
    return [t for t in re.split(r"[^a-z0-9]+", stroka.lower()) if t]


def _est_polnaya_podposledovatelnost(nuzhnye: List[str], dostupnye: List[str]) -> bool:
    """Проверяет, что все токены nuzhnye встречаются в dostupnye по порядку."""
    i = 0
    for tok in dostupnye:
        if i < len(nuzhnye) and tok == nuzhnye[i]:
            i += 1
    return i == len(nuzhnye)


def _dlina_lcs(a: List[str], b: List[str]) -> int:
    """Длина наибольшей общей подпоследовательности (для частичных совпадений)."""
    if not a or not b:
        return 0
    prev = [0] * (len(b) + 1)
    for x in a:
        cur = [0] * (len(b) + 1)
        for j, y in enumerate(b, start=1):
            cur[j] = prev[j - 1] + 1 if x == y else max(prev[j], cur[j - 1])
        prev = cur
    return prev[-1]


def _otsenit_sovpadenie(iskomye: List[str], kandidat: List[str]) -> Optional[float]:
    """
    Оценивает совпадение токенов имени модели (iskomye) с токенами
    имени папки-кандидата (kandidat). Возвращает коэффициент "плотности"
    совпадения в диапазоне (0..1], либо None, если совпадение слишком слабое.
    """
    if not iskomye or not kandidat:
        return None

    if _est_polnaya_podposledovatelnost(iskomye, kandidat):
        # Чем меньше "лишних" токенов в кандидате — тем точнее совпадение.
        return len(iskomye) / len(kandidat)

    sovpalo = _dlina_lcs(iskomye, kandidat)
    ratio = sovpalo / len(iskomye)
    if ratio >= MIN_CHASTICHNOE_SOVPADENIE:
        # Частичное совпадение всегда хуже полного.
        return ratio * 0.5
    return None


class DCLMMmproj:
    """Поиск и переключение mmproj-файлов мультимодальных моделей."""

    def __init__(self, log_callback: Optional[Callable[[str], None]] = None) -> None:
        self._log = log_callback or (lambda _msg: None)

    # ------------------------------------------------------------------
    # Определение корневой папки моделей
    # ------------------------------------------------------------------

    def opredelit_papku_modelei(self, lms_cli_put: Optional[Path] = None) -> Path:
        """
        Определяет папку .../models на основе пути к CLI (lms / lms.exe).

        Структура LM Studio/Bionic одинакова на всех ОС: <корень>/bin/lms[.exe],
        папка моделей — <корень>/models. Папка пользовательских данных не
        обязана совпадать с папкой установки самого приложения, поэтому
        путь к CLI — надёжный ориентир.
        """
        if lms_cli_put:
            cli_put = Path(lms_cli_put)
            koren = cli_put.parent.parent
            kandidat = koren / "models"
            if kandidat.is_dir():
                return kandidat
            self._log(f"[DCLMMmproj] Папка моделей не найдена рядом с CLI: {kandidat}")

        zapasnoy_variant = Path.home() / ".lmstudio" / "models"
        return zapasnoy_variant

    # ------------------------------------------------------------------
    # Поиск папки конкретной модели
    # ------------------------------------------------------------------

    def naiti_papku_modeli(
        self,
        model_name: str,
        models_dir: Optional[Path] = None,
        lms_cli_put: Optional[Path] = None,
    ) -> Optional[Path]:
        """
        Ищет папку модели в дереве models_dir по имени из API LM Studio/Bionic.

        Используется нечёткое сопоставление токенов, т.к. имя из API может
        не совпадать со структурой папок на диске (см. докстринг модуля).
        """
        koren = models_dir or self.opredelit_papku_modelei(lms_cli_put)
        if not koren.is_dir():
            self._log(f"[DCLMMmproj] Папка моделей не существует: {koren}")
            return None

        iskomye_varianty = self._varianty_tokenov_imeni(model_name)

        luchshaya_papka: Optional[Path] = None
        luchshaya_otsenka = -1.0

        for tekuschaya_papka, _podpapki, faily in os.walk(koren):
            faily_modeli = [
                f for f in faily
                if f.lower().endswith(GGUF_EXT) or f.lower().endswith(DISABLED_EXT)
            ]
            if not faily_modeli:
                continue  # промежуточная папка-организатор (издатель и т.п.)

            put_papki = Path(tekuschaya_papka)
            tokeny_papki = self._tokeny_kandidata(put_papki.name)

            for iskomye in iskomye_varianty:
                otsenka = _otsenit_sovpadenie(iskomye, tokeny_papki)
                if otsenka is not None and otsenka > luchshaya_otsenka:
                    luchshaya_otsenka = otsenka
                    luchshaya_papka = put_papki

        if luchshaya_papka is None:
            self._log(f"[DCLMMmproj] Папка модели не найдена по имени: {model_name}")
        return luchshaya_papka

    def _varianty_tokenov_imeni(self, model_name: str) -> List[List[str]]:
        """
        Варианты токенизации имени модели: с издателем и без.
        Издатель в имени из API часто не совпадает с папкой-издателем на
        диске (относится к автору модели, а не к тому, кто её упаковал).
        """
        polnoe = _tokenizirovat(model_name)
        if "/" in model_name:
            _izdatel, slag = model_name.split("/", 1)
            bez_izdatelya = _tokenizirovat(slag)
            if bez_izdatelya != polnoe:
                return [bez_izdatelya, polnoe]
        return [polnoe]

    @staticmethod
    def _tokeny_kandidata(imya: str) -> List[str]:
        """Токенизирует имя папки, отбрасывая технический суффикс gguf."""
        tokeny = _tokenizirovat(imya)
        if tokeny and tokeny[-1] == "gguf":
            tokeny = tokeny[:-1]
        return tokeny

    # ------------------------------------------------------------------
    # Поиск mmproj-файла внутри папки модели
    # ------------------------------------------------------------------

    def naiti_mmproj_fail(self, model_dir: Path) -> Optional[Path]:
        """Ищет файл mmproj*.gguf или mmproj*.dc в папке модели (рекурсивно)."""
        if not model_dir or not Path(model_dir).is_dir():
            return None

        for tekuschaya_papka, _podpapki, faily in os.walk(model_dir):
            for imya_faila in faily:
                nizhnee = imya_faila.lower()
                if nizhnee.startswith(MMPROJ_PREFIX) and (
                    nizhnee.endswith(GGUF_EXT) or nizhnee.endswith(DISABLED_EXT)
                ):
                    return Path(tekuschaya_papka) / imya_faila
        return None

    # ------------------------------------------------------------------
    # Статус и переключение
    # ------------------------------------------------------------------

    def proverit_status(
        self,
        model_name: str,
        models_dir: Optional[Path] = None,
        lms_cli_put: Optional[Path] = None,
    ) -> MmprojStatus:
        model_dir = self.naiti_papku_modeli(model_name, models_dir, lms_cli_put)
        if model_dir is None:
            return MmprojStatus(is_multimodal=False, enabled=False)

        mmproj_put = self.naiti_mmproj_fail(model_dir)
        if mmproj_put is None:
            return MmprojStatus(is_multimodal=False, enabled=False, model_dir=str(model_dir))

        vklyucheno = mmproj_put.suffix.lower() == GGUF_EXT
        return MmprojStatus(
            is_multimodal=True,
            enabled=vklyucheno,
            model_dir=str(model_dir),
            mmproj_path=str(mmproj_put),
        )

    def vklyuchit(
        self,
        model_name: str,
        models_dir: Optional[Path] = None,
        lms_cli_put: Optional[Path] = None,
    ) -> MmprojResult:
        return self._pereklyuchit(model_name, True, models_dir, lms_cli_put)

    def vyklyuchit(
        self,
        model_name: str,
        models_dir: Optional[Path] = None,
        lms_cli_put: Optional[Path] = None,
    ) -> MmprojResult:
        return self._pereklyuchit(model_name, False, models_dir, lms_cli_put)

    def _pereklyuchit(
        self,
        model_name: str,
        vkliuchit: bool,
        models_dir: Optional[Path],
        lms_cli_put: Optional[Path],
    ) -> MmprojResult:
        model_dir = self.naiti_papku_modeli(model_name, models_dir, lms_cli_put)
        if model_dir is None:
            soobschenie = f"Папка модели не найдена: {model_name}"
            self._log(f"[DCLMMmproj] {soobschenie}")
            return MmprojResult(False, MmprojStatus(False, False), soobschenie)

        mmproj_put = self.naiti_mmproj_fail(model_dir)
        if mmproj_put is None:
            soobschenie = f"mmproj-файл не найден в папке: {model_dir}"
            self._log(f"[DCLMMmproj] {soobschenie}")
            return MmprojResult(False, MmprojStatus(False, False, str(model_dir)), soobschenie)

        rasshirenie_tsel = GGUF_EXT if vkliuchit else DISABLED_EXT
        novyj_put = mmproj_put.with_suffix(rasshirenie_tsel)

        if mmproj_put.suffix.lower() == rasshirenie_tsel:
            status = MmprojStatus(True, vkliuchit, str(model_dir), str(mmproj_put))
            return MmprojResult(True, status)

        if novyj_put.exists():
            soobschenie = f"Файл назначения уже существует: {novyj_put}"
            self._log(f"[DCLMMmproj] {soobschenie}")
            tekuschee_sostoyanie = mmproj_put.suffix.lower() == GGUF_EXT
            return MmprojResult(
                False,
                MmprojStatus(True, tekuschee_sostoyanie, str(model_dir), str(mmproj_put)),
                soobschenie,
            )

        try:
            mmproj_put.rename(novyj_put)
        except OSError as oshibka:
            soobschenie = f"Не удалось переименовать mmproj-файл: {oshibka}"
            self._log(f"[DCLMMmproj] {soobschenie}")
            tekuschee_sostoyanie = mmproj_put.suffix.lower() == GGUF_EXT
            return MmprojResult(
                False,
                MmprojStatus(True, tekuschee_sostoyanie, str(model_dir), str(mmproj_put)),
                soobschenie,
            )

        deistvie = "включён" if vkliuchit else "выключен"
        self._log(f"[DCLMMmproj] mmproj {deistvie} для модели {model_name}: {novyj_put}")
        status = MmprojStatus(True, vkliuchit, str(model_dir), str(novyj_put))
        return MmprojResult(True, status)
