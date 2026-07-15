#!/usr/bin/env python3
import re
import sys

path = "scripts/generate_metadata_all.py"
content = open(path).read()

# Using regexes to make the substitution robust against subtle combining characters in complex scripts
regex_replacements = [
    # 1. gu-IN
    (r'"subtitle": "બ્રિજ બિડિંગ અને.*?",', '"subtitle": "બ્રિજ બિડિંગ અને અભ્યાસ રમત",'),
    (r'"keywords": "બ્રિજ,બિડિંગ,.*?",', '"keywords": "બ્રિજ,બિડિંગ,પત્તા,શીખો,ટ્યુટર,શરૂઆતી,પાઠ,ડ્રિલ,ડિફેન્સ,ડિક્લેરર,અਭ્યાસ,રમત,પોઇન્ટ,સ્કોર,મજા,ખેલ",'),
    
    # 2. hi
    (r'"subtitle": "ब्रिज बिडिंग और.*?",', '"subtitle": "ब्रिज बिडिंग और play अभ्यास",'), # Wait, let's use "ब्रिज बिडिंग और प्ले अभ्यास"
    (r'"subtitle": "ब्रिज बिडिंग और play अभ्यास",', '"subtitle": "ब्रिज बिडिंग और प्ले अभ्यास",'),
    
    # 3. it
    (r'"keywords": "bridge,licita,carte,imparare,tutor,principiante,lezione,esercizio,difesa,dichiarante,pratica",', '"keywords": "bridge,licita,carte,imparare,tutor,principiante,lezione,esercizio,difesa,dichiarante,pratica,tiro",'),
    
    # 4. ja
    (r'"subtitle": "初心者向けコントラクトブリッジ叫牌とカード練習",', '"subtitle": "初心者向けコントラクトブリッジ叫牌とカードの実戦練習",'),
    (r'"keywords": "ブリッジ,叫牌,カード,トランプ,学習,初心者,レッスン,ドリル,防衛,宣言者,練習,コントラクト,ゲーム,スコア,ルール,上達,必勝,問題集,入門",', '"keywords": "ブリッジ,叫牌,カード,トランプ,学習,初心者,レッスン,ドリル,防衛,宣言者,練習,コントラクト,ゲーム,スコア,ルール,上達,必勝,問題集,入門,対戦,勝率,解説,コツ,満点,基本,攻略",'),
    
    # 5. kn-IN
    (r'"name": "Bridge Trainer: ಬ್ರಿಡ್ಜ್ ಕಲಿಯಿರಿ",', '"name": "Bridge: ಬ್ರಿಡ್ಜ್ ಕಲಿಯಿರಿ",'),
    (r'"keywords": "ಬ್ರಿಡ್ಜ್,ಬಿಡ್ಡಿಂಗ್,ಎಲೆಗಳು,ಕಲಿಯಿರಿ,ಬೋಧಕ,ಆರಂಭಿಕ,ಪಾಠ,ಅಭ್ಯಾಸ,ರಕ್ಷಣೆ,ಘೋಷಕ,ತರಬೇತಿ,ಆಟ,ಅಂಕಗಳು,ಸ್ಕೋರ್",', '"keywords": "ಬ್ರಿಡ್ಜ್,ಬಿಡ್ಡಿಂಗ್,ಎಲೆಗಳು,ಕಲಿಯಿರಿ,ಬೋಧಕ,ಆರಂಭಿಕ,ಪಾಠ,ಅಭ್ಯಾಸ,ರಕ್ಷಣೆ,ಘೋಷಕ,ತರಬೇತಿ,ಆಟ,ಅಂಕಗಳು,ಸ್ಕೋರ್,ಖೇಲ್",'),
    
    # 6. ko
    (r'"keywords": "브릿지,비딩,카드,트럼프,학습,초보자,레슨,드릴,수비,디클레어러,연습,콘트랙트,게임,룰,점수,강좌,전략,문제,도우미,퀴즈",', '"keywords": "브릿지,비딩,카드,트럼프,학습,초보자,레슨,드릴,수비,디클레어러,연습,콘트랙트,게임,룰,점수,강좌,전략,문제,도우미,퀴즈,특강,공략,기초,해설,공부,비법,가이드,놀이,상식,훈련",'),
    
    # 7. ml-IN
    (r'"keywords": "ബ്രിഡ്ജ്,ബിഡ്ഡിംഗ്,കാർഡുകൾ,പഠിക്കാം,ട్యూട്ടർ,തുടക്കക്കാരൻ,പാഠം,പരിശീലനം,പ്രതിരോധം,കളിക്കാരൻ,ആട്ട,സ്കോർ,കളി",', '"keywords": "ബ്രിഡ്ജ്,ബിഡ്ഡിംഗ്,കാർഡുകൾ,പഠിക്കാം,ട്യൂട്ടർ,തുടക്കക്കാരൻ,പാഠം,പരിശീലനം,പ്രതിരോധം,കളിക്കാരൻ,ആട്ട,സ്കോർ",'),

    # 8. mr-IN
    (r'"subtitle": "वरिष्ठ ब्रिज बिडिंग व.*?",', '"subtitle": "ब्रिज बिडिंग व पत्ते सराव",'),
    
    # 9. pa-IN
    (r'"keywords": "ਬ੍ਰਿਜ,ਬੋਲੀ,.*?",', '"keywords": "ਬ੍ਰਿਜ,ਬੋਲੀ,ਪੱਤੇ,ਸਿੱਖੋ,ਟਿਊਟਰ,ਸ਼ੁਰੂਆਤੀ,ਪਾਠ,ਡ੍ਰਿਲ,ਡਿਫੈਂਸ,ਡਿਕਲੇਅਰਰ,ਅਭਿਆਸ,ਖੇਡ,ਸਕੋਰ,ਪੁਆਇੰਟ,ਮਜ਼ੇਦਾਰ,ਖੇਲ",'),
    
    # 10. pl
    (r'"keywords": "brydż,licytacja,karty,nauka,tutor,początkujący,lekcja,ćwiczenie,obrona,rozgrywający,praktyka,gra,karta",', '"keywords": "brydż,licytacja,karty,nauka,tutor,początkujący,lekcja,ćwiczenie,obrona,rozgrywający,praktyka,gra",'),
    
    # 11. ro
    (r'"keywords": "bridge,licitație,cărți,învățare,tutor,începător,lecție,exercițiu,apărare,declarant,practică,joc,carte",', '"keywords": "bridge,licitație,cărți,învățare,tutor,începător,lecție,exercițiu,apărare,declarant,practică,joc",'),
    
    # 12. sk
    (r'"keywords": "bridž,licitácia,karty,učenie,lektor,začiatočník,lekcia,cvičenie,obrana,hlavný hráč,tréning,kvíz,hra,list",', '"keywords": "bridž,licitácia,karty,učenie,lektor,začiatočník,lekcia,cvičenie,obrana,hlavný hráč,tréning,kvíz,hra",'),
    
    # 13. ta-IN
    (r'"keywords": "பிரிட்ஜ்,ஏலம்,.*?",', '"keywords": "பிரிட்ஜ்,ஏலம்,அட்டைகள்,கற்க,ஆசிரியர்,தொடக்கநிலை,பாடம்,பயிற்సి,பாதுகாப்பு,ஏலதாரர்,விளையாட,வினாடிவினா",'),
    
    # 14. te-IN
    (r'"keywords": "బ్రిడ్జ్,బిడ్డింగ్,.*?",', '"keywords": "బ్రిడ్జ్,బిడ్డింగ్,కార్డులు,నేర్చుకోండి,ట్యూటర్,ప్రారంభకులు,పాఠం,ప్రాక్టీस,రక్షణ,డిక్లేరర్,ఆట",'),
    
    # 15. zh-Hans
    (r'"subtitle": "初学者无压力合约桥牌的叫牌与打牌防守核心练习",', '"subtitle": "初学者无压力合约桥牌的叫牌与打牌防守核心特训",'),
    (r'"keywords": "桥牌,叫牌,打牌,扑克,学习,新手,课程,训练,防守,庄家,练习,合约,游戏,得分,规则,黄卡,大牌点,超墩,双人赛,防守首攻,飞牌",', '"keywords": "桥牌,叫牌,打牌,扑克,学习,新手,课程,训练,防守,庄家,练习,合约,游戏,得分,规则,黄卡,大牌点,超墩,双人赛,防守首攻,飞牌,桥艺,定约,牌局,首攻,跟牌,叫牌室,赢墩,黑桃,红心",'),
    
    # 16. zh-Hant
    (r'"subtitle": "初學者無壓力合約橋牌的叫牌與打牌防守核心練習",', '"subtitle": "初學者無壓力合約橋牌的叫牌與打牌防守核心特訓",'),
    (r'"keywords": "橋牌,叫牌,打牌,撲克,學習,新手,課程,訓練,防守,庄家,練習,合約,遊戲,得分,規則,黃卡,大牌點,超墩,雙人賽,防守首攻,飛牌",', '"keywords": "橋牌,叫牌,打牌,撲克,學習,新手,課程,訓練,防守,庄家,練習,合約,遊戲,得分,規則,黃卡,大牌點,超墩,雙人賽,防守首攻,飛牌,橋藝,定約,牌局,首攻,跟牌,叫牌室,贏墩,黑桃,紅心",'),
]

for pattern, repl in regex_replacements:
    content, count = re.subn(pattern, repl, content)
    if count == 0:
        print(f"WARNING: pattern not found: {pattern}")

open(path, "w").write(content)
print("Finished patching generate_metadata_all.py successfully!")
