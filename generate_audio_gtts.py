# generate_audio_gtts.py
# 使い方:
#   python generate_audio_gtts.py
# 処理:
#   - assets/kanji_data.json を読み込み
#   - 各漢字の kunyomi / onyomi から日本語音声を gTTS で生成 (mp3)
#   - assets/audio/ に保存
#   - audioKunyomi / audioOnyomi を追記した JSON を
#     assets/kanji_data_with_audio.json として出力

import json
import os
from pathlib import Path
from gtts import gTTS

PROJECT_ROOT = Path(__file__).resolve().parent
ASSETS_DIR = PROJECT_ROOT / "assets"
JSON_IN = ASSETS_DIR / "kanji_data.json"
JSON_OUT = ASSETS_DIR / "kanji_data_with_audio.json"
AUDIO_DIR = ASSETS_DIR / "audio"

# 片仮名→平仮名（音読みを自然に読ませるため）
def kata_to_hira(s: str) -> str:
    res = []
    for ch in s:
        code = ord(ch)
        # 「ァ(0x30A1)〜ン(0x30F3)」を「ぁ(0x3041)〜ん(0x3093)」へ
        if 0x30A1 <= code <= 0x30F3:
            res.append(chr(code - 0x60))
        # 「ヴ(0x30F4)」などの濁点もひとまず単純変換
        elif ch == "ヴ":
            res.append("ゔ")
        else:
            res.append(ch)
    return "".join(res)

def safe_filename(text: str) -> str:
    """
    Windowsでも使えるように、ファイル名に不適切な文字を除去。
    （日本語はそのままでOK。スラッシュやコロン等のみ排除）
    """
    invalid = '<>:"/\\|?*'
    for c in invalid:
        text = text.replace(c, "")
    # 先頭・末尾の空白を削る
    return text.strip()

def main():
    if not JSON_IN.exists():
        raise FileNotFoundError(f"入力JSONが見つかりません: {JSON_IN}")
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)

    with JSON_IN.open("r", encoding="utf-8") as f:
        data = json.load(f)

    for item in data:
        kanji = item.get("kanji", "")
        kunyomi = item.get("kunyomi", []) or []
        onyomi = item.get("onyomi", []) or []

        audio_kunyomi_paths = []
        audio_onyomi_paths = []

        # 訓読み：多くはひらがななので、そのままTTS
        for yomi in kunyomi:
            text = str(yomi).strip()
            if not text:
                continue
            filename = safe_filename(f"{kanji}_kun_{text}.mp3")
            out_path = AUDIO_DIR / filename
            # すでにファイルがあれば再生成しない（上書きしたいなら削除して実行）
            if not out_path.exists():
                tts = gTTS(text=text, lang="ja")
                tts.save(str(out_path))
            audio_kunyomi_paths.append(f"assets/audio/{filename}")

        # 音読み：カタカナは平仮名に変換してTTSへ渡すと自然
        for yomi in onyomi:
            text_src = str(yomi).strip()
            if not text_src:
                continue
            text = kata_to_hira(text_src)
            filename = safe_filename(f"{kanji}_on_{text}.mp3")
            out_path = AUDIO_DIR / filename
            if not out_path.exists():
                tts = gTTS(text=text, lang="ja")
                tts.save(str(out_path))
            audio_onyomi_paths.append(f"assets/audio/{filename}")

        # 既存フィールドはそのままに、音声パス配列を追記
        item["audioKunyomi"] = audio_kunyomi_paths
        item["audioOnyomi"] = audio_onyomi_paths

    with JSON_OUT.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("✅ 完了しました。生成結果:")
    print(f"- 音声: {AUDIO_DIR}")
    print(f"- 新JSON: {JSON_OUT}")
    print("\nアプリ側で 'assets/kanji_data_with_audio.json' を読み込むように設定してください。")

if __name__ == "__main__":
    main()
