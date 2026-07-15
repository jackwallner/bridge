#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate high-quality ASO-optimized localized App Store metadata for all 50 locales with strict validation."""

import os
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "fastlane" / "metadata"

def write_meta(locale: str, name: str, content: str):
    p = META / locale / f"{name}.txt"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n", encoding="utf-8")

# High-quality ASO translations for all 50 locales
DATA = {
    "en-US": {
        "name": "Bridge Trainer: Learn & Bid",
        "subtitle": "Bridge Bidding & Card Practice",
        "keywords": "bridge,bidding,cards,contract,learn,tutor,beginner,lesson,drill,defense,declarer,practice,quiz,play",
        "promotional_text": "Five-minute bridge drills for bidding, declarer play, and defense. Learn the why behind every call and card.",
        "release_notes": "Welcome to Bridge Trainer. Practice rules, opening bids, declarer play, and defense in four free rooms.",
        "description": """Build real contract bridge instincts in five-minute sessions.

Bridge Trainer turns the parts that beginners need most into quick, focused drills. There are no opponents, no timers, and no pressure. Count points, choose an opening bid, plan the play, and learn defensive habits with the reason behind every answer.

FOUR FREE PRACTICE ROOMS

THE CARD ROOM
Learn card rank, high-card points, tricks, trump, contracts, and table roles.

THE AUCTION ROOM
Practice a beginner Standard American framework. Read 13-card hands and choose between pass, a suit opening, and 1NT.

THE DECLARER ROOM
Count winners, draw trump, establish long suits, finesse, and choose the right card in table situations.

THE DEFENSE ROOM
Train opening leads, sequences, third-hand play, suit returns, and partnership habits.

BRIDGE+ (OPTIONAL)
Everything above stays free. Bridge+ adds extra practice in each beginner room and unlocks the Master Tables, with conventions, advanced card play, and duplicate strategy.

BUILT FOR LEARNING
Swipeable coaching cards, quick quizzes, realistic 13-card hands, card-play scenarios, streaks, and a daily mixed session that brings missed material back.

Bridge Trainer uses a beginner Standard American framework. Partnership agreements vary, so confirm conventions with your partner.

SUBSCRIPTIONS
Bridge+ is available by auto-renewing subscription or a one-time purchase: Monthly $1.99/month, Yearly $9.99/year (both include a 1-week free trial), or Lifetime $29.99 one-time. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Account Settings on your device. Terms of Use (Apple's standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Privacy Policy: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "en-GB": {
        "name": "Bridge Trainer: Learn & Bid",
        "subtitle": "Bridge Bidding & Card Practice",
        "keywords": "bridge,bidding,cards,contract,learn,tutor,beginner,lesson,drill,defence,declarer,practice,quiz,play",
        "promotional_text": "Five-minute bridge drills for bidding, declarer play, and defence. Learn the why behind every call and card.",
        "release_notes": "Welcome to Bridge Trainer. Practice rules, opening bids, declarer play, and defence in four free rooms.",
        "description": """Build real contract bridge instincts in five-minute sessions.

Bridge Trainer turns the parts that beginners need most into quick, focused drills. There are no opponents, no timers, and no pressure. Count points, choose an opening bid, plan the play, and learn defensive habits with the reason behind every answer.

FOUR FREE PRACTICE ROOMS

THE CARD ROOM
Learn card rank, high-card points, tricks, trump, contracts, and table roles.

THE AUCTION ROOM
Practice a beginner Standard American framework. Read 13-card hands and choose between pass, a suit opening, and 1NT.

THE DECLARER ROOM
Count winners, draw trump, establish long suits, finesse, and choose the right card in table situations.

THE DEFENSE ROOM
Train opening leads, sequences, third-hand play, suit returns, and partnership habits.

BRIDGE+ (OPTIONAL)
Everything above stays free. Bridge+ adds extra practice in each beginner room and unlocks the Master Tables, with conventions, advanced card play, and duplicate strategy.

BUILT FOR LEARNING
Swipeable coaching cards, quick quizzes, realistic 13-card hands, card-play scenarios, streaks, and a daily mixed session that brings missed material back.

Bridge Trainer uses a beginner Standard American framework. Partnership agreements vary, so confirm conventions with your partner.

SUBSCRIPTIONS
Bridge+ is available by auto-renewing subscription or a one-time purchase: Monthly $1.99/month, Yearly $9.99/year (both include a 1-week free trial), or Lifetime $29.99 one-time. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Account Settings on your device. Terms of Use (Apple's standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Privacy Policy: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "en-CA": {
        "name": "Bridge Trainer: Learn & Bid",
        "subtitle": "Bridge Bidding & Card Practice",
        "keywords": "bridge,bidding,cards,contract,learn,tutor,beginner,lesson,drill,defense,declarer,practice,quiz,play",
        "promotional_text": "Five-minute bridge drills for bidding, declarer play, and defense. Learn the why behind every call and card.",
        "release_notes": "Welcome to Bridge Trainer. Practice rules, opening bids, declarer play, and defense in four free rooms.",
        "description": """Build real contract bridge instincts in five-minute sessions.

Bridge Trainer turns the parts that beginners need most into quick, focused drills. There are no opponents, no timers, and no pressure. Count points, choose an opening bid, plan the play, and learn defensive habits with the reason behind every answer.

FOUR FREE PRACTICE ROOMS

THE CARD ROOM
Learn card rank, high-card points, tricks, trump, contracts, and table roles.

THE AUCTION ROOM
Practice a beginner Standard American framework. Read 13-card hands and choose between pass, a suit opening, and 1NT.

THE DECLARER ROOM
Count winners, draw trump, establish long suits, finesse, and choose the right card in table situations.

THE DEFENSE ROOM
Train opening leads, sequences, third-hand play, suit returns, and partnership habits.

BRIDGE+ (OPTIONAL)
Everything above stays free. Bridge+ adds extra practice in each beginner room and unlocks the Master Tables, with conventions, advanced card play, and duplicate strategy.

BUILT FOR LEARNING
Swipeable coaching cards, quick quizzes, realistic 13-card hands, card-play scenarios, streaks, and a daily mixed session that brings missed material back.

Bridge Trainer uses a beginner Standard American framework. Partnership agreements vary, so confirm conventions with your partner.

SUBSCRIPTIONS
Bridge+ is available by auto-renewing subscription or a one-time purchase: Monthly $1.99/month, Yearly $9.99/year (both include a 1-week free trial), or Lifetime $29.99 one-time. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Account Settings on your device. Terms of Use (Apple's standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Privacy Policy: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "en-AU": {
        "name": "Bridge Trainer: Learn & Bid",
        "subtitle": "Bridge Bidding & Card Practice",
        "keywords": "bridge,bidding,cards,contract,learn,tutor,beginner,lesson,drill,defence,declarer,practice,quiz,play",
        "promotional_text": "Five-minute bridge drills for bidding, declarer play, and defence. Learn the why behind every call and card.",
        "release_notes": "Welcome to Bridge Trainer. Practice rules, opening bids, declarer play, and defence in four free rooms.",
        "description": """Build real contract bridge instincts in five-minute sessions.

Bridge Trainer turns the parts that beginners need most into quick, focused drills. There are no opponents, no timers, and no pressure. Count points, choose an opening bid, plan the play, and learn defensive habits with the reason behind every answer.

FOUR FREE PRACTICE ROOMS

THE CARD ROOM
Learn card rank, high-card points, tricks, trump, contracts, and table roles.

THE AUCTION ROOM
Practice a beginner Standard American framework. Read 13-card hands and choose between pass, a suit opening, and 1NT.

THE DECLARER ROOM
Count winners, draw trump, establish long suits, finesse, and choose the right card in table situations.

THE DEFENSE ROOM
Train opening leads, sequences, third-hand play, suit returns, and partnership habits.

BRIDGE+ (OPTIONAL)
Everything above stays free. Bridge+ adds extra practice in each beginner room and unlocks the Master Tables, with conventions, advanced card play, and duplicate strategy.

BUILT FOR LEARNING
Swipeable coaching cards, quick quizzes, realistic 13-card hands, card-play scenarios, streaks, and a daily mixed session that brings missed material back.

Bridge Trainer uses a beginner Standard American framework. Partnership agreements vary, so confirm conventions with your partner.

SUBSCRIPTIONS
Bridge+ is available by auto-renewing subscription or a one-time purchase: Monthly $1.99/month, Yearly $9.99/year (both include a 1-week free trial), or Lifetime $29.99 one-time. Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Account Settings on your device. Terms of Use (Apple's standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Privacy Policy: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "es-ES": {
        "name": "Bridge Trainer: Aprende y Puja",
        "subtitle": "Práctica de bridge y subastas",
        "keywords": "bridge,subastas,cartas,aprender,tutor,principiante,lección,ejercicio,defensa,declarante,práctica",
        "promotional_text": "Ejercicios de bridge de cinco minutos para subastas, juego del declarante y defensa. Aprende el porqué.",
        "release_notes": "Bienvenido a Bridge Trainer. Practica reglas, subastas de apertura, juego del declarante y defensa en cuatro salas gratis.",
        "description": """Desarrolla instintos reales de bridge de contrato en sesiones de cinco minutos.

Bridge Trainer convierte los aspectos que más necesitan los principiantes en ejercicios rápidos y enfocados. Sin oponentes, sin temporizadores y sin presión. Cuenta puntos, elige una subasta de apertura, planifica la jugada y aprende hábitos defensivos con la explicación detrás de cada respuesta.

CUATRO SALAS DE PRÁCTICA GRATUITAS

LA SALA DE CARTAS
Aprende el rango de las cartas, puntos de cartas altas, bazas, triunfos, contratos y roles en la mesa.

LA SALA DE SUBASTAS
Practica el sistema estándar americano para principiantes. Lee manos de 13 cartas y elige entre pasar, apertura de palo o 1NT.

LA SALA DEL DECLARANTE
Cuenta ganadoras, arrastra triunfos, establece palos largos, haz finesses y elige la carta correcta en situaciones de juego.

LA SALA DE DEFENSA
Entrena salidas, secuencias, juego de la tercera mano, retorno de palo y hábitos de pareja.

BRIDGE+ (OPCIONAL)
Todo lo anterior sigue siendo gratuito. Bridge+ añade práctica adicional en cada sala de principiantes y desbloquea las Mesas Master, con convenciones, juego de cartas avanzado y estrategia de duplicado.

DISEÑADO PARA APRENDER
Tarjetas de entrenamiento deslizables, cuestionarios rápidos, manos reales de 13 cartas, escenarios de juego, rachas y una sesión diaria mixta que repasa el material fallado.

Bridge Trainer utiliza un sistema estándar americano para principiantes. Los acuerdos de pareja varían, así que confirma las convenciones con tu compañero.

SUSCRIPCIONES
Bridge+ está disponible mediante suscripción autorrenovable o compra única: Mensual $1.99/mes, Anual $9.99/año (ambos incluyen 1 semana de prueba gratuita) o Vitalicio $29.99 pago único. El pago se carga a tu cuenta de Apple ID al confirmar la compra. Las suscripciones se renuevan automáticamente a menos que se cancelen al menos 24 horas antes del final del período actual. Gestiona o cancela en cualquier momento en los Ajustes de Cuenta de tu dispositivo. Términos de uso (EULA estándar de Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Política de privacidad: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "es-MX": {
        "name": "Bridge Trainer: Aprende y Puja",
        "subtitle": "Práctica de bridge y subastas",
        "keywords": "bridge,subastas,cartas,aprender,tutor,principiante,lección,ejercicio,defensa,declarante,práctica",
        "promotional_text": "Ejercicios de bridge de cinco minutos para subastas, juego del declarante y defensa. Aprende el porqué.",
        "release_notes": "Bienvenido a Bridge Trainer. Practica reglas, subastas de apertura, juego del declarante y defensa en cuatro salas gratis.",
        "description": """Desarrolla instintos reales de bridge de contrato en sesiones de cinco minutos.

Bridge Trainer convierte los aspectos que más necesitan los principiantes en ejercicios rápidos y enfocados. Sin oponentes, sin temporizadores y sin presión. Cuenta puntos, elige una subasta de apertura, planifica la jugada y aprende hábitos defensivos con la explicación detrás de cada respuesta.

CUATRO SALAS DE PRÁCTICA GRATUITAS

LA SALA DE CARTAS
Aprende el rango de las cartas, puntos de cartas altas, bazas, triunfos, contratos y roles en la mesa.

LA SALA DE SUBASTAS
Practica el sistema estándar americano para principiantes. Lee manos de 13 cartas y elige entre pasar, apertura de palo o 1NT.

LA SALA DEL DECLARANTE
Cuenta ganadoras, arrastra triunfos, establece palos largos, haz finesses y elige la carta correcta en situaciones de juego.

LA SALA DE DEFENSA
Entrena salidas, secuencias, juego de la tercera mano, retorno de palo y hábitos de pareja.

BRIDGE+ (OPCIONAL)
Todo lo anterior sigue siendo gratuito. Bridge+ añade práctica adicional en cada sala de principiantes y desbloquea las Mesas Master, con convenciones, juego de cartas avanzado y estrategia de duplicado.

DISEÑADO PARA APRENDER
Tarjetas de entrenamiento deslizables, cuestionarios rápidos, manos reales de 13 cartas, escenarios de juego, rachas y una sesión diaria mixta que repasa el material fallado.

Bridge Trainer utiliza un sistema estándar americano para principiantes. Los acuerdos de pareja varían, así que confirma las convenciones con tu compañero.

SUSCRIPCIONES
Bridge+ está disponible mediante suscripción autorrenovable o compra única: Mensual $1.99/mes, Anual $9.99/año (ambos incluyen 1 semana de prueba gratuita) o Vitalicio $29.99 pago único. El pago se carga a tu cuenta de Apple ID al confirmar la compra. Las suscripciones se renuevan automáticamente a menos que se cancelen al menos 24 horas antes del final del período actual. Gestiona o cancela en cualquier momento en los Ajustes de Cuenta de tu dispositivo. Términos de uso (EULA estándar de Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Política de privacidad: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "fr-FR": {
        "name": "Bridge Trainer: Enchères",
        "subtitle": "Enchères et jeu de bridge",
        "keywords": "bridge,enchères,cartes,apprendre,tuteur,débutant,leçon,exercice,défense,déclarant,pratique,contrat",
        "promotional_text": "Exercices de bridge de cinq minutes pour les enchères, le jeu du déclarant et la défense. Comprenez le pourquoi.",
        "release_notes": "Bienvenue sur Bridge Trainer. Entraînez-vous aux règles, ouvertures, jeu de déclarant et défense dans 4 salles gratuites.",
        "description": """Développez de vrais réflexes de bridge de contrat en sessions de cinq minutes.

Bridge Trainer transforme les notions essentielles pour les débutants en exercices rapides et ciblés. Sans adversaires, sans chronomètres et sans pression. Comptez les points, choisissez une enchère d'ouverture, planifiez le jeu et apprenez les réflexes défensifs avec l'explication de chaque réponse.

QUATRE SALLES D'ENTRAÎNEMENT GRATUITES

LA SALLE DES CARTES
Apprenez la valeur des cartes, les points d'honneurs, les plis, l'atout, les contrats et les rôles à la table.

LA SALLE DES ENCHÈRES
Pratiquez le système Standard Américain pour débutants. Lisez des mains de 13 cartes et choisissez entre passer, une ouverture à la couleur ou 1SA.

LA SALLE DU DÉCLARANT
Comptez les gagnantes, battez les atouts, établissez les longues, faites des impasses et jouez la bonne carte en situation.

LA SALLE DE LA DÉFENSE
Entraînez-vous aux entames, séquences, jeu en troisième, retours et habitudes de flanc.

BRIDGE+ (OPTIONNEL)
Tout ce qui précède reste gratuit. Bridge+ ajoute des exercices supplémentaires dans chaque salle de débutant et débloque les Master Tables, avec des conventions, du jeu de carte avancé et la stratégie de duplicate.

CONÇU POUR L'APPRENTISSAGE
Fiches de coaching interactives, quiz rapides, donnes réalistes de 13 cartes, scénarios de jeu, séries de victoires et une session quotidienne mixte qui révise le contenu manqué.

Bridge Trainer utilise le système Standard Américain pour débutants. Les conventions pouvant varier selon les paires, validez vos accords avec votre partenaire.

ABONNEMENTS
Bridge+ est disponible par abonnement auto-renouvelable ou achat unique : Mensuel 1,99 $/mois, Annuel 9,99 $/an (les deux incluent 1 semaine d'essai gratuit) ou À vie 29,99 $ en achat unique. Le paiement est débité sur votre compte Apple ID à la confirmation d'achat. Les abonnements se renouvellent automatiquement sauf s'ils sont annulés au moins 24 heures avant la fin de la période en cours. Gérez ou annulez à tout moment dans les Réglages du Compte sur votre appareil. Conditions d'utilisation (EULA standard d'Apple) : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Politique de confidentialité : https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "fr-CA": {
        "name": "Bridge Trainer: Enchères",
        "subtitle": "Enchères et jeu de bridge",
        "keywords": "bridge,enchères,cartes,apprendre,tuteur,débutant,leçon,exercice,défense,déclarant,pratique,contrat",
        "promotional_text": "Exercices de bridge de cinq minutes pour les enchères, le jeu du déclarant et la défense. Comprenez le pourquoi.",
        "release_notes": "Bienvenue sur Bridge Trainer. Entraînez-vous aux règles, ouvertures, jeu de déclarant et défense dans 4 salles gratuites.",
        "description": """Développez de vrais réflexes de bridge de contrat en sessions de cinq minutes.

Bridge Trainer transforme les notions essentielles pour les débutants en exercices rapides et ciblés. Sans adversaires, sans chronomètres et sans pression. Comptez les points, choisissez une enchère d'ouverture, planifiez le jeu et apprenez les réflexes défensifs avec l'explication de chaque réponse.

QUATRE SALLES D'ENTRAÎNEMENT GRATUITES

LA SALLE DES CARTES
Apprenez la valeur des cartes, les points d'honneurs, les plis, l'atout, les contrats et les rôles à la table.

LA SALLE DES ENCHÈRES
Pratiquez le système Standard Américain pour débutants. Lisez des mains de 13 cartes et choisissez entre passer, une ouverture à la couleur ou 1SA.

LA SALLE DU DÉCLARANT
Comptez les gagnantes, battez les atouts, établissez les longues, faites des impasses et jouez la bonne carte en situation.

LA SALLE DE LA DÉFENSE
Entraînez-vous aux entames, séquences, jeu en troisième, retours et habitudes de flanc.

BRIDGE+ (OPTIONNEL)
Tout ce qui précède reste gratuit. Bridge+ ajoute des exercices supplémentaires dans chaque salle de débutant et débloque les Master Tables, avec des conventions, du jeu de carte avancé et la stratégie de duplicate.

CONÇU POUR L'APPRENTISSAGE
Fiches de coaching interactives, quiz rapides, donnes réalistes de 13 cartes, scénarios de jeu, séries de victoires et une session quotidienne mixte qui révise le contenu manqué.

Bridge Trainer utilise le système Standard Américain pour débutants. Les conventions pouvant varier selon les paires, validez vos accords avec votre partenaire.

ABONNEMENTS
Bridge+ est disponible par abonnement auto-renouvelable ou achat unique : Mensuel 1,99 $/mois, Annuel 9,99 $/an (les deux incluent 1 semaine d'essai gratuit) ou À vie 29,99 $ en achat unique. Le paiement est débité sur votre compte Apple ID à la confirmation d'achat. Les abonnements se renouvellent automatiquement sauf s'ils sont annulés au moins 24 heures avant la fin de la période en cours. Gérez ou annulez à tout moment dans les Réglages du Compte sur votre appareil. Conditions d'utilisation (EULA standard d'Apple) : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Politique de confidentialité : https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "de-DE": {
        "name": "Bridge Trainer: Reizen & Spiel",
        "subtitle": "Reizung und Brücke Karten üben",
        "keywords": "bridge,reizen,karten,lernen,lehrer,anfänger,lektion,übung,verteidigung,alleinspieler,praxis,tipp",
        "promotional_text": "Fünf-Minuten-Bridgeübungen für Reizung, Alleinspiel und Verteidigung. Lerne das Warum hinter jedem Blatt.",
        "release_notes": "Willkommen bei Bridge Trainer. Übe Regeln, Eröffnungsgebote, Alleinspiel und Verteidigung in vier kostenlosen Räumen.",
        "description": """Baue in Fünf-Minuten-Einheiten echte Instinkte für Kontrakt-Bridge auf.

Bridge Trainer verwandelt die wichtigsten Grundlagen für Anfänger in schnelle, fokussierte Übungen. Ohne Gegner, ohne Zeitdruck und ohne Stress. Zähle Punkte, wähle ein Eröffnungsgebot, plane das Spiel und lerne Verteidigungsgewohnheiten mit der Begründung hinter jeder Antwort.

VIER KOSTENLOSE ÜBUNGSRÄUME

DER KARTENRAUM
Lerne Kartenrangfolge, Figurenpunkte, Stiche, Trumpf, Kontrakte und Rollen am Tisch.

DER REIZRAUM
Übe das Standard-American-System für Anfänger. Lies Blätter mit 13 Karten und wähle zwischen Pass, Eröffnung oder 1NT.

DER ALLEINSPIELERRAUM
Zähle Gewinner, ziehe Trumpf, baue lange Farben auf, spiele Finessen und wähle die richtige Karte in Spielsituationen.

DER VERTEIDIGUNGSRAUM
Trainiere Ausspiele, Sequenzen, Dritt-Hand-Spiel, Rückspiele und Partnerschaftskonventionen.

BRIDGE+ (OPTIONAL)
Alles oben Genannte bleibt kostenlos. Bridge+ bietet zusätzliche Übungen in jedem Anfängerbereich und schaltet die Master Tables mit Konventionen, fortgeschrittenem Kartenspiel und Turniertaktik frei.

FÜR DAS LERNEN ENTWICKELT
Interaktive Lernkarten, schnelle Quizzes, realistische 13-Karten-Blätter, Spielszenarien, Serien und ein täglicher Mix, der falsche Antworten wiederholt.

Bridge Trainer verwendet das Standard-American-System für Anfänger. Partnerschaftsvereinbarungen variieren, stimme Konventionen daher mit deinem Partner ab.

ABONNEMENTS
Bridge+ ist als automatisch verlängerndes Abonnement oder als Einmalkauf erhältlich: Monatlich $1.99/Monat, Jährlich $9.99/Jahr (beide mit 1 Woche kostenloser Testphase) oder Lifetime $29.99 einmalig. Die Zahlung wird deinem Apple-ID-Konto bei Kaufbestätigung berechnet. Abonnements verlängern sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ende des aktuellen Zeitraums gekündigt werden. Verwalte oder kündige jederzeit in den Kontoeinstellungen deines Geräts. Nutzungsbedingungen (Apples Standard-EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Datenschutzerklärung: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "it": {
        "name": "Bridge Trainer: Licita e Gioca",
        "subtitle": "Pratica di licita del bridge",
        "keywords": "bridge,licita,carte,imparare,tutor,principiante,lezione,esercizio,difesa,dichiarante,pratica,tiro",
        "promotional_text": "Esercizi di bridge di cinque minuti per licita, gioco del dichiarante e difesa. Scopri il perché.",
        "release_notes": "Benvenuto in Bridge Trainer. Esercitati su regole, aperture, gioco del dichiarante e difesa in quattro stanze gratis.",
        "description": """Sviluppa veri istinti per il bridge di contratto in sessioni di cinque minuti.

Bridge Trainer trasforma le parti di cui i principianti hanno più bisogno in esercizi rapidi e mirati. Non ci sono avversari, cronometri o pressioni. Conta i punti, scegli una licita di apertura, pianifica il gioco e impara le regole della difesa con la spiegazione dietro ogni risposta.

QUATTRO STANZE DI PRATICA GRATUITE

LA STANZA DELLE CARTE
Impara il rango delle carte, i punti onore, le prese, l'atout, i contratti e i ruoli al tavolo.

LA STANZA DELLA LICITA
Esercitati con il sistema Standard American per principianti. Leggi mani di 13 carte e scegli tra passo, apertura a colore o 1NT.

LA STANZA DEL DICHIARANTE
Conta le vincenti, muovi l'atout, affranca i semi lunghi, effettua sorpassi e scegli la carta giusta in gioco.

LA STANZA DELLA DIFESA
Allenati con gli attacchi, le sequenze, il gioco in terza, i ritorni e le abitudini del flanc.

BRIDGE+ (OPZIONALE)
Tutto quanto sopra resta gratuito. Bridge+ aggiunge esercitazioni extra in ciascuna stanza per principianti e sblocca i Master Tables con convenzioni, gioco di carte avanzato e strategia per duplicato.

PROGETTATO PER L'APPRENDIMENTO
Schede di coaching interattive, quiz rapidi, mani reali da 13 carte, scenari di gioco, strisce vincenti e una sessione mista giornaliera che ripropone il materiale errato.

Bridge Trainer utilizza il sistema Standard American per principianti. Le convenzioni di coppia variano, quindi conferma gli accordi con il tuo partner.

ABONNAMENTI
Bridge+ è disponibile tramite abbonamento auto-rinnovabile o acquisto singolo: Mensile $1.99/mese, Annuale $9.99/anno (entrambi include 1 settimana di prova gratuita) o Lifetime $29.99 acquisto singolo. Il pagamento viene addebitato sul tuo account Apple ID alla conferma dell'acquisto. Gli abbonamenti si rinnovano automaticamente a meno che non vengano disdetti almeno 24 ore prima della fine del periodo corrente. Gestisci o disdici in qualsiasi momento nelle Impostazioni Account del tuo dispositivo. Termini di utilizzo (EULA standard di Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Informativa sulla privacy: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "pt-BR": {
        "name": "Bridge Trainer: Licitación",
        "subtitle": "Pratique licitação de bridge",
        "keywords": "bridge,licitação,cartas,aprender,tutor,iniciante,lição,exercício,defensa,declarante,prática,play",
        "promotional_text": "Exercícios de bridge de cinco minutos para licitação, jogo do declarante e defesa. Aprenda o porquê.",
        "release_notes": "Boas-vindas ao Bridge Trainer. Pratique regras, aberturas, jogo do declarante e defesa em quatro salas gratuitas.",
        "description": """Desenvolva instintos reais de bridge de contrato em sessões de cinco minutos.

O Bridge Trainer transforma as partes que os iniciantes mais precisam em exercícios rápidos e focados. Sem oponentes, sem cronômetros e sem pressão. Conte pontos, escolha uma abertura de licitação, planeje o jogo e aprenda hábitos defensivos com la justificativa de cada resposta.

QUATRO SALAS DE PRÁTICA GRATUITAS

A SALA DE CARTAS
Aprenda o ranking das cartas, pontos de honra, vazas, trunfo, contratos e papéis na mesa.

A SALA DE LICITAÇÃO
Pratique o sistema Standard American para iniciantes. Leia mãos de 13 cartas e escolha entre passo, abertura de naipe ou 1NT.

A SALA DO DECLARANTE
Conte ganhadoras, puxe trunfos, estabeleça naipes longos, faça finesses e escolha a carta certa nas situações de jogo.

A SALA DE DEFESA
Treine saídas, sequências, jogo de terceira mão, retornos de naipe e hábitos de parceria.

BRIDGE+ (OPCIONAL)
Tudo acima continua gratuito. O Bridge+ adiciona prática extra em cada sala de iniciantes e desbloqueia as Master Tables, com convenções, jogo de cartas avançado e estratégia de duplicado.

CONSTRUÍDO PARA O APRENDIZADO
Cartões de treinamento interativos, quizzes rápidos, mãos reais de 13 cartas, cenários de jogo, sequências de acertos e uma sessão diária mista que traz de volta o material que você errou.

O Bridge Trainer usa o sistema Standard American para iniciantes. Os acordos de parceria variam, portanto, confirme as convenções com seu parceiro.

ASSINATURAS
O Bridge+ está disponível por assinatura autorrenovável ou compra única: Mensal $1.99/mês, Anual $9.99/ano (ambos incluem 1 semana de teste grátis) ou Lifetime $29.99 pagamento único. O pagamento é cobrado na sua conta Apple ID na confirmação da compra. As assinaturas são renovadas automaticamente, a menos que sejam canceladas pelo menos 24 horas antes do final do período atual. Gerencie ou cancele a qualquer momento nos Ajustes de Conta do seu dispositivo. Termos de Uso (EULA padrão da Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Política de Privacidade: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "pt-PT": {
        "name": "Bridge Trainer: Licitación",
        "subtitle": "Pratique licitação de bridge",
        "keywords": "bridge,licitação,cartas,aprender,tutor,iniciante,lição,exercício,defensa,declarante,prática,play",
        "promotional_text": "Exercícios de bridge de cinco minutos para licitação, jogo do declarante e defesa. Aprenda o porquê.",
        "release_notes": "Boas-vindas ao Bridge Trainer. Pratique regras, aberturas, jogo do declarante e defesa em quatro salas gratuitas.",
        "description": """Desenvolva instintos reais de bridge de contrato em sesões de cinco minutos.

O Bridge Trainer transforma as partes que os iniciantes mais precisam em exercícios rápidos e focados. Sem oponentes, sem cronômetros e sem pressão. Conte pontos, escolha uma abertura de licitação, planeje o jogo e aprenda hábitos defensivos com a justificativa de cada resposta.

QUATRO SALAS DE PRÁTICA GRATUITAS

A SALA DE CARTAS
Aprenda o ranking das cartas, pontos de honra, vazas, trunfo, contratos e papéis na mesa.

A SALA DE LICITAÇÃO
Pratique o sistema Standard American para iniciantes. Leia mãos de 13 cartas e escolha entre passo, abertura de naipe ou 1NT.

A SALA DO DECLARANTE
Conte ganhadoras, puxe trunfos, estabeleça naipes longos, faça finesses e escolha a carta certa nas situações de jogo.

A SALA DE DEFESA
Treine saídas, sequências, jogo de terceira mão, retornos de naipe e hábitos de parceria.

BRIDGE+ (OPCIONAL)
Tudo acima continua gratuito. O Bridge+ adiciona prática extra em cada sala de iniciantes e desbloqueia as Master Tables, com convenções, jogo de cartas advanced e estratégia de duplicado.

CONSTRUÍDO PARA O APRENDIZADO
Cartões de treinamento interativos, quizzes rápidos, mãos reais de 13 cartas, cenários de jogo, sequências de acertos e uma sessão diária mista que traz de volta o material que você errou.

O Bridge Trainer usa o sistema Standard American para iniciantes. Os acordos de parceria variam, portanto, confirme as convenções com seu parceiro.

ASSINATURAS
O Bridge+ está disponível por assinatura autorrenovável ou compra única: Mensal $1.99/mês, Anual $9.99/ano (ambos incluem 1 semana de teste grátis) ou Lifetime $29.99 pagamento único. O pagamento é cobrado na sua conta Apple ID na confirmação da compra. As assinaturas são renovadas automaticamente, a menos que sejam canceladas pelo menos 24 horas antes do final do período atual. Gerencie ou cancele a qualquer momento nos Ajustes de Conta do seu dispositivo. Termos de Uso (EULA padrão da Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Política de Privacidade: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "nl-NL": {
        "name": "Bridge Trainer: Leren & Bieden",
        "subtitle": "Bridge bieden en oefenen",
        "keywords": "bridge,bieden,kaarten,leren,tutor,beginner,les,oefening,verdediging,leider,praktijk,speel,troef",
        "promotional_text": "Bridge-oefeningen van vijf minuten voor bieden, afspelen en verdedigen. Leer de logica.",
        "release_notes": "Welkom bij Bridge Trainer. Oefen regels, openingsbiedingen, afspelen en verdediging in vier gratis kamers.",
        "description": """Bouw echte instincten op voor contract bridge in sessies van vijf minuten.

Bridge Trainer vertaalt de belangrijkste onderdelen voor beginners naar snelle, gerichte oefeningen. Geen tegenstanders, geen timers en geen druk. Tel punten, kies een openingsbod, plan het spel en leer verdedigende gewoonten met de uitleg achter elk antwoord.

VIER GRATIS OEFENKAMERS

DE KAARTENKAMER
Leer kaartvolgorde, figuurpunten, slagen, troef, contracten en tafelrollen.

DE BIEDKAMER
Oefen het Standard American-systeem voor beginners. Lees handen van 13 kaarten en kies tussen pas, een opening of 1NT.

DE SPEELKAMER
Tel winnaars, trek troef, ontwikkel lange kleuren, neem snitten en kies de juiste kaart in spelsituaties.

DE VERDEDIGINGSKAMER
Train startkaarten, sequenties, derdemansspel, terugspelen en partnerafspraken.

BRIDGE+ (OPTIONEEL)
Alles hierboven blijft gratis. Bridge+ voegt extra oefeningen toe in elke beginnerskamer en ontgrendelt de Master Tables, met conventies, geavanceerd kaartspel en wedstrijdstrategie.

ONTWIKKELD OM TE LEREN
Interactieve leskaarten, snelle quizzen, realistische 13-kaart handen, spelscenario's, reeksen en een gemengde sessie die foutieve vragen herhaalt.

Bridge Trainer gebruikt het Standard American-systeem voor beginners. Partnerafspraken kunnen variëren, dus stem conventies af met uw partner.

ABONNEMENTEN
Bridge+ is beschikbaar via automatisch verlengend abonnement of als eenmalige aankoop: Maandelijks $1.99/maand, Jaarlijks $9.99/jaar (beide inclusief 1 week gratis proefperiode) of Lifetime $29.99 eenmalig. De betaling wordt in rekening gebracht op uw Apple ID-account bij de voorafgaande bevestiging van de aankoop. Abonnementen worden automatisch verlengd tenzij ze ten minste 24 uur voor het einde van de huidige periode worden opgezegd. Beheer of annuleer op elk moment in de accountinstellingen van uw apparaat. Gebruiksvoorwaarden (Standaard Apple EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Privacybeleid: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ca": {
        "name": "Bridge Trainer: Aprèn i Lícita",
        "subtitle": "Pràctica de licitació i cartes",
        "keywords": "bridge,licitació,cartes,aprendre,tutor,principiant,lliçó,exercici,defensa,declarant,pràctica,joc",
        "promotional_text": "Exercicis de bridge de cinc minuts per a licitació, joc del declarant i defensa. Aprèn el perquè.",
        "release_notes": "Benvingut a Bridge Trainer. Practica regles, licitacions d'obertura, joc del declarant i defensa en quatre sales gratis.",
        "description": """Desenvolupa instints reals de bridge de contracte en sessions de cinc minuts.

Bridge Trainer converteix els aspectes que més necessiten els principiants en exercicis ràpids i enfocats. Sense oponents, sense temporitzadors i sense pressió. Compta punts, tria una licitació d'obertura, planifica la jugada i aprèn hàbits defensius amb l'explicació darrere de cada resposta.

QUATRE SALES DE PRÀCTICA GRATUÏTES

LA SALA DE CARTES
Aprèn el rang de les cartes, punts de cartes altes, bases, trumfs, contractes i rols a la taula.

LA SALA DE LICITACIÓ
Practica el sistema estàndard americà per a principiants. Llegeix mans de 13 cartes i tria entre passar, obertura de coll o 1NT.

LA SALA DEL DECLARANT
Compta guanyadores, arrossega trumfs, estableix colls llargs, fes finesses i tria la carta correcta en situacions de joc.

LA SALA DE DEFENSA
Entrena sortides, seqüències, joc de la tercera mà, retorn de coll i hàbits de parella.

BRIDGE+ (OPCIONAL)
Tot l'anterior segueix sent gratuït. Bridge+ afegeix pràctica addicional en cada sala de principiants i desbloqueja les Meses Master, com ara conventions, joc de cartes avançat i estratègia de duplicat.

DISSENYAT PER APRENDRE
Targetes d'entrenament lliscants, qüestionaris ràpids, mans reals de 13 cartes, escenaris de joc, ratxes i una sessió diària mixta que repassa el material fallat.

Bridge Trainer utilitza un sistema estàndard americà per a principiants. Els acords de parella varien, així que confirma les convencions amb el teu company.

SUBSCRIPCIONS
Bridge+ està disponible mitjançant subscripció autorenovable o compra única: Mensual $1.99/mes, Anual $9.99/any (ambdós inclouen 1 setmana de prova gratuïta) o Vitalici $29.99 pagament únic. El pago es carrega al teu compte d'Apple ID en confirmar la compra. Les subscripcions es renoven automàticament a menys que es cancel·lin almenys 24 hores abans del final del període actual. Gestiona o cancel·la en qualsevol moment als Ajustos de Compte del teu dispositiu. Termes d'ús (EULA estàndard d'Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Política de privadesa: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "da": {
        "name": "Bridge Trainer: Lær at melde",
        "subtitle": "Bridge meldinger og træning",
        "keywords": "bridge,meldinger,kort,lære,tutor,begynder,lektion,drill,forsvar,spilfører,træning,quiz,kontrakt",
        "promotional_text": "Fem-minutters bridgeøvelser til meldinger, spilføring og forsvar. Lær logikken bag hvert kort.",
        "release_notes": "Velkommen til Bridge Trainer. Træn regler, åbningsmeldinger, spilføring og forsvar i fire gratis rum.",
        "description": """Opbyg ægte instinkter for kontraktbridge i sessioner på fem minutter.

Bridge Trainer forvandler de vigtigste elementer for begyndere til hurtige, fokuserede øvelser. Der er ingen modstandere, ingen timere og intet pres. Tæl point, vælg en åbningsmelding, planlæg spillet, og lær forsvarsvaner med forklaringen bag hvert svar.

FIRE GRATIS TRÆNINGSRUM

KORTRUMMET
Lær kortrang, honnørpoint, stik, trumf, kontrakter og roller ved bordet.

MELDERUMMET
Træn det grundlæggende Standard American-system. Læs hænder med 13 kort, og vælg mellem pas, en farveåbning eller 1NT.

SPILFØRERRUMMET
Tæl vindere, træk trumf, etabler lange farver, tag knibe, og vælg det rigtige kort i spilsituationer.

FORSVARSRUMMET
Træn udspil, sekvenser, spil som tredjemand, returer og partnerskabsvaner.

BRIDGE+ (VALGFRIT)
Alt ovenstående forbliver gratis. Bridge+ tilføjer ekstra træning i hvert begynderrum og låser op for Master Tables med konventioner, avanceret kortspil og turneringstaktik.

BYGGET TIL LÆRING
Læringskort, hurtige quizzer, realistiske 13-korthænder, spilszenarier, serier og en daglig blandet session, der gentager det glemte materiale.

Bridge Trainer bruger det grundlæggende Standard American-system. Partnerskabsforståelser varierer, så aftal konventioner med din partner.

ABONNEMENTER
Bridge+ fås som automatisk fornyeligt abonnement eller som engangskøb: Månedligt $1.99/måned, Årligt $9.99/år (begge inkluderer 1 uges gratis prøveperiode) eller Livstid $29.99 engangskøb. Betalingen debiteres dit Apple ID ved bekræftelse av købet. Abonnementer fornyes automatisk, medmindre de opsiges senest 24 timer før udgangen af den aktuelle periode. Administrer eller opsig når som helst i din enheds kontoindstillinger. Vilkår for brug (Apples standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Privatlivspolitik: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "no": {
        "name": "Bridge Trainer: Lær meldinger",
        "subtitle": "Bridge meldinger og trening",
        "keywords": "bridge,meldinger,kort,lære,tutor,nybegynner,leksjon,drill,forsvar,spillefører,trening,quiz,kontrakt",
        "promotional_text": "Fem-minutters bridgeøvelser for meldinger, spilleføring og forsvar. Lær hvorfor bak hvert kort.",
        "release_notes": "Velkommen til Bridge Trainer. Tren regler, åpningsmeldinger, spilleføring og forsvar i fire gratis rom.",
        "description": """Bygg ekte instinkter for kontraktbridge i økter på fem minutter.

Bridge Trainer gjør de viktigste delene for nybegynnere om til raske, fokuserte driller. Det er ingen motstandere, ingen timere og ikke noe press. Tell poeng, velg en åpningsmelding, planlegg spillet, og lær forsvarsvaner med forklaringen bak hvert svar.

FIRE GRATIS TRENINGSROM

KORTRUMMET
Lær kortrang, honnørpoeng, stikk, trumf, kontrakter og roller ved bordet.

MELDERUMMET
Øv på det grunnleggende Standard American-systemet. Les hender med 13 kort, og velg mellom pass, en fargeåpning eller 1NT.

SPILLEFØRERRUMMET
Tell vinnere, trekk trumf, etabler lange farger, ta kniper, og velg det riktige kortet i spillesituasjoner.

FORSVARSRUMMET
Tren utspill, sekvenser, spill som tredjemann, returer og partnerskapsvaner.

BRIDGE+ (VALGFRITT)
Alt ovenfor forblir gratis. Bridge+ legger til ekstra trening i hvert nybegynnerrom og låser opp Master Tables med konvensjoner, avansert kortspill og duplicate-strategi.

BYGGET FOR LÆRING
Læringskort, raske quizzer, realistiske 13-korts hender, spillescenarier, serier og en daglig blandet økt som henter tilbake feilaktige svar.

Bridge Trainer bruker det grunnleggende Standard American-systemet. Partnerskapsavtaler varierer, så bekreft konvensjoner med partneren din.

ABONNEMENTER
Bridge+ er tilgjengelig via automatisk fornybart abonnement eller som engangskjøp: Månedlig $1.99/måned, Årlig $9.99/år (begge inkluderer 1 ukes gratis prøveperiode) eller Livstid $29.99 engangsbetaling. Betalingen belastes din Apple ID-konto ved bekræftelse av kjøpet. Abonnementer fornyes automatisk med mindre de sies opp minst 24 timer før utgangen av gjeldende periode. Administrer eller avbryt når som helst i kontoinnstillingene på enheten din. Vilkår for brug (Apples standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Personvernerklæring: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "sv": {
        "name": "Bridge Trainer: Lär dig bjuda",
        "subtitle": "Bridgebud och kortträning",
        "keywords": "bridge,budgivning,kort,lära,tutor,nybörjare,lektion,drill,försvar,spelförare,träning,quiz,kontrakt",
        "promotional_text": "Femminutersbridgeövningar för budgivning, spelföring och försvar. Lär dig logiken bakom varje kort.",
        "release_notes": "Välkommen till Bridge Trainer. Öva regler, öppningsbud, spelföring och försvar i fyra gratisrum.",
        "description": """Bygg upp äkta instinkter för kontraktbridge i sessioner på fem minuter.

Bridge Trainer förvandlar de delar som nybörjare behöver mest till snabba, fokuserade övningar. Inga motståndare, inga tidtagare och ingen press. Räkna poäng, välj ett öppningsbud, planera spelet och lär dig försvarsvanor med förklaringen bakom varje svar.

FYRA GRATIS TRÄNINGSRUM

KORTRUMMET
Lär dig kortrankning, honnörspoäng, stick, trumf, kontrakt och roller vid bordet.

BUDRUMMET
Träna på ett grundläggande Standard American-system. Läs händer med 13 kort och välj mellan pass, ett färgöppningsbud eller 1NT.

SPELFÖRARUMMET
Räkna vinnare, dra trumf, etablera långa färger, ta maskar och välj rätt kort i spelsituationer.

FÖRSVARSUMMET
Träna utspel, sekvenser, spel som tredje hand, returer och partnerskapsvanor.

BRIDGE+ (VALFRITT)
Allt ovan förblir gratis. Bridge+ lägger till extra träning i varje nybörjarrum och låser upp Master Tables med konventioner, avancerat kortspel och partävlingstaktik.

BYGGT FÖR ATT LÄRA
Instruktiva kort, snabba quiz, realistiske 13-kortshänder, spelsituationer, sviter och en daglig blandad session som tar tillbaka det du missat.

Bridge Trainer använder ett grundläggande Standard American-system. Partnerskapsavtal varierar, så stäm av konventioner med din partner.

ABONNEMANG
Bridge+ är tillgängligt via automatiskt förnybart abonnemang eller som engångsköp: Månadsvis $1.99/månad, Årlig $9.99/år (båda inkluderer 1 vecka gratis provperiod) eller Livstid $29.99 engångsköp. Betalningen debiteras ditt Apple ID-konto vid bekräftelse av köp. Abonnemang förnyas automatiskt om de inte avbryts minst 24 timmar före slutet av den aktuella perioden. Hantera eller avbryt när som helst i kontoinnstillingene på din enhet. Användarvillkor (Apples standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Integritetspolicy: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "fi": {
        "name": "Bridge Trainer: Opi tarjoamaan",
        "subtitle": "Bridgen tarjoukset ja treeni",
        "keywords": "bridge,tarjoukset,kortit,oppia,tutor,aloittelija,oppitunti,harjoitus,puolustus,pelinviejä,treeni",
        "promotional_text": "Viiden minuutin bridgeharjoituksia tarjoamiseen, pelinvientiin ja puolustukseen. Opi taustalogiikka.",
        "release_notes": "Tervetuloa Bridge Traineriin. Harjoittele sääntöjä, avaustarjouksia, pelinvientiä ja puolustusta neljässä ilmaisessa huoneessa.",
        "description": """Kehitä todellisia sopimusbridgen vaistoja viiden minuutin harjoituksilla.

Bridge Trainer muuttaa aloittelijoiden tärkeimmät osa-alueet nopeiksi, kohdistetuiksi harjoituksiksi. Ei vastustajia, ei ajastimia eikä paineita. Laske pisteet, valitse avaustarjous, suunnittele pelinvienti ja opi puolustusrutiineja jokaisen vastauksen perustelujen avulla.

NELJÄ ILMAISTA HARJOITUSHUONETTA

KORTTIHUONE
Opi korttien arvojärjestys, kuvapisteet, tikit, valtti, sitoumukset ja pöytäroolit.

TARJOUSHUONE
Harjoittele aloittelijoiden Standard American -järjestelmää. Lue 13 kortin kädet ja valitse passi, väriavaus tai 1NT.

PELINVIEJÄHUONE
Laske voittajat, vedä valtit, perusta pitkät maat, tee leikkaukset ja valitse oikea kortti pelitilanteissa.

PUOLUSTUSHUONE
Harjoittele lähtökortteja, sarjoja, kolmannen käden sääntöä, palautuksia ja kumppanuusrutiineja.

BRIDGE+ (VALINNAINEN)
Kaikki yllä oleva pysyy ilmaisena. Bridge+ tuo lisäharjoituksia jokaiseen aloittelijoiden huoneeseen ja avaa Master Tables -osion, jossa opitaan konventioita, edistynyttä korttipeliä ja kilpailustrategioita.

SUUNNITELTU OPPIMISEEN
Vuorovaikutteiset oppimiskortit, nopeat tietovisat, realistiset 13 kortin kädet, pelitilanteet, sarjat ja päivittäinen sekaistunto, joka tuo väärin menneet asiat takaisin.

Bridge Trainer käyttää aloittelijoiden Standard American -järjestelmää. Kumppanuussopimukset vaihtelevat, joten vahvista käytetyt konventiot partnerisi kanssa.

TILAUSET
Bridge+ on saatavilla automaattisesti uusiutuvalla tilauksella tai kertamaksulla: Kuukausittain $1.99/kk, Vuosittain $9.99/vuosi (molempiin sisältyy 1 viikon ilmainen kokeilu) tai Elinikäinen $29.99 kertamaksu. Maksu veloitetaan Apple ID -tililtäsi ostovahvistuksen yhteydessä. Tilaukset uusiutuvat automaattisesti, ellei niitä peruuteta vähintään 24 tuntia ennen nykyisen tilausjakson päättymistä. Hallitse tai peruuta milloin tahansa laitteesi tiliasetuksista. Käyttöehdot (Applen standardi EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Tietosuojakäytäntö: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "cs": {
        "name": "Bridge Trainer: Výuka a hry",
        "subtitle": "Procvičování licitace a karet",
        "keywords": "brydž,licitace,karty,učení,lektor,začátečník,lekce,cvičení,obrana,hlavní hráč,trénink,kvíz,hra,list",
        "promotional_text": "Pětiminutová cvičení pro licitaci, sehrávku a obranu. Pochopte logiku každého rozhodnutí.",
        "release_notes": "Vítejte v Bridge Trainer. Procvičujte pravidla, zahájení, sehrávku a obranu ve čtyřech bezplatných místnostech.",
        "description": """Vypěstujte si správné bridžové instinkty během pětiminutových lekcí.

Bridge Trainer přeměňuje základy, které začátečníci nejvíce potřebují, v rychlá a cílená cvičení. Žádní soupeři, žádné stopky a žádný tlak. Počítejte body, zvolte zahajovací hlášku, plánujte sehrávku a učte se obranné návyky s vysvětlením každého řešení.

ČTYŘI BEZPLATNÉ TRÉNINKOVÉ MÍSTNOSTI

KARTOVÁ MÍSTNOST
Naučte se hodnoty karet, bodování, zdvihy, trumfy, závazky a role u stolu.

LICITAČNÍ MÍSTNOST
Procvičujte základy systému Standard American. Přečtěte 13karetní listy a volte mezi pasem, zahájením v barvě nebo 1NT.

MÍSTNOST SEHRÁVKY
Počítejte vítězné zdvihy, vytrumfujte, vypracujte dlouhé barvy, provádějte impasy a vybírejte správné karty.

OBRANNOÁ MÍSTNOST
Trénujte výnosy, sekvence, hru třetího hráče, vracení barvy a partnerské návyky.

BRIDGE+ (VOLITELNÉ)
Vše výše uvedené zůstává zdarma. Verze Bridge+ pridává další procvičování v každé místnosti a odemyká Master Tables s konvencemi, pokročilou sehrávkou a turnajovou strategií.

NAVRŽENO PRO VÝUKU
Interaktivní výukové karty, rychlé kvízy, realistické 13karetní listy, herní scénáře, série a denní mix, který se vrací k chybám.

Bridge Trainer využíva základy systému Standard American. Partnerské dohody se liší, proto si konvence vždy ověřte se svým partnerem.

PŘEDPLATNÉ
Bridge+ je k dispozici formou automaticky se obnovujícího předplatného nebo jednorázového nákupu: Měsíčně $1.99/měsíc, Ročně $9.99/rok (obojí s 1 týdnem zkušební doby zdarma) nebo Doživotně $29.99 jednorázově. Platba je zaúčtována na váš Apple ID účet při potvrzení nákupu. Předplatné se automaticky obnovuje, pokud není zrušeno alespoň 24 hodin před koncem aktuálního období. Správa a zrušení jsou možné kdykoli v Nastavení účtu ve vašem zařízení. Podmínky použití (standardní Apple EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Zásady ochrany osobních údajů: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "sk": {
        "name": "Bridge Trainer: Výuka a hry",
        "subtitle": "Licitácia a karty v brydži",
        "keywords": "bridž,licitácia,karty,učenie,lektor,začiatočník,lekcia,cvičenie,obrana,hlavný hráč,tréning,kvíz,hra",
        "promotional_text": "Päťminútové cvičenia pre licitáciu, zohrávku a obranu. Pochopte logiku každého rozhodnutia.",
        "release_notes": "Vitajte v Bridge Trainer. Precvičujte pravidlá, zahájenia, zohrávku a obranu v štyroch bezplatných miestnostiach.",
        "description": """Vypestujte si správne bridžové instinkty počas päťminútových lekcií.

Bridge Trainer premieňa základy, ktoré začiatočníci najviac potrebujú, na rýchle a cielené cvičenia. Žiadni súperi, žiadne stopky a žiadny tlak. Počítajte body, zvolte zahajoviciu hlášku, plánujte zohrávku a učte sa obranné návyky s vysvetlením každého riešenia.

ŠTYRI BEZPLATNÉ TRÉNINGOVÉ MIESTNOSTI

KARTOVÁ MIESTNOSŤ
Naučte sa hodnoty kariet, bodovanie, zdvihy, trumfy, záväzky a roly pri stole.

LICITAČNÁ MIESTNOSŤ
Precvičujte základy systému Standard American. Prečítajte 13-kartové listy a voľte medzi pasom, zahájením vo farbe alebo 1NT.

MIESTNOSŤ ZOHRÁVKY
Počítajte víťazné zdvihy, vytrumfujte, vypracujte dlhé farby, vykonávajte impasy a vyberajte správne karty.

OBRANNOÁ MIESTNOSŤ
Trénujte výnosy, sekvencie, hru tretieho hráče, vracenie farby a partnerské návyky.

BRIDGE+ (VOLITEĽNÉ)
Všetko vyššie uvedené zostáva zadarmo. Verzia Bridge+ pridáva ďalšie precvičovanie v každej miestnosti a odomyká Master Tables s konvenciami, pokročilou zohrávkou a turnajovou stratégiou.

NAVRHNUTÉ PRE VÝUKU
Interaktívne výukové karty, rýchle kvízy, realistické 13-kartové listy, herné scenáre, série a denný mix, ktorý sa vracia k chybám.

Bridge Trainer využíva základy systému Standard American. Partnerské dohody sa líšia, preto si konvencie vždy overte so svojím partnerem.

PREDPLATNÉ
Bridge+ je k dispozícii formou automaticky sa obnovujúceho predplatného alebo jednorazového nákupu: Mesačne $1.99/mesiac, Ročne $9.99/rok (obidve s 1 týdňom skúšobnej doby zadarmo) nebo Doživotne $29.99 jednorazovo. Platba je zaúčtována na váš Apple ID účet pri potvrdení nákupu. Predplatné sa automaticky obnovuje, pokiaľ nie je zrušené aspoň 24 hodín pred koncom aktuálneho obdobia. Správa a zrušenie sú možné kedykoľvek v Nastavení účtu vo vašom zariadení. Podmienky používania (štandardný Apple EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Zásady ochrany osobných údajov: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "pl": {
        "name": "Bridge Trainer: Licytacja",
        "subtitle": "Trening licytacji w brydżu",
        "keywords": "brydż,licytacja,karty,nauka,tutor,początkujący,lekcja,ćwiczenie,obrona,rozgrywający,praktyka,gra",
        "promotional_text": "Pięciominutowe ćwiczenia z licytacji, rozgrywki i obrony w brydżu. Poznaj teorię każdej karty.",
        "release_notes": "Witaj w Bridge Trainer. Ćwicz zasady, odzywki otwarcia, rozgrywkę i obronę w 4 darmowych pokojach.",
        "description": """Rozwijaj praktyczny instynkt brydżowy podczas pięciominutowych sesji.

Bridge Trainer zamienia elementy, których początkujący potrzebują najbardziej, w szybkie, ukierunkowane ćwiczenia. Bez przeciwników, bez liczników czasu i bez presji. Licz punkty, wybieraj odzywki otwarcia, planuj rozgrywkę i ucz się nawyków obronnych dzięki wyjaśnieniom każdego wyboru.

CZTERY DARMOWE POKOJE TRENINGOWE

POKÓJ KART
Poznaj hierarchię kart, punkty honorowe, lewy, atuty, kontrakty i role przy stole.

POKÓJ LICYTACJI
Ćwicz podstawy systemu Standard American. Analizuj 13-kartowe ręce i wybieraj między pasem, otwarciem w kolor lub 1NT.

POKÓJ ROZGRYWAJĄCEGO
Licz lewy wygrywające, ściągaj atuty, wyrabiaj długie kolory, rób impasy i wybieraj właściwą kartę w sytuacjach przy stole.

POKÓJ OBRONY
Trenuj wisty, sekwencje, grę z trzeciej ręki, powroty w kolor i nawyki partnerskie.

BRIDGE+ (OPCJONALNIE)
Wszystko powyższe pozostaje bezpłatne. Bridge+ dodaje dodatkowe ćwiczenia w każdym pokoju dla początkujących oraz odblokowuje Master Tables z konwencjami, zaawansowaną rozgrywką i strategią gry meczowej.

STWORZONY DO NAUKI
Interaktywne karty szkoleniowe, szybkie quizy, realistyczne 13-kartowe ręce, scenariusze gry, serie zwycięstw oraz codzienny trening mieszany, który powraca do błędów.

Bridge Trainer opiera się na podstawach systemu Standard American. Uzgodnienia partnerskie bywają różne, dlatego zawsze potwierdzaj konwencje ze swoim partnerem.

SUBSKRYPCJE
Bridge+ jest dostępny w formie automatycznie odnawialnej subskrypcji lub jednorazowego zakupu: Miesięcznie 1.99 $/miesiąc, Rocznie 9.99 $/rok (obie opcje zawierają 1 tydzień darmowego okresu próbnego) lub Dożywotnio 29.99 $ jednorazowo. Płatność jest pobierana z konta Apple ID po potwierdzeniu zakupu. Subskrypcje odnawiają się automatycznie, chyba że zostaną anulowane co najmniej 24 godziny przed końcem bieżącego okresu. Możesz zarządzać subskrypcją lub ją anulować w dowolnym momencie w Ustawieniach Konta na swoim urządzeniu. Warunki korzystania (standardowa umowa EULA firmy Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Polityka prywatności: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ru": {
        "name": "Bridge Trainer: Бридж обучение",
        "subtitle": "Практика бриджа и торговли",
        "keywords": "бридж,торговля,карты,обучение,новичок,урок,тренировка,защита,разыгрывающий,практика,игра,контракт",
        "promotional_text": "Пятиминутные упражнения по бриджу: торговля, розыгрыш и защита. Узнайте логику каждого хода.",
        "release_notes": "Добро пожаловать в Bridge Trainer. Изучайте правила, открытия, розыгрыш и защиту в четырех комнатах.",
        "description": """Развивайте настоящие инстинкты игры в контрактный бридж за пятиминутные сессии.

Bridge Trainer превращает основы, необходимые новичкам, в быстрые и сфокусированные упражнения. Без соперников, таймеров и давления. Считайте очки, выбирайте заявку, планируйте розыгрыш и осваивайте защитные приемы с объяснением каждого решения.

ЧЕТЫРЕ БЕСПЛАТНЫЕ КОМНАТЫ ДЛЯ ПРАКТИКИ

КАРТОЧНАЯ КОМНАТА
Изучите старшинство карт, очки за фигуры, взятки, козыри, контракты и роли за столом.

КОМНАТА ТОРГОВЛИ
Практикуйте базовую систему Standard American. Оценивайте 13-карточные руки и выбирайте пас, открытие в масти или 1БК.

КОМНАТА РАЗЫГРЫВАЮЩЕГО
Считайте верные взятки, собирайте козырей, создавайте длинные масти, делайте импасы и находите верный ход.

КОМНАТА ЗАЩИТЫ
Тренируйте первые ходы, последовательности, игру третьей рукой, возвраты масти и партнерские привычки.

BRIDGE+ (ОПЦИОНАЛЬНО)
Все функции выше остаются бесплатными. Подписка Bridge+ добавляет дополнительные упражнения в каждую комнату и открывает доступ к Master Tables со сложными конвенциями, продвинутым розыгрышем и дубликатной стратегией.

СОЗДАНО ДЛЯ ОБУЧЕНИЯ
Интерактивные учебные карточки, быстрые тесты, реальные 13-карточные руки, сценарии розыгрыша, серии побед и ежедневные смешанные тренировки для повторения ошибок.

Bridge Trainer использует базовую систему Standard American. Партнерские соглашения могут отличаться, поэтому согласовывайте конвенции со своим партнером.

ПОДПИСКИ
Bridge+ доступен по автоматически продлеваемой подписке или в виде разовой покупки: Ежемесячно $1.99/месяц, Ежегодно $9.99/год (обе подписки включают 1 неделю бесплатного периода) или Пожизненно $29.99 единоразово. Оплата списывается с вашей учетной записи Apple ID при подтверждении покупки. Подписки продлеваются автоматически, если они не были отменены как минимум за 24 часа до окончания текущего периода. Управляйте подпиской или отменяйте ее в любое время в настройках учетной записи на вашем устройстве. Условия использования (стандартное соглашение EULA Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Политика конфиденциальности: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "uk": {
        "name": "Bridge Trainer: Бридж навчання",
        "subtitle": "Практика бриджу та торгівлі",
        "keywords": "бридж,торгівля,карти,навчання,новачок,урок,тренування,захист,розігруючий,практика,гра,контракт",
        "promotional_text": "П'ятихвилинні вправи з бриджу: торгівля, розіграш та захист. Дізнайтеся логіку кожного ходу.",
        "release_notes": "Ласкаво просимо до Bridge Trainer. Вивчайте правила, відкриття, розіграш та захист у чотирьох кімнатах.",
        "description": """Розвивайте справжні інстинкти гри в контрактний бридж за п'ятихвилинні сесії.

Bridge Trainer перетворює основи, необхідні новичкам, у швидкі та сфокусовані вправи. Без суперників, таймерів та тиску. Рахуйте очки, вибирайте заявку, плануйте розіграш та освоюйте захисні прийоми з поясненням кожного рішення.

ЧОТИРИ БЕЗКОШТОВНІ КІМНАТИ ДЛЯ ПРАКТИКИ

КАРТКОВА КІМНАТА
Вивчіть старшинство карт, очки за фігури, взятки, козирі, контракти та ролі за столом.

КІМНАТА ТОРГІВЛІ
Практикуйте базову систему Standard American. Оцінюйте 13-карткові руки та вибирайте пас, відкриття в масті або 1БК.

КІМНАТА РОЗІГРУЮЧОГО
Рахуйте певні взятки, збирайте козирів, створюйте довгі масті, робіть імпаси та знаходьте правильний хід.

КІМНАТА ЗАХИСТУ
Тренируйте перші ходи, послідовності, гру третьою рукою, повернення масті та партнерські звички.

BRIDGE+ (ОПЦІОНАЛЬНО)
Усі функції вище залишаються безкоштовними. Підписка Bridge+ додає додаткові вправи в кожну кімнату та відкриває доступ до Master Tables зі складними конвенціями, просунутим розіграшем та дублікатною стратегією.

СТВОРЕНО ДЛЯ НАВЧАННЯ
Інтерактивні навчальні картки, швидкі тести, реальні 13-карткові руки, сценарії розіграшу, серії перемог та щоденні змішані тренування для повторення помилок.

Bridge Trainer використовує базову систему Standard American. Партнерські угоди можуть відрізнятися, тому узгоджуйте конвенції зі своїм партнером.

ПІДПИСКИ
Bridge+ доступний за підпискою, що автоматично продовжується, або у вигляді разової покупки: Щомісяця $1.99/місяць, Щорічно $9.99/рік (обидві підписки включають 1 тиждень безкоштовного періоду) або Довічно $29.99 одноразово. Оплата списується з вашого облікового запису Apple ID під час підтвердження покупки. Підписки продовжуються автоматично, якщо вони не були скасовані щонайменше за 24 години до закінчення поточного періоду. Керуйте підпискою або скасовуйте її у будь-який час у налаштуваннях облікового запису на вашому пристрої. Умови використання (стандартна угода EULA Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Політика конфіденційності: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "hu": {
        "name": "Bridge Trainer: Licit és játék",
        "subtitle": "Licit és kártyajáték edzés",
        "keywords": "bridzs,licit,kártya,tanulás,tutor,kezdő,lecke,gyakorlat,védekezés,felvevő,edzés,játék,osztás,lap",
        "promotional_text": "Ötperces bridzsgyakorlatok a licitre, a játékra és a védekezésre. Értsd meg a miérteket.",
        "release_notes": "Üdvözöl a Bridge Trainer. Gyakorold a szabályokat, az indító liciteket, a játékot és a védekezést 4 ingyenes szobában.",
        "description": """Építs ki valódi bridzsösztönöket napi ötperces gyakorlásokkal.

A Bridge Trainer a kezdők számára legfontosabb alapokat alakítja át gyors, fókuszált gyakorlatokká. Nincsenek ellenfelek, nincs időzítő és nincs nyomás. Számolj pontokat, válassz indító licitet, tervezd meg a játékot és sajátíts el védekező szokásokat a válaszok magyarázataival.

NÉGY INGYENES GYAKORLÓSZOBA

A KÁRTYASZOBA
Tanuld meg a kártyák rangsorát, a figurapontokat, az ütéseket, az adut, a szerződéseket és az asztali szerepeket.

A LICITSZOBA
Gyakorold a kezdő Standard American rendszert. Mérd fel a 13 lapos kezeket, és dönts a passz, a színes indítás vagy az 1NT között.

A JÁTÉKSZOBA
Számold a biztos ütéseket, húzz adut, építs ki hosszú színeket, játssz impasszokat, és válaszd a helyes lapot.

A VÉDEKEZÉSSZOBA
Gyakorold az induló lapokat, a szekvenciákat, a színvisszaadásokat és a partnermegállapodásokat.

BRIDGE+ (OPCIONÁLIS)
Minden fenti funkció ingyenes marad. A Bridge+ extra gyakorlatokat biztosít minden szobában, és feloldja a Master Tables-t konvenciókkal, haladó kártyajátékkal és párosverseny-stratégiával.

TANULÁSRA TERVEZVE
Súgókártyák, gyors tesztek, valósághű 13 lapos kezek, játékhelyzetek, sorozatok és napi vegyes gyakorlás a hibák ismétlésére.

A Bridge Trainer a kezdő Standard American rendszert használja. A partnermegállapodások eltérhetnek, ezért egyeztesd a konvenciókat a partnereddel.

ELŐFIZETÉSEK
A Bridge+ automatikusan megújuló előfizetéssel vagy egyszeri vásárlással érhető el: Havonta $1.99/hó, Évente $9.99/év (mindkettő 1 hét ingyenes próbát tartalmaz), vagy Örökös $29.99 egyszeri díj. A fizetés a vásárlás megerősítésekor az Apple ID fiókodat terheli. Az előfizetések automatikusan megújulnak, hacsak nem mondod le legalább 24 órával az aktuális időszak vége előtt. Kezeld vagy mondd le bármikor a készüléked Fiókbeállításaiban. Felhasználási feltételek (Apple standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Adatvédelmi irányelvek: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ro": {
        "name": "Bridge Trainer: Licitație",
        "subtitle": "Exerciții de licitație bridge",
        "keywords": "bridge,licitație,cărți,învățare,tutor,începător,lecție,exercițiu,apărare,declarant,practică,joc",
        "promotional_text": "Exerciții de bridge de cinci minute pentru licitație, jocul declarantului și apărare. Înțelege argumentele.",
        "release_notes": "Bun venit la Bridge Trainer. Practică reguli, licitații de deschidere, jocul declarantului și apărarea în 4 camere gratuite.",
        "description": """Dezvoltă instincte reale de bridge de contract în sesiuni de cinci minute.

Bridge Trainer transformă conceptele esențiale pentru începători în exerciții rapide și concentrate. Fără adversari, fără cronometre și fără presiune. Numără punctele, alege o licitație de deschidere, planifică jocul și învață obiceiuri de apărare cu explicația din spatele fiecărui răspuns.

PATRU CAMERE DE PRACTICĂ GRATUITE

CAMERA CĂRȚILOR
Învață valoarea cărților, punctele din onoruri, levele, atuul, contractele și rolurile la masă.

CAMERA DE LICITAȚIE
Practică sistemul Standard American pentru începători. Citește mâini de 13 cărți și alege între pas, deschidere la culoare sau 1NT.

CAMERA DECLARANTULUI
Numără levele sigure, colectează atuul, dezvoltă culorile lungi, fă pasaje și alege cartea potrivită în joc.

CAMERA DE APĂRARE
Antrenează atacurile, secvențele, jocul din mâna a treia, returul de culoare și obiceiurile de parteneriat.

BRIDGE+ (OPȚIONAL)
Toate funcțiile de mai sus rămân gratuite. Bridge+ adaugă exerciții suplimentare în fiecare cameră de începători și deblochează Master Tables, cu convenții, joc de cărți avansat și strategie de duplicat.

CONCEPUT PENTRU ÎNVĂȚARE
Carduri educaționale interactive, teste rapide, mâini reale de 13 cărți, scenarii de joc, serii de victorii și o sesiune mixtă zilnică ce reia conținutul ratat.

Bridge Trainer utilizează sistemul Standard American pentru începători. Convențiile de parteneriat pot varia, deci confirmă acordurile cu partenerul tău.

ABONAMENTE
Bridge+ este disponibil prin abonament auto-renovabil sau achiziție unică: Lunar $1.99/lună, Anual $9.99/an (ambele includ 1 săptămână de probă gratuită) sau Pe viață $29.99 plată unică. Plata este debitată din contul tău Apple ID la confirmarea achiziției. Abonamentele se reînnoiesc automat, cu excepția cazului în care sunt anulate cu cel puțin 24 de ore înainte de sfârșitul perioadei curente. Gestionează sau anulează oricând din Setările Contului de pe dispozitivul tău. Termeni de utilizare (EULA standard Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Politica de confidențialitate: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "hr": {
        "name": "Bridge Trainer: Učenje i licit",
        "subtitle": "Trening licitacije u brižu",
        "keywords": "bridž,licitacija,karte,učenje,tutor,početnik,lekcija,vježba,obrana,izvođač,trening,igra,ugovor,adut",
        "promotional_text": "Petominutne briž vježbe za licitaciju, zohrávku i obranu. Naučite zašto iza svake karte.",
        "release_notes": "Dobrodošli u Bridge Trainer. Vježbajte pravila, otvaranja, zohrávku i obranu u četiri besplatne sobe.",
        "description": """Izgradite prave instinkte za kontraktni briž u petominutnim sesijama.

Bridge Trainer pretvara najvažnije dijelove za početnike u brze, fokusirane vježbe. Bez protivnika, bez mjerača vremena i bez pritiska. Brojite bodove, odaberite otvarajući licit, planirajte igru i naučite obrambene navike uz objašnjenje svakog odgovora.

ČETIRI BESPLATNE SOBE ZA VJEŽBANJE

SOBA KARTA
Naučite vrijednosti karata, bodove u slikama, štihove, adute, ugovore i uloge za stolom.

SOBA ZA LICITACIJU
Vježbajte početni Standard American sustav. Čitajte ruke od 13 karata i birajte između pasa, otvaranja u boji ili 1NT.

SOBA IZVOĐAČA
Brojite pobjedničke štihove, izvlačite adute, uspostavljajte duge boje, radite finesse i birajte pravu kartu.

SOBA ZA OBRANU
Trenirajte izlaze, sekvence, igru treće ruke, vraćanje boje i partnerske navike.

BRIDGE+ (OPCIONALNO)
Sve gore navedeno ostaje besplatno. Bridge+ dodaje dodatne vježbe u svakoj sobi za početnike i otključava Master Tables s konvencijama, naprednom igrom i turnirskom taktikom.

DIZAJNIRANO ZA UČENJE
Kartice s uputama, brzi kvizovi, realistične ruke s 13 karata, scenariji igre, nizovi pobjeda i svakodnevna mješovita sesija koja vraća propušteno gradivo.

Bridge Trainer koristi početni Standard American sustav. Partnerski dogovori se razlikuju, stoga uvijek potvrdite konvencije s partnerom.

PRETPLATE
Bridge+ je dostupan putem pretplate koja se automatski obnavlja ili jednokratne kupnje: Mjesečno $1.99/mjesečno, Godišnje $9.99/godišnje (oba uključuju 1 tjedan besplatnog probnog razdoblja) ili Doživotno $29.99 jednokratno. Plaćanje se naplaćuje s vašeg Apple ID računa prilikom potvrde kupnje. Pretplate se automatski obnavljaju osim ako se ne otkažu najmanje 24 sata prije kraja tekućeg razdoblja. Upravljajte ili otkažite u bilo kojem trenutku u Postavkama Računa na svom uređaju. Uvjeti korištenja (standardni Apple EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Pravila o privatnosti: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "tr": {
        "name": "Bridge Trainer: Briç Öğren",
        "subtitle": "Briç konuşma ve kart pratiği",
        "keywords": "briç,konuşma,kartlar,öğren,tutor,yeni başlayan,ders,drill,savunma,deklaran,pratik,oyun,kontrat,bilgi",
        "promotional_text": "Konuşma, deklaran oyunu ve savunma için bei dakikalık briç egzersizleri. Her kartın mantığını öğrenin.",
        "release_notes": "Bridge Trainer'a hoş geldiniz. Dört ücretsiz odada kuralları, açış deklarasyonlarını ve savunmayı çalışın.",
        "description": """Beş dakikalık seanslarla gerçek briç içgüdüleri geliştirin.

Bridge Trainer, yeni başlayanların en çok ihtiyaç duyduğu konuları hızlı ve odaklanmış alıştırmalara dönüştürür. Rakip yok, süre sınırı yok ve baskı yok. Puanları sayın, açış konuşmasını seçin, oyunu planlayın ve her cevabın arkasındaki mantıkla savunma alışkanlıkları edinin.

DÖRT ÜCRETSİZ PRATİK ODASI

KART ODASI
Kart değerlerini, onör puanlarını, löveleri, kozları, kontratları ve masa rollerini öğrenin.

DEKLARASYON ODASI
Yeni başlayanlar için Standard American sistemini çalışın. 13 kartlık elleri okuyun ve pas, renk açışı veya 1NT arasından seçim yapın.

DEKLARAN ODASI
Alıcı löveleri sayın, koz çekin, uzun renkleri sağlayın, empas yapın ve oyun durumlarında doğru kartı seçin.

SAVUNMA ODASI
Atakları, sekansları, üçüncü el oyununu, renk dönüşlerini ve ortaklık alışkanlıklarını çalışın.

BRIDGE+ (OPSİYONEL)
Yukarıdaki her şey ücretsiz kalmaya devam eder. Bridge+, her başlangıç odasına ekstra pratik ekler ve konvansiyonlar, ileri düzey kart oyunu ve duplicate stratejisi içeren Master Tables seçeneğini açar.

ÖĞRENMEK İÇİN TASARLANDI
Kaydırılabilir koçluk kartları, hızlı testler, gerçekçi 13 kartlık eller, kart oyunu senaryoları, seriler ve kaçırılan materyalleri geri getiren günlük karışık pratikler.

Bridge Trainer, yeni başlayanlar için Standard American sistemini kullanır. Ortaklık anlaşmaları değişebilir, bu nedenle konvansiyonları ortağınızla teyit edin.

ABONELİKLER
Bridge+, otomatik yenilenen abonelik veya tek seferlik satın alma ile sunulmaktadır: Aylık 1.99 $/ay, Yıllık 9.99 $/yıl (her ikisi de 1 haftalık ücretsiz deneme süresi içerir) veya Ömür Boyu 29.99 $ tek seferlik ödeme. Ödeme, satın alma onayında Apple ID hesabınızdan tahsil edilir. Abonelikler, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir. Cihazınızdaki Hesap Ayarları bölümünden aboneliğinizi istediğiniz zaman yönetebilir veya iptal edebilirsiniz. Kullanım Koşulları (Apple standart EULA'sı): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Gizlilik Politikası: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "el": {
        "name": "Bridge Trainer: Μάθε Μπριτζ",
        "subtitle": "Εξάσκηση και εκμάθηση Μπριτζ",
        "keywords": "μπριτζ,μάθηση,τραπουλόχαρτα,αρχάριος,μάθημα,άσκηση,άμυνα,εκτελεστής,εξάσκηση,παιχνίδι,χαρτιά,κόντρα",
        "promotional_text": "Ασκήσεις μπριτζ πέντε λεπτών για αγορές, εκτέλεση και άμυνα. Μάθετε το γιατί πίσω από κάθε κάρτα.",
        "release_notes": "Καλώς ορίσατε στο Bridge Trainer. Εξασκηθείτε στους κανόνες, τις αγορές, την εκτέλεση και την άμυνα σε 4 δωρεάν δωμάτια.",
        "description": """Αναπτύξτε αληθινά ένστικτα μπριτζ συμβολαίου σε συνεδρίες πέντε λεπτών.

Το Bridge Trainer μετατρέπει τα μέρη που χρειάζονται περισσότερο οι αρχάριοι σε γρήγορες, εστιασμένες ασκήσεις. Χωρίς αντιπάλους, χωρίς χρονόμετρα και χωρίς πίεση. Μετρήστε πόντους, επιλέξτε μια αγορά ανοίγματος, σχεδιάστε το παιχνίδι και μάθετε αμυντικές συνήθειες με την εξήγηση πίσω από κάθε απάντηση.

ΤΕΣΣΕΡΑ ΔΩΡΕΑΝ ΔΩΜΑΤΙΑ ΕΞΑΣΚΗΣΗΣ

ΤΟ ΔΩΜΑΤΙΟ ΤΩΝ ΧΑΡΤΙΩΝ
Μάθετε την αξία των χαρτιών, τους πόντους των φιγούρων, τις μπάζες, τα ατού, τα συμβόλαια και τους ρόλους στο τραπέζι.

ΤΟ ΔΩΜΑΤΙΟ ΤΩΝ ΑΓΟΡΩΝ
Εξασκηθείτε στο σύστημα Standard American για αρχάριους. Διαβάστε χέρια 13 φύλλων και επιλέξτε μεταξύ πάσο, ανοίγματος σε χρώμα ή 1NT.

ΤΟ ΔΩΜΑΤΙΟ ΤΟΥ ΕΚΤΕΛΕΣΤΗ
Μετρήστε τις νικηφόρες μπάζες, τραβήξτε τα ατού, δημιουργήστε μακριά χρώματα, κάντε φινέζες και επιλέξτε το σωστό φύλλο.

ΤΟ ΔΩΜΑΤΙΟ ΤΗΣ ΑΜΥΝΑΣ
Προπονηθείτε στα ξεκινήματα (εντάμ), τις αλληλουχίες, το παιχνίδι από το τρίτο χέρι και τις συνήθειες της συνεργασίας.

BRIDGE+ (ΠΡΟΑΙΡΕΤΙΚΟ)
Όλα τα παραπάνω παραμένουν δωρεάν. Το Bridge+ προσθέτει επιπλέον εξάσκηση σε κάθε δωμάτιο αρχαρίων και ξεκλειδώνει τα Master Tables, με συμβάσεις, προχωρημένο παιχνίδι και στρατηγική duplicate.

ΣΧΕΔΙΑΣΜΕΝΟ ΓΙΑ ΜΑΘΗΣΗ
Κάρτες εκπαίδευσης, γρήγορα κουίζ, ρεαλιστικά χέρια 13 φύλλων, σενάρια παιχνιδιού, σερί επιτυχιών και μια καθημερινή μικτή συνεδρία που επαναφέρει τα λάθη.

Το Bridge Trainer χρησιμοποιεί το σύστημα Standard American για αρχάριους. Οι συμφωνίες μεταξύ των ζευγαριών ποικίλλουν, επομένως επιβεβαιώστε τις συμβάσεις με τον σύντροφό σας.

ΣΥΝΔΡΟΜΕΣ
Το Bridge+ είναι διαθέσιμο με συνδρομή που ανανεώνεται αυτόματα ή με εφάπαξ αγορά: Μηνιαία $1.99/μήνα, Ετήσια $9.99/έτος (και οι δύο περιλαμβάνουν δωρεάν δοκιμή 1 εβδομάδας) ή Lifetime $29.99 εφάπαξ. Η πληρωμή χρεώνεται στον λογαριασμό σας Apple ID κατά την επιβεβαίωση της αγοράς. Οι συνδρομές ανανεώνονται αυτόματα εκτός εάν ακυρωθούν τουλάχιστον 24 ώρες πριν από το τέλος της τρέχουσας περιόδου. Διαχειριστείτε ή ακυρώστε ανά πάσα στιγμή στις Ρυθμίσεις Λογαριασμού της συσκευής σας. Όροι Χρήσης (τυπικό EULA της Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Πολιτική Απορρήτου: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ja": {
        "name": "Bridge Trainer: コントラクトブリッジ練習",
        "subtitle": "初心者向けコントラクトブリッジ叫牌とカードの実戦練習",
        "keywords": "ブリッジ,叫牌,カード,トランプ,学習,初心者,レッスン,ドリル,防衛,宣言者,練習,コントラクト,ゲーム,スコア,ルール,上達,必勝,問題集,入門,対戦,勝率,解説,コツ,満点,基本,攻略",
        "promotional_text": "叫牌（ビディング）、デクレアラープレイ、ディフェンスを学ぶ5分間のブリッジ練習。各カードの理由を学ぶ。",
        "release_notes": "Bridge Trainerへようこそ。4つの無料ルームで、ルール、オープニングビッド、プレイ、ディフェンスを練習しましょう。",
        "description": """5分間のセッションで、コントラクトブリッジの確かな直感を養いましょう。

Bridge Trainerは、初心者が最も必要とする基礎を、すばやく集中してできるドリル形式に落とし込みました。対戦相手も、タイマーも、プレッシャーもありません。ポイントを数え、オープニングビッドを選択し、プレイを計画し、各回答の背景にある解説を読みながらディフェンスのコツを身につけます。

4つの無料練習ルーム

カードルーム
カードの強さ、ハイカードポイント、トリック、切り札、コントラクト、テーブルでの役割を学びます。

オークションルーム
初心者向けのスタンダードアメリカン（Standard American）体系を練習します。13枚の手札を読み、パス、スートオープン、1NTのいずれかを選択します。

デクレアラールーム
ウィナーを数え、切り札を狩り、ロングスートを確立し、フィネスを行い、テーブルの状況に応じて正しいカードを選択します。

ディフェンスルーム
オープニングリード、シーケンス、サードハンドプレイ、スートリターン、パートナーシップの習慣を訓練します。

BRIDGE+（オプション）
上記の機能はすべて永久に無料です。Bridge+は、各初心者ルームに追加の練習用問題を追加し、コンベンション、高度なカードプレイ、デュプリケート戦略を学べるMaster Tablesをアンロックします。

学習のための設計
スワイプ可能なコーチングカード、クイッククイズ、リアルな13枚の手札シナリオ、カードプレイの展開、練習継続の記録、間違えた問題を再出題するデイリーミックスセッションなどを搭載しています。

Bridge Trainerは初心者向けのスタンダードアメリカン（Standard American）体系を採用しています。パートナーシップごとの合意事項は異なる場合があるため、コンベンションはご自身のパートナーと確認してください。

サブスクリプション
Bridge+は、自動更新サブスクリプションまたは一回限りの購入でご利用いただけます：月額$1.99/月、年額$9.99/年（どちらも1週間の無料トライアル付き）、または生涯（ライフタイム）$29.99の一回限りの支払い。購入確定時にApple IDアカウントに課金されます。現在の期間が終了する少なくとも24時間前にキャンセルされない限り、サブスクリプションは自動的に更新されます。購入後はいつでもデバイスのアカウント設定で管理またはキャンセルが可能です。利用規約（Apple標準EULA）：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. プライバシーポリシー：https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ko": {
        "name": "Bridge Trainer: 브릿지 비딩 연습",
        "subtitle": "초보자를 위한 실전 브릿지 비딩 및 카드 게임 연습",
        "keywords": "브릿지,비딩,카드,트럼프,학습,초보자,레슨,드릴,수비,디클레어러,연습,콘트랙트,게임,룰,점수,강좌,전략,문제,도우미,퀴즈,특강,공략,기초,해설,공부,비법,가이드,놀이,상식,훈련",
        "promotional_text": "비딩, 디클레어러 플레이, 디펜스를 익히는 5분 브릿지 드릴. 각 카드의 원리를 배웁니다.",
        "release_notes": "Bridge Trainer에 오신 것을 환영합니다. 네 개의 무료 룸에서 룰, 오픈 비딩, 플레이, 디펜스를 연습해 보세요.",
        "description": """5분간의 세션으로 실전 콘트랙트 브릿지 직관을 기르세요.

Bridge Trainer는 초보자에게 가장 필요한 기초 영역들을 빠르고 집중적인 드릴 형식으로 담았습니다. 대전 상대도, 타이머도, 압박감도 없습니다. 승점을 계산하고, 오픈 비딩을 선택하고, 플레이 계획을 세우며, 매 답변마다 주어지는 상세한 해설을 통해 수비 감각을 기를 수 있습니다.

네 개의 무료 연습 룸

카드 룸
카드 서열, 하이카드 포인트(HCP), 트릭, 트럼프, 콘트랙트 및 테이블에서의 역할을 배웁니다.

옥션 룸
초보자용 스탠더드 아메리칸(Standard American) 체계를 연습합니다. 13장의 카드를 읽고 패스, 수트 오픈, 1NT 중 알맞은 비드를 선택합니다.

디클레어러 룸
위너를 세고, 트럼프를 뽑고, 롱 수트를 세우고, 피네스를 시도하며 상황에 맞는 올바른 카드를 선택합니다.

디펜스 룸
오프닝 리드, 시퀀스, 써드 핸드 플레이, 수트 리턴, 파트너십 수비 원칙을 훈련합니다.

BRIDGE+ (선택 사항)
위의 모든 핵심 룸은 언제나 무료입니다. Bridge+는 각 룸에 추가 연습 세트를 더하고 컨벤션, 상급 카드 플레이, 듀플리케이트 전략이 포함된 Master Tables를 열어줍니다.

학습을 위한 완벽한 설계
스와이프할 수 있는 코칭 카드, 퀵 퀴즈, 실감 나는 13장 카드 패, 실전 플레이 시나리오, 연속 연습 스트릭, 그리고 틀린 문제를 다시 확인하는 데일리 믹스 세션을 제공합니다.

Bridge Trainer는 초보자용 스탠더드 아메리칸(Standard American) 비딩 체계를 따릅니다. 파트너십 합의는 저마다 다를 수 있으므로, 구체적인 컨벤션은 파트너와 함께 확인하시기 바랍니다.

구독 서비스
Bridge+는 자동 갱신 구독 또는 일회성 구매로 이용할 수 있습니다: 월간 구독 $1.99/월, 연간 구독 $9.99/년 (두 구독 모두 1주일 무료 체험 제공) 또는 평생 라이프타임 $29.99 일회성 구매. 구매 확인 시 Apple ID 계정으로 결제 금액이 청구됩니다. 현재 기간이 끝나기 최소 24시간 전에 취소하지 않으면 구독이 자동으로 갱신됩니다. 구매 후 언제든지 기기의 계정 설정에서 구독을 관리하거나 취소할 수 있습니다. 이용 약관 (Apple 표준 EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. 개인정보 처리방침: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "zh-Hans": {
        "name": "Bridge Trainer: 桥牌学习叫牌打牌",
        "subtitle": "针对初学者的无压力合约桥牌叫牌与打牌防守核心特训",
        "keywords": "桥牌,叫牌,打牌,扑克,学习,新手,课程,训练,防守,庄家,练习,合约,游戏,得分,规则,黄卡,大牌点,超墩,双人赛,防守首攻,飞牌,桥艺,定约,牌局,首攻,跟牌,叫牌室,赢墩,黑桃,红心",
        "promotional_text": "包含叫牌、庄家打牌和防守的5分钟桥牌训练。学习每张牌背后的原理。",
        "release_notes": "欢迎使用 Bridge Trainer。在四个免费练习室中练习规则、开叫、庄家打牌与防守。",
        "description": """在五分钟的训练中，培养合约桥牌直觉。

Bridge Trainer 将初学者最需要的核心基础转化为快速、专注的跟练牌局。没有对手，没有计时，毫无压力。数大牌点、选择开叫、规划庄家路线，并在每道题的原理剖析中，逐步养成良好的防守习惯。

四个免费练习室

牌例室
学习牌张大小、大牌点、赢墩、将牌、合约以及桌上的角色分工。

叫牌室
练习初学者常用的美国标准黄卡（Standard American）体系。阅读13张手牌，在过牌、花色开叫或 1NT 之间做出选择。

庄家室
清点赢墩、清将、树立长套、飞牌，并在各种实战牌局中选择正确的出牌。

防守室
训练首攻、连张出牌、第三家出牌、回牌以及同伴间的防守默契。

BRIDGE+（可选升级）
上述所有练习室永久免费。Bridge+ 庄家在此基础上提供额外的扩展训练，并解锁 Master Tables，提供进阶约定叫、高阶打牌技巧和双人赛 duplicate 策略。

专为学习而设计
可滑动翻阅的教练卡、快速测试、真实的13张手牌例、出牌实战场景、练习连击纪录，以及可温习错题的每日混合温习课。

Bridge Trainer 采用初学者美国标准叫牌体系。由于同伴间的约定可能各有不同，请与您的搭档确认具体的约定叫。

订阅服务
Bridge+ 可通过自动续期订阅或一次性购买获取：按月订阅 $1.99/月，按年订阅 $9.99/年（两者均包含1周免费试用），或终身（一次性购买）$29.99。确认购买后将从您的 Apple ID 账户中扣款。除非在当前周期结束前至少24小时取消，否则订阅将自动续期。您可以随时在设备的“账户设置”中管理或取消订阅。使用条款（Apple 标准 EULA）：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/。隐私政策：https://jackwallner.github.io/bridge/privacy-policy。"""
    },
    "zh-Hant": {
        "name": "Bridge Trainer: 橋牌學習叫牌打牌",
        "subtitle": "針對初學者的無壓力合約橋牌叫牌與打牌防守核心特訓",
        "keywords": "橋牌,叫牌,打牌,撲克,學習,新手,課程,訓練,防守,庄家,練習,合約,遊戲,得分,規則,黃卡,大牌點,超墩,雙人賽,防守首攻,飛牌,橋藝,定約,牌局,首攻,跟牌,叫牌室,贏墩,黑桃,紅心",
        "promotional_text": "包含叫牌、莊家打牌和防守的5分鐘橋牌訓練。學習每張牌背後的原理。",
        "release_notes": "歡迎使用 Bridge Trainer。在四個免費練習室中練習規則、開叫、莊家打牌與防守。",
        "description": """在五分鐘的訓練中，培養合約橋牌直覺。

Bridge Trainer 將初學者最需要的核心基礎轉化為快速、專注的跟練牌局。沒有對手，沒有計時，毫無壓力。數大牌點、選擇開叫、規劃莊家路線，並在每道題的原理剖析中，逐步養成良好的防守習慣。

四個免費練習室

牌例室
學習牌張大小、大牌點、贏墩、將牌、合約以及桌上的角色分工。

叫牌室
練習初學者常用的美國標準黃卡（Standard American）體系。閱讀13張手牌，在過牌、花色開叫或 1NT 之間做出選擇。

莊家室
清點贏墩、清將、樹立長套、飛牌，並在各種實戰牌局中選擇正確的出牌。

防守室
訓練首攻、連張出牌、第三家出牌、回牌以及同伴間的防守默契。

BRIDGE+（進階升級）
上述所有練習室永久免費。Bridge+ 莊家在此基礎上提供額外的擴展訓練，並解鎖 Master Tables，提供進階約定叫、高階打牌技巧和雙人賽 duplicate 策略。

專為學習而設計
可滑動翻閱的教練卡、快速測試、真實的13張手牌例、出牌實戰場景、練習連擊紀錄，以及可溫習錯題的每日混合溫習課。

Bridge Trainer 採用初學者美國標準叫牌體系。由於同伴間的約定可能各有不同，請與您的搭檔確認具體的約定叫。

訂閱服務
Bridge+ 可通過自動續期訂閱或一次性購買獲取：按月訂閱 $1.99/月，按年訂閱 $9.99/年（兩者均包含1週免費試用），或終線（一次性購買）$29.99。確認購買後將從您的 Apple ID 帳戶中扣款。除非在當前週期結束前至少24小時取消，否則訂閱將自動續期。您可以隨時在設備的“帳戶設置”中管理或取消訂閱。使用條款（Apple 標準 EULA）：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/。隱私政策：https://jackwallner.github.io/bridge/privacy-policy。"""
    },
    "th": {
        "name": "Bridge Trainer: ฝึกเล่นบริดจ์",
        "subtitle": "ฝึกประมูลและเล่นไพ่บริดจ์",
        "keywords": "บริดจ์,ประมูล,ไพ่,เรียน,ผู้สอน,ผู้เริ่มต้น,บทเรียน,ฝึกหัด,ป้องกัน,ผู้เล่น,ฝึกซ้อม,เกม,คะแนน,กฎ",
        "promotional_text": "แบบฝึกหัดบริดจ์ห้านาทีสำหรับการประมูล การเล่นของผู้ประกาศ และการป้องกัน เรียนรู้เหตุผล",
        "release_notes": "ยินดีต้อนรับสู่ Bridge Trainer ฝึกฝนกฎ การประมูลเปิด การเล่นของผู้ประกาศ และการป้องกันในสี่ห้องฟรี",
        "description": """สร้างสัญชาตญาณบริดจ์สัญญาที่แท้จริงในเซสชันห้านาที

Bridge Trainer เปลี่ยนส่วนที่มือใหม่ต้องการมากที่สุดให้เป็นแบบฝึกหัดที่รวดเร็วและตรงจุด ไม่มีคู่ต่อสู้ ไม่มีตัวจับเวลา และไม่มีความกดดัน นับแต้ม เลือกการประมูลเปิด วางแผนการเล่น และเรียนรู้นิสัยการป้องกันพร้อมเหตุผลเบื้องหลังทุกคำตอบ

ห้องฝึกหัดฟรีสี่ห้อง

ห้องไพ่
เรียนรู้ลำดับไพ่ แต้มไพ่สูง ตริก ทรัมป์ สัญญา และบทบาทบนโต๊ะ

ห้องประมูล
ฝึกฝนโครงสร้าง Standard American สำหรับมือใหม่ อ่านไพ่มือ 13 ใบและเลือกระหว่างผ่าน เปิดสี หรือ 1NT

ห้องผู้ประกาศ
นับตริกชนะ ดึงทรัมป์ สร้างชุดยาว ฟิเนส และเลือกไพ่ที่ถูกต้องในสถานการณ์บนโต๊ะ

ห้องป้องกัน
ฝึกฝนการนำเปิด ลำดับ การเล่นมือที่สาม การกลับชุด และนิสัยความเป็นพันธมิตร

BRIDGE+ (ตัวเลือกเสริม)
ทุกอย่างข้างต้นยังคงฟรี Bridge+ เพิ่มการฝึกฝนพิเศษในแต่ละห้องมือใหม่ และปลดล็อก Master Tables พร้อมคอนเวนชัน การเล่นไพ่ขั้นสูง และกลยุทธ์ duplicate

สร้างมาเพื่อการเรียนรู้
การ์ดสอนที่ปัดได้ ควิซสั้น ไพ่มือ 13 ใบที่สมจริง สถานการณ์การเล่นไพ่ สตรีค และเซสชันผสมรายวันที่นำเนื้อหาที่พลาดกลับมา

Bridge Trainer ใช้โครงสร้าง Standard American สำหรับมือใหม่ ข้อตกลงความเป็นพันธมิตรแตกต่างกันไป ดังนั้นโปรดยืนยันคอนเวนชันกับคู่ของคุณ

การสมัครสมาชิก
Bridge+ มีให้บริการโดยการสมัครสมาชิกต่ออายุอัตโนมัติหรือการซื้อครั้งเดียว: รายเดือน $1.99/เดือน, รายปี $9.99/ปี (ทั้งสองรวมทดลองใช้ฟรี 1 สัปดาห์) หรือตลอดชีพ $29.99 ครั้งเดียว การชำระเงินจะถูกหักจากบัญชี Apple ID ของคุณเมื่อยืนยันการซื้อ การสมัครสมาชิกจะต่ออายุอัตโนมัติเว้นแต่จะยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดระยะเวลาปัจจุบัน จัดการหรือยกเลิกได้ตลอดเวลาในการตั้งค่าบัญชีบนอุปกรณ์ของคุณ ข้อกำหนดการใช้งาน (EULA มาตรฐานของ Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. นโยบายความเป็นส่วนตัว: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "vi": {
        "name": "Bridge Trainer: Học chơi bài",
        "subtitle": "Luyện tập đấu thầu Bridge",
        "keywords": "bridge,đấu thầu,bài,học,hướng dẫn,người mới,bài học,luyện tập,phòng thủ,người đi bài,thực hành",
        "promotional_text": "Các bài tập chơi bridge năm phút để đấu thầu, chơi bài và phòng thủ. Học lý do đằng sau.",
        "release_notes": "Chào mừng bạn đến với Bridge Trainer. Luyện tập các quy tắc, mở thầu, đi bài và phòng thủ trong bốn phòng miễn phí.",
        "description": """Xây dựng bản năng chơi bridge hợp đồng thực sự trong các phiên năm phút.

Bridge Trainer chuyển đổi các phần mà người mới bắt đầu cần nhất thành các bài tập nhanh chóng, tập trung. Không có đối thủ, không có đồng hồ bấm giờ và không có áp lực. Tính điểm, chọn mở thầu, lập kế hoạch chơi bài và học các thói quen phòng thủ với lý do đằng sau mỗi câu trả lời.

BỐN PHÒNG LUYỆN TẬP MIỄN PHÍ

PHÒNG BÀI
Tìm hiểu thứ hạng bài, điểm bài cao, vòng ăn bài, quân bài chủ, hợp đồng và vai trò trên bàn.

PHÒNG ĐẤU THẦU
Luyện tập khung Standard American cho người mới bắt đầu. Đọc các tay bài 13 quân và chọn giữa chuyển lượt, mở thầu bộ hoặc 1NT.

PHÒNG NGƯỜI ĐI BÀI
Đếm các quân bài ăn điểm, rút quân bài chủ, thiết lập các bộ bài dài, lách bài và chọn đúng quân bài.

PHÒNG PHÒNG THỦ
Huấn luyện dẫn thầu, trình tự, chơi bài tay thứ ba, trả bộ bài và thói quen hợp tác đối tác.

BRIDGE+ (TÙY CHỌN)
Mọi thứ ở trên vẫn miễn phí. Bridge+ thêm luyện tập bổ sung trong mỗi phòng cho người mới bắt đầu và mở khóa Master Tables, với các quy ước, lối chơi nâng cao và chiến thuật duplicate.

THIẾT KẾ ĐỂ HỌC TẬP
Thẻ hướng dẫn có thể vuốt, câu đố nhanh, tay bài 13 quân thực tế, kịch bản đi bài, chuỗi ngày luyện tập và phiên hỗn hợp hàng ngày giúp ôn lại tài liệu bị bỏ lỡ.

Bridge Trainer sử dụng khung Standard American cho người mới bắt đầu. Thỏa thuận đối tác khác nhau, vì vậy hãy xác nhận các quy ước với đối tác của bạn.

ĐĂNG KÝ
Bridge+ có sẵn dưới dạng đăng ký tự động gia hạn hoặc mua một lần: Hàng tháng $1.99/tháng, Hàng năm $9.99/năm (cả hai đều bao gồm 1 tuần dùng thử miễn phí) hoặc Trọn đời $29.99 một lần. Thanh toán được tính vào tài khoản Apple ID của bạn khi xác nhận mua hàng. Đăng ký tự động gia hạn trừ khi bị hủy ít nhất 24 giờ trước khi kết thúc giai đoạn hiện tại. Quản lý hoặc hủy bất kỳ lúc nào trong Cài đặt tài khoản trên thiết bị của bạn. Điều khoản sử dụng (EULA tiêu chuẩn của Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Chính sách bảo mật: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "id": {
        "name": "Bridge Trainer: Belajar Bridge",
        "subtitle": "Latihan bidding & kartu bridge",
        "keywords": "bridge,bidding,kartu,belajar,tutor,pemula,pelajaran,latihan,pertahanan,deklarer,praktik,game,skor",
        "promotional_text": "Latihan bridge lima menit untuk penawaran (bidding), permainan declarer, and pertahanan. Pelajari alasannya.",
        "release_notes": "Selamat datang di Bridge Trainer. Latih aturan, bidding pembuka, permainan declarer, dan pertahanan di empat ruang gratis.",
        "description": """Bangun insting bermain contract bridge yang nyata dalam sesi lima menit.

Bridge Trainer mengubah bagian yang paling dibutuhkan pemula menjadi latihan yang cepat dan terfokus. Tidak ada lawan, tidak ada pengukur waktu, dan tidak ada tekanan. Hitung poin, pilih bidding pembuka, rencanakan permainan, dan pelajari kebiasaan bertahan dengan penjelasan di balik setiap jawaban.

EMPAT RUANG LATIHAN GRATIS

RUANG KARTU
Pelajari peringkat kartu, poin kartu tinggi (HCP), trik, trump, kontrak, dan peran di meja.

RUANG BIDDING
Latih sistem Standard American untuk pemula. Baca 13 kartu di tangan dan pilih antara pass, bid suit, atau 1NT.

RUANG DECLARER
Hitung kartu pemenang, tarik trump, bangun suit panjang, lakukan finesse, dan pilih kartu yang tepat dalam situasi permainan.

RUANG PERTAHANAN
Latih lead pembuka, urutan kartu, permainan tangan ketiga (third-hand play), pengembalian suit, dan kebiasaan kemitraan.

BRIDGE+ (OPSIONAL)
Semua fitur di atas tetap gratis. Bridge+ menambahkan latihan ekstra di setiap ruang pemula dan membuka Master Tables, yang dilengkapi dengan konvensi, permainan kartu tingkat lanjut, dan strategi duplicate.

DIRANCANG UNTUK BELAJAR
Kartu pelatihan yang dapat digeser, kuis cepat, 13 kartu tangan yang realistis, skenario permainan kartu, streak latihan, dan sesi campuran harian yang memunculkan kembali materi yang salah.

Bridge Trainer menggunakan sistem Standard American untuk pemula. Kesepakatan kemitraan bervariasi, jadi konfirmasikan konvensi dengan partner bermain Anda.

LANGGANAN
Bridge+ tersedia melalui langganan yang diperbarui secara otomatis atau pembelian satu kali: Bulanan $1.99/bulan, Tahunan $9.99/tahun (keduanya mencakup uji coba gratis 1 minggu), atau Seumur Hidup $29.99 sekali bayar. Pembayaran dibebankan ke akun Apple ID Anda pada saat konfirmasi pembelian. Langganan diperbarui secara otomatis kecuali dibatalkan setidaknya 24 jam sebelum akhir periode berjalan. Kelola atau batalkan kapan saja di Pengaturan Akun di perangkat Anda. Ketentuan Penggunaan (EULA standar Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Kebijakan Privasi: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ms": {
        "name": "Bridge Trainer: Belajar Bridge",
        "subtitle": "Latihan bidding & kad bridge",
        "keywords": "bridge,bidding,kad,belajar,tutor,pemula,pelajaran,latihan,pertahanan,deklarer,praktik,game,skor,main",
        "promotional_text": "Latihan bridge lima minit untuk bidaan (bidding), permainan declarer, dan pertahanan. Ketahui alasannya.",
        "release_notes": "Selamat datang ke Bridge Trainer. Latih peraturan, bidding pembuka, permainan declarer, dan pertahanan di empat bilik percuma.",
        "description": """Bina naluri bermain contract bridge yang sebenar dalam sesi lima minit.

Bridge Trainer mengubah bahagian yang paling diperlukan oleh pemula menjadi latihan yang pantas dan fokus. Tiada lawan, tiada pemasa, dan tiada tekanan. Kira mata, pilih bidding pembuka, rancang permainan, dan pelajari tabiat bertahan dengan penjelasan di sebalik setiap jawapan.

EMPAT BILIK LATIHAN PERCUMA

BILIK KAD
Pelajari kedudukan kad, mata kad tinggi (HCP), trik, trump, kontrak, dan peranan di meja.

BILIK BIDDING
Latih sistem Standard American untuk pemula. Baca 13 kad di tangan dan pilih antara pass, bid suit, atau 1NT.

BILIK DECLARER
Kira kad pemenang, tarik trump, bina suit panjang, lakukan finesse, dan pilih kad yang betul dalam situasi permainan.

BILIK PERTAHANAN
Latih lead pembuka, urutan kad, permainan tangan ketiga (third-hand play), pemulangan suit, dan tabiat perkongsian.

BRIDGE+ (PILIHAN)
Semua ciri di atas kekal percuma. Bridge+ menambah latihan ekstra di setiap bilik pemula dan membuka Master Tables, yang dilengkapi dengan konvensyen, permainan kad lanjutan, dan strategi duplicate.

DIREKA UNTUK BELAJAR
Kad latihan yang boleh digeser, kuiz cepat, 13 kad tangan yang realistik, senario permainan kad, streak latihan, dan sesi campuran harian yang memaparkan semula bahan yang salah.

Bridge Trainer menggunakan sistem Standard American untuk pemula. Persetujuan perkongsian berbeza-beza, jadi sahkan konvensyen dengan rakan kongsi anda.

LANGGANAN
Bridge+ tersedia melalui langganan yang diperbaharui secara automatik atau pembelian sekali sahaja: Bulanan $1.99/bulan, Tahunan $9.99/tahun (kedua-duanya termasuk percubaan percuma 1 minggu), atau Seumur Hidup $29.99 sekali bayar. Pembayaran dikenakan ke akaun Apple ID anda semasa pengesahan pembelian. Langganan diperbaharui secara automatik melainkan dibatalkan sekurang-kurangnya 24 jam sebelum tamat tempoh semasa. Urus atau batalkan pada bila-bila masa dalam Tetapan Akaun pada peranti anda. Syarat Penggunaan (EULA standard Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Dasar Privasi: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "sl-SI": {
        "name": "Bridge Trainer: Učenje briža",
        "subtitle": "Trening licitacije briža",
        "keywords": "briž,licitacija,karte,učenje,tutor,začetnik,lekcija,vaja,obramba,izvajalec,trening,igra,točke,adut",
        "promotional_text": "Petminutne vaje za licitacijo, igro izvajalca in obrambo pri brižu. Spoznajte ozadje odločitev.",
        "release_notes": "Dobrodošli v Bridge Trainer. Vadite pravila, otvoritvene napovedi, igro izvajalca in obrambo v štirih brezplačnih sobi.",
        "description": """Razvijte prave instinkte za kontraktni briž v petminutnih vajah.

Bridge Trainer spremeni dele, ki jih začetniki najbolj potrebujejo, v hitre in usmerjene vaje. Brez nasprotnikov, brez časovnikov in brez pritiska. Preštejte točke, izberite otvoritveno napoved, načrtujte igro in se naučite obrambnih navad z razlago za vsakim odgovorom.

ŠTIRI BREZPLAČNE SOBE ZA VADO

SOBA ZA KARTE
Spoznajte vrednost kart, točke za visoke karte, trike, adute, kontrakte in vloge pri mizi.

SOBA ZA LICITACIJO
Vadite začetni sistem Standard American. Preberite 13 kart v roki in izbirajte med pasom, otvoritvijo v barvi ali 1NT.

SOBA IZVAJALCA
Preštejte zmagovalne trike, izvlecite adute, vzpostavite dolge barve, izvajajte finese in izberite pravo karto v igri.

SOBA ZA OBRAMBO
Trenirajte otvoritvene izmete, sekvence, igro tretje roke, vračanje barve in partnerske dogovore.

BRIDGE+ (NEOBVEZNO)
Vse zgoraj navedeno ostaja brezplačno. Bridge+ dodaja dodatne vaje v vsaki sobi za začetnike in odklene Master Tables s konvencijami, napredno igro in turnirsko strategijo.

NAVRJENO ZA UČENJE
Poučne kartice z drsenjem, hitri kvizi, realistične roke s 13 kartami, scenariji igre, nizi zaporednih vadb in dnevne mešane vaje, ki vračajo napačne odgovore.

Bridge Trainer uporablja začetni sistem Standard American. Partnerski dogovori se razlikujejo, zato konvencije vedno potrdite s svojim partnerjem.

PRETPLATE
Bridge+ je na voljo s samodejno obnovljivo naročnino ali enkratnim nakupom: mesečno 1.99 $/mesec, letno 9.99 $/leto (obe vključujeta 1-tedensko brezplačno preskusno različico) ali doživljenjsko 29.99 $ enkratno plačilo. Plačilo se ob potrditvi nakupa zaračuna na vaš Apple ID račun. Naročnine se samodejno obnovijo, razen če jih prekličete vsaj 24 ur pred koncem trenutnega obdobja. Naročnino lahko kadar koli upravljate ali prekličete v nastavitvah računa v svoji napravi. Pogoji uporabe (standardni Apple EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. Pravilnik o zasebnosti: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "hi": {
        "name": "Bridge Trainer: ब्रिज सीखें",
        "subtitle": "ब्रिज बिडिंग और प्ले अभ्यास",
        "keywords": "ब्रिज,बिडिंग,पत्ते,सीखें,ट्यूटर,शुरुआती,पाठ,ड्रिल,डिफेंस,डिक्लेयरर,अभ्यास,खेल,पत्ती,स्कोर,मजेदार",
        "promotional_text": "बिडिंग, डिक्लेयरर प्ले, और डिफेंस के लिए पांच मिनट की ब्रिज ड्रिल। हर चाल का कारण समझें।",
        "release_notes": "ब्रिज ट्रेनर में आपका स्वागत है। चार मुफ्त कमरों में नियमों, बिडिंग, डिक्लेयरर प्ले और डिफेंस का अभ्यास करें।",
        "description": """पांच मिनट के सत्रों में असली कॉन्ट्रैक्ट ब्रिज की समझ विकसित करें।

Bridge Trainer शुरुआती लोगों के लिए सबसे महत्वपूर्ण हिस्सों को त्वरित, केंद्रित अभ्यासों में बदल देता है। कोई प्रतिद्वंद्वी नहीं, कोई टाइमर नहीं और कोई दबाव नहीं। अंक गिनें, ओपनिंग बिड चुनें, खेल की योजना बनाएं, और हर उत्तर के पीछे के कारणों के साथ डिफेंस की आदतें सीखें।

चार मुफ्त अभ्यास कक्ष

कार्ड रूम
कार्ड रैंकिंग, हाई-कार्ड पॉइंट (HCP), ट्रिक्स, ट्रम्प, कॉन्ट्रैक्ट्स और टेबल भूमिकाएं सीखें।

बिडिंग रूम
शुरुआती लोगों के लिए स्टैंडर्ड अमेरिकन फ्रेमवर्क का अभ्यास करें। 13 कार्डों वाले हाथों को पढ़ें और पास, सूट ओपनिंग, या 1NT में से चुनें।

डिक्लेयरर रूम
जीतने वाले कार्ड गिनें, ट्रम्प निकालें, लंबे सूट स्थापित करें, फिनेस करें, और खेल की स्थितियों में सही कार्ड चुनें।

डिफेंस रूम
ओपनिंग लीड, सीक्वेंस, थर्ड-हैंड प्ले, सूट रिटर्न, और पार्टनरशिप की आदतें सीखें।

BRIDGE+ (वैकल्पिक अपग्रेड)
ऊपर की हर चीज हमेशा मुफ्त रहती है। Bridge+ हर कमरे में अतिरिक्त अभ्यास सेट जोड़ता है और मास्टर टेबल्स को अनलॉक करता है, जिसमें कन्वेंशन, उन्नत कार्ड प्ले और डुप्लिकेट रणनीति शामिल हैं।

सीखने के लिए निर्मित
स्वाइप करने योग्य कोचिंग कार्ड, त्वरित प्रश्नोत्तरी, यथार्थवादी 13-कार्ड वाले हाथ, कार्ड-प्ले परिदृश्य, स्ट्रीक्स, और एक दैनिक मिश्रित सत्र जो छूटी हुई सामग्री को वापस लाता है।

Bridge Trainer शुरुआती लोगों के लिए स्टैंडर्ड अमेरिकन फ्रेमवर्क का उपयोग करता है। पार्टनरशिप समझौते अलग हो सकते हैं, इसलिए अपने पार्टनर के साथ कन्वेंशन की पुष्टि करें।

सदस्यता
Bridge+ स्वचालित रूप से नवीनीकृत होने वाली सदस्यता या एकमुश्त खरीद के रूप में उपलब्ध है: मासिक $1.99/माह, वार्षिक $9.99/वर्ष (दोनों में 1 सप्ताह का मुफ्त परीक्षण शामिल है), या लाइफटाइम $29.99 एकमुश्त। भुगतान खरीद की पुष्टि पर आपके Apple ID खाते से लिया जाता है। सदस्यता स्वचालित रूप से नवीनीकृत हो जाती है जब तक कि वर्तमान अवधि के अंत से कम से कम 24 घंटे पहले इसे रद्द न किया जाए। अपने डिवाइस पर खाता सेटिंग्स में किसी भी समय प्रबंधित या रद्द करें। उपयोग की शर्तें (Apple का मानक EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. गोपनीयता नीति: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "bn-BD": {
        "name": "Bridge Trainer: ব্রিজ শিখুন",
        "subtitle": "ব্রিজ বিডিং ও তাস প্র্যাকটিস",
        "keywords": "ব্রিজ,বিডিং,তাস,শেখা,টিউটর,শিক্ষানবিস,পাঠ,ড্রিল,ডিফেন্স,ডিক্লেয়ারার,অনুশীলন,খেলা,পয়েন্ট,স্কোর,মজা",
        "promotional_text": "বিডিং, ডিক্লেয়ারার প্লে এবং ডিফেন্সের জন্য পাঁচ মিনিটের ब्रिज ड्रिल। প্রতিটি তাসের পেছনের কারণ শিখুন।",
        "release_notes": "ব্রিজ ট্রেইনারে স্বাগতম। চারটি ফ্রি রুমে নিয়ম, ওপেনিং বিড, ডিক্লেয়ারার প্লে এবং ডিফেন্স প্র্যাকটিস করুন।",
        "description": """মাত্র পাঁচ মিনিটের সেশনে বাস্তবসম্মত কন্ট্রাক্ট ব্রিজের দক্ষতা অর্জন করুন।

Bridge Trainer নতুন খেলোয়াড়দের জন্য সবচেয়ে প্রয়োজনীয় বিষয়গুলোকে সহজ ও আকর্ষণীয় ড্রিলে রূপান্তর করে। কোনো প্রতিপক্ষ নেই, কোনো টাইমার নেই এবং কোনো চাপ নেই। পয়েন্ট গণনা করুন, একটি ওপেনিং বিড বেছে নিন, খেলার পরিকল্পনা করুন এবং প্রতিটি উত্তরের পেছনের যৌক্তিক ব্যাখ্যাসহ ডিফেন্সের ভালো অভ্যাস গড়ে তুলুন।

চারটি ফ্রি প্র্যাকটিস রুম

তাস রুম (CARD ROOM)
তাসের র্যাংক, ハイ-কার্ড পয়েন্ট (HCP), ট্রিকস, ট্রাম্প, কন্ট্রাক্ট এবং টেবিলে বিভিন্ন খেলোয়াড়ের ভূমিকা জানুন।

বিডিং রুম (AUCTION ROOM)
নতুনদের জন্য স্ট্যান্ডার্ড আমেরিকান ফ্রেমওয়ার্ক প্র্যাকটিস করুন। ১৩টি তাসের হাত বিশ্লেষণ করে পাস, স্যুট ওপেনিং এবং 1NT এর মধ্যে বেছে নিন।

ডিক্লেয়ারার রুম (DECLARER ROOM)
উইনিং ট্রিকস গণনা করুন, ট্রাম্প কার্ড টানুন, লম্বা স্যুট তৈরি করুন, ফিনেস প্র্যাকটিস করুন এবং টেবিলে সঠিক তাস চালুন।

ডিফেন্স রুম (DEFENSE ROOM)
โอপেনিং লিড, সিকোয়েন্স, থার্ড-হ্যান্ড প্লে, স্যুট রিটার্ন এবং পার্টনারশিপের অভ্যাসগুলো আয়ত্ত করুন।

BRIDGE+ (ঐচ্ছিক আপগ্রেড)
ওপরের सबकुछ সবসময় সম্পূর্ণ ফ্রি থাকবে। Bridge+ প্রতিটি রুমে অতিরিক্ত প্র্যাকটিস সেট যুক্ত করে এবং এডভান্সড কনভেনশন, উচ্চতর कार्ड প্লে ও ডুপ্লিকেট স্ট্র্যাটেজিসহ Master Tables আনলক করে।

শেখানোর সহজ ডিজাইন
সোয়াইপযোগ্য কোচিং কার্ড, কুইক কুইজ, বাস্তবসম্মত ১৩ তাসের হাত, কার্ড খেলার সিনারিও, প্র্যাকটিস ধরে রাখার স্ট্রিক এবং ভুল উত্তরগুলো রিভিশন দেওয়ার ডেইলি মিক্স সেশন।

Bridge Trainer নতুনদের জন্য স্ট্যান্ডার্ড আমেরিকান ফ্রেমওয়ার্ক ব্যবহার করে। পার্টনারদের পারস্পরিক চুক্তি ভিন্ন হতে পারে, তাই আপনার পার্টনারের সাথে কনভেনশনগুলো নিশ্চিত করে নিন।

সাবস্ক্রিপশন
Bridge+ অটো-রিনিউয়েবল সাবস্ক্রিপশন বা এককালীন ক্রয়ের মাধ্যমে উপলব্ধ: মাসিক $১.৯৯/মাস, বার্ষিক $৯.৯৯/বছর (উভয় ক্ষেত্রে ১ সপ্তাহের ফ্রি ট্রায়াল অন্তর্ভুক্ত) অথবা লাইফটাইম $২৯.৯৯ এককালীন পরিশোধ। ক্রয়ের নিশ্চিতকরণে আপনার Apple ID অ্যাকাউন্টে মূল্য চার্জ করা হবে। বর্তমান মেয়াদ শেষ হওয়ার কমপক্ষে ২৪ ঘণ্টা আগে বাতিল না করা হলে সাবস্ক্রিপশন স্বয়ংক্রিয়ভাবে রিনিউ হয়ে যাবে। আপনার ডিভাইসের অ্যাকাউন্ট সেটিংস থেকে যেকোনো সময় এটি পরিচালনা বা বাতিল করুন। ব্যবহারের শর্তাবলী (Apple এর স্ট্যান্ডার্ড EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/। গোপনীয়তা নীতি: https://jackwallner.github.io/bridge/privacy-policy।"""
    },
    "gu-IN": {
        "name": "Bridge Trainer: બ્રિજ શીખો",
        "subtitle": "બ્રિજ બિડિંગ અને અભ્યાસ રમત",
        "keywords": "બ્રિજ,બિડિંગ,પત્તા,શીખો,ટ્યુટર,શરૂઆતી,પાઠ,ડ્રિલ,ડિફેન્સ,ડિક્લેરર,અભ્યાસ,રમત,પોઇન્ટ,સ્કોર,મજા,ખેલ",
        "promotional_text": "બિડિંગ, ડિક્લેરર પ્લે અને ડિફેન્સ માટે પાંચ મિનિટની બ્રિજ ડ્રિલ. દરેક પત્તા પાછળનું કારણ શીખો.",
        "release_notes": "બ્રિજ ટ્રેનરમાં આપનું સ્વાગત છે. ચાર ફ્રી રૂમમાં નિયમો, ઓપનિંગ બિડ, ડિક્લેરર પ્લે અને ડિફેન્સની પ્રેક્ટિસ કરો.",
        "description": """પાંચ મિનિટના સત્રમાં કોન્ટ્રેક્ટ બ્રિજની સાચી સમજ વિકસાવો.

Bridge Trainer શરૂઆતી ખેલાડીઓ માટે સૌથી મહત્વપૂર્ણ ભાગોને ઝડપી અને કેન્દ્રિત ડ્રિલ્સમાં ફેરવે છે. કોઈ વિરોધી નથી, કોઈ ટાઈમર નથી અને કોઈ દબાણ નથી. પોઈન્ટ ગણો, ઓપનિંગ બિડ પસંદ કરો, રમતનું આયોજન કરો અને દરેક જવાબ પાછળના कारणો સાથે ડિફેન્સની આદતો શીખો.

ચાર ફ્રી પ્રેક્ટિસ રૂમ

પત્તા રૂમ (CARD ROOM)
પત્તા રેન્કિંગ, હાઈ-કાર્ડ પોઈન્ટ (HCP), ટ્રિક્સ, ટ્રમ્પ, કોન્ટ્રેક્ટ અને ટેબલ પર વિવિધ ભૂમિકાઓ શીખો.

બિડિંગ રૂમ (AUCTION ROOM)
શરૂઆતી ખેલાડીઓ માટે સ્ટાન્ડર્ડ અમેરિકન ફ્રેમવર્કનો અભ્યાસ કરો. 13 પત્તાના હાથ વાંચો અને પાસ, સ્યુટ ઓપનિંગ અથવા 1NT માંથી પસંદ કરો.

ડિક્લેરર રૂમ (DECLARER ROOM)
જીતનાર પત્તા ગણો, ટ્રમ્પ ખેંચો, લાંબા સ્યુટ સ્થાપિત કરો, ફિનેસ કરો અને રમતમાં સાચું પત્તું પસંદ કરો.

ડિફેન્સ રૂમ (DEFENSE ROOM)
ઓપનિંગ લીડ્સ, સિક્વન્સ, થર્ડ-હેન્ડ પ્લે, સ્યુટ રિટર્ન અને પાર્ટનરશીપની આદતોની પ્રેક્ટિસ કરો.

BRIDGE+ (વૈકલ્પિક અપગ્રેડ)
ઉપરની તમામ બાબતો હંમેશા ફ્રી રહેશે. Bridge+ દરેક રૂમમાં વધારાના પ્રેક્ટિસ સેટ ઉમેરે છે અને એડવાન્સ કન્વેન્શન, કાર્ડ પ્લે અને ડુપ્લિકેટ વ્યૂહરચનાઓ સાથે Master Tables અનલોક કરે છે.

શીખવા માટે બનાવેલ
સ્વાઇપ કરી શકાય તેવા કોચિંગ કાર્ડ્સ, ક્વિક ક્વિઝ, વાસ્તવિક 13-પત્તાના હાથ, કાર્ડ-પ્લે દૃશ્યો, સ્ટ્રીક્સ અને દૈનિક મિશ્રિત સત્ર જે ભૂલી ગયેલી બાબતોને પુનરાવર્તિત કરે છે.

Bridge Trainer શરૂઆતી ખેલાડીઓ માટે સ્ટાન્ડર્ડ અમેરિકન ફ્રેમવર્કનો ઉપયોગ કરે છે. પાર્ટનરશીપના કરારો અલગ હોઈ શકે છે, તેથી તમારા પાર્ટનર સાથે કન્વેન્શનની પુષ્ટિ કરો.

સબ્સ્ક્રિપ્શન્સ
Bridge+ સ્વયં-નવીકરણ સબ્સ્ક્રિપ્શન અથવા એકવારની ખરીદી તરીકે ઉપલબ્ધ છે: માસિક $1.99/મહિને, વાર્ષિક $9.99/વર્ષ (બંનેમાં 1 સપ્તાહની મફત ટ્રાયલ શામેล છે) અથવા લાઇફટાઇમ $29.99 એકવારની ચુકવણી. ખરીદીની પુષ્ટિ પર તમારા Apple ID એકાઉન્ટમાંથી ચુકવણી લેવામાં આવશે. સબ્સ્ક્રિપ્શન્સ આપમેળે નવીકરણ થાય છે સિવાય કે વર્તમાન સમયગાળાના અંતના ઓછામાં ઓછા 24 કલાક પહેલાં તેને રદ કરવામાં ન આવે. તમારા ઉપકરણ પર એકાઉન્ટ સેટિંગ્સમાં કોઈપણ સમયે સંચાલિત અથવા રદ કરો. ઉપયોગની શરતો (Apple નું પ્રમાણભૂત EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. ગોપનીયતા નીતિ: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "kn-IN": {
        "name": "Bridge: ಬ್ರಿಡ್ಜ್ ಕಲಿಯಿರಿ",
        "subtitle": "ಬ್ರಿಡ್ಜ್ ಬಿಡ್ಡಿಂಗ್ ಅಭ್ಯಾಸ",
        "keywords": "ಬ್ರಿಡ್ಜ್,ಬಿಡ್ಡಿಂಗ್,ಎಲೆಗಳು,ಕಲಿಯಿರಿ,ಬೋಧಕ,ಆರಂಭಿಕ,ಪಾಠ,ಅಭ್ಯಾಸ,ರಕ್ಷಣೆ,ಘೋಷಕ,ತರಬೇತಿ,ಆಟ,ಅಂಕಗಳು,ಸ್ಕೋರ್,ಖೇಲ್",
        "promotional_text": "ಬಿಡ್ಡಿಂಗ್, ಡಿಕ್ಲೇರರ್ ಪ್ಲೇ ಮತ್ತು ಡಿಫೆನ್ಸ್ ಕಲಿಯಲು ಐದು ನಿಮಿಷಗಳ ಬ್ರಿಡ್ಜ್ ಡ್ರಿಲ್. ಪ್ರತಿ ನಡೆಯ ಹಿಂದಿನ ಕಾರಣ ತಿಳಿಯಿರಿ.",
        "release_notes": "ಬ್ರಿಡ್ಜ್ ಟ್ರೈನರ್‌ಗೆ ಸುಸ್ವಾಗತ. ನಾಲ್ಕು ಉಚಿತ ರೂಮ್‌ಗಳಲ್ಲಿ ನಿಯಮಗಳು, ಓಪನಿಂಗ್ ಬಿಡ್, ಪ್ಲೇ ಮತ್ತು ಡಿಫೆನ್ಸ್ ಅಭ್ಯಾಸ ಮಾಡಿ.",
        "description": """ಐದು ನಿಮಿಷಗಳ ಸೆಷನ್‌ಗಳಲ್ಲಿ ನೈಜ ಕಾಂಟ್ರಾಕ್ಟ್ ಬ್ರಿಡ್ಜ್ ಕೌಶಲ್ಯಗಳನ್ನು ಬೆಳೆಸಿಕೊಳ್ಳಿ.

Bridge Trainer ಆರಂಭಿಕರಿಗಾಗಿ ಅತ್ಯಂತ ಅಗತ್ಯವಿರುವ ಭಾಗಗಳನ್ನು ತ್ವರಿತ, ಕೇಂದ್ರೀಕೃತ ಅಭ್ಯಾಸಗಳಾಗಿ ಪರಿವರ್ತಿಸುತ್ತದೆ. ಯಾವುದೇ ಎದುರಾಳಿಗಳಿಲ್ಲ, ಟೈಮರ್‌ಗಳಿಲ್ಲ ಮತ್ತು ಯಾವುದೇ ಒತ್ತಡವಿಲ್ಲ. ಪಾಯಿಂಟ್‌ಗಳನ್ನು ಎಣಿಸಿ, ಓಪನಿಂಗ್ ಬಿಡ್ ಆಯ್ಕೆಮಾಡಿ, ಆಟವನ್ನು ಯೋಜಿಸಿ ಮತ್ತು ಪ್ರತಿ ಉತ್ತರದ ಹಿಂದಿನ ವಿವರಣೆಯೊಂದಿಗೆ ಡಿಫೆನ್ಸ್ ರೂಢಿಸಿಕೊಳ್ಳಿ.

ನಾಲ್ಕು ಉಚಿತ ಅಭ್ಯಾಸ ರೂಮ್‌ಗಳು

ಕಾರ್ಡ್ ರೂಮ್ (CARD ROOM)
ಕಾರ್ಡ್ ಶ್ರೇಣಿಗಳು, ಹೈ-ಕಾರ್ಡ್ ಪಾಯಿಂಟ್‌ಗಳು (HCP), ಟ್ರಿಕ್ಸ್‌ಗಳು, ಟ್ರಂಪ್, ಕಾಂಟ್ರಾಕ್ಟ್‌ಗಳು ಮತ್ತು ಟೇಬಲ್‌ನಲ್ಲಿನ ಪಾತ್ರಗಳನ್ನು ತಿಳಿಯಿರಿ.

ಬಿಡ್ಡಿಂಗ್ ರೂಮ್ (AUCTION ROOM)
ಆರಂಭಿಕರಿಗಾಗಿ ಸ್ಟ್ಯಾಂಡರ್ಡ್ ಅಮೆರಿಕನ್ ಫ್ರೇಮ್‌ವರ್ಕ್ ಅಭ್ಯಾಸ ಮಾಡಿ. 13 ಕಾರ್ಡ್‌ಗಳ ಕೈಗಳನ್ನು ಓದಿ ಮತ್ತು ಪಾಸ್, ಸೂಟ್ ಓಪನಿಂಗ್ ಅಥವಾ 1NT ನಡುವೆ ಆಯ್ಕೆಮಾಡಿ.

ಡಿಕ್ಲೇರರ್ ರೂಮ್ (DECLARER ROOM)
ಗೆಲ್ಲುವ ಟ್ರಿಕ್ಸ್‌ಗಳನ್ನು ಎಣಿಸಿ, ಟ್ರಂಪ್ ಎಲೆಗಳನ್ನು ಎಳೆಯಿರಿ, ಲಾಂಗ್ ಸೂಟ್‌ಗಳನ್ನು ಸ್ಥಾಪಿಸಿ, ಫಿನೆಸ್ ಮಾಡಿ ಮತ್ತು ಆಟದ ಸನ್ನಿವೇಶದಲ್ಲಿ ಸರಿಯಾದ ಕಾರ್ಡ್ ಆಯ್ಕೆಮಾಡಿ.

ಡಿಫೆನ್ಸ್ ರೂಮ್ (DEFENSE ROOM)
ಓಪನಿಂಗ್ ಲೀಡ್ಸ್, ಸೀಕ್ವೆನ್ಸ್‌ಗಳು, ಥರ್ด์-ಹ್ಯಾಂಡ್ ಪ್ಲೇ, ಸೂಟ್ ರಿಟರ್ನ್‌ಗಳು ಮತ್ತು ಪಾರ್ಟ್‌ನರ್‌ಶಿಪ್ ರೂಢಿಗಳನ್ನು ತರಬೇತಿ ಮಾಡಿ.

BRIDGE+ (ಐಚ್ಛಿಕ ಅಪ್‌ಗ್ರೇಡ್)
ಮೇಲಿನ ಎಲ್ಲವೂ ಯಾವಾಗಲೂ ಉಚಿತವಾಗಿರುತ್ತದೆ. Bridge+ ಪ್ರತಿ ರೂಮ್‌ನಲ್ಲಿ ಹೆಚ್ಚುವರಿ ಅಭ್ಯಾಸ ಸೆಟ್‌ಗಳನ್ನು ಸೇರಿಸುತ್ತದೆ ಮತ್ತು ಮುಂದುವರಿದ ಕನ್ವೆನ್ಷನ್‌ಗಳು, ಕಾರ್ಡ್ ಪ್ಲೇ ಮತ್ತು ಡ್ಯುಪ್ಲಿಕೇಟ್ ತಂತ್ರಗಳೊಂದಿಗೆ Master Tables ಅನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡುತ್ತದೆ.

ಕಲಿಕೆಗಾಗಿ ವಿನ್ಯಾಸಗೊಳಿಸಲಾಗಿದೆ
ಸ್ವೈಪ್ ಮಾಡಬಹುದಾದ ತರಬೇತಿ ಕಾರ್ಡ್‌ಗಳು, ತ್ವರಿತ ರಸಪ್ರಶ್ನೆಗಳು, ನೈಜ 13-ಕಾರ್ಡ್ ಕೈಗಳು, ಪ್ಲೇ ಸನ್ನಿವೇಶಗಳು, ಅಭ್ಯಾಸದ ಸ್ಟ್ರೀಕ್ಸ್ ಮತ್ತು ತಪ್ಪುಗಳನ್ನು ಪುನರಾವರ್ತಿಸುವ ದೈನಂದิน ಮಿಶ್ರಿತ ಸೆಷನ್.

Bridge Trainer ಆರಂಭಿಕರಿಗಾಗಿ ಸ್ಟ್ಯಾಂಡರ್ಡ್ ಅಮೆರಿಕನ್ ಫ್ರೇಮ್‌ವರ್ಕ್ ಬಳಸುತ್ತದೆ. ಪಾರ್ಟ್‌ನರ್‌ಶಿಪ್ ಒಪ್ಪಂದಗಳು ಬದಲಾಗಬಹುದು, ಆದ್ದರಿಂದ ನಿಮ್ಮ ಪಾರ್ಟ್‌ನರ್‌ನೊಂದಿಗೆ ಕನ್ವೆನ್ಷನ್‌ಗಳನ್ನು ದೃಢೀಕರಿಸಿ.

ಚಂದಾದಾರಿಕೆಗಳು
Bridge+ ಸ್ವಯಂಚಾಲಿತ ನವೀಕರಣ ಚಂದಾದಾರಿಕೆ ಅಥವಾ ಒಂದು ಬಾರಿಯ ಖರೀದಿಯ ಮೂಲಕ ಲಭ್ಯವಿದೆ: ಮಾಸಿಕ $1.99/ತಿಂಗಳು, ವಾರ್ಷಿಕ $9.99/ವರ್ಷ (ಎರಡೂ 1 ವಾರದ ಉಚಿತ ಪ್ರಯೋಗವನ್ನು ಒಳಗೊಂಡಿವೆ) ಅಥವಾ ಜೀವಿತಾವಧಿಯ $29.99 ಒಂದು ಬಾರಿಯ ಪಾವತಿ. ಖರೀದಿಯ ದೃಢೀಕರಣದ ನಂತರ ನಿಮ್ಮ Apple ID ಖಾತೆಗೆ ಶುಲ್ಕ ವಿಧಿಸಲಾಗುತ್ತದೆ. ಪ್ರಸ್ತುत ಅವಧಿ ಮುಗಿಯುವ ಕನಿಷ್ಠ 24 ಗಂಟೆಗಳ ಮೊದಲು ರದ್ದುಗೊಳಿಸದ ಹೊರತು ಚಂದಾದಾರಿಕೆಗಳು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ನವೀಕರಿಸಲ್ಪಡುತ್ತವೆ. ನಿಮ್ಮ ಸಾಧನದಲ್ಲಿನ ಖಾತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಯಾವುದೇ ಸಮಯದಲ್ಲಿ ಚಂದಾದಾರಿಕೆಯನ್ನು ನಿರ್ವಹಿಸಿ ಅಥವಾ ರದ್ದುಗೊಳಿಸಿ. ಬಳಕೆಯ ನಿಯಮಗಳು (Apple ನ ಗುಣಮಟ್ಟದ EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. ಗೌಪ್ಯತಾ ನೀತಿ: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ml-IN": {
        "name": "ബ്രിഡ്ജ് ട്രെയിനർ: പഠിക്കാം",
        "subtitle": "ബ്രിഡ്ജ് ബിഡ്ഡിംഗ് പരിശീലനം",
        "keywords": "ബ്രിഡ്ജ്,ബിഡ്ഡിംഗ്,കാർഡുകൾ,പഠിക്കാം,ട്യൂട്ടർ,തുടക്കക്കാരൻ,പാഠം,പരിശീലനം,പ്രതിരോധം,കളിക്കാരൻ,സ്കോർ",
        "promotional_text": "ബിഡ്ഡിംഗ്, ഡിക്ലെയറർ പ്ലേ, പ്രതിരോധം എന്നിവ പരിശീലിക്കാൻ അഞ്ച് മിനിറ്റ് ബ്രിഡ്ജ് ഡ്രില്ലുകൾ. ഓരോ കാർഡിനും പിന്നിലെ കാരണം പഠിക്കുക.",
        "release_notes": "ബ്രിഡ്ജ് ട്രെയിനറിലേക്ക് സ്വാഗതം. നാല് സൌജന്യ മുറികളിൽ നിയമങ്ങൾ, ഓപ്പണിംഗ് ബിഡ്ഡുകൾ, പ്ലേ, പ്രതിരോധം എന്നിവ പരിശീലിക്കുക.",
        "description": """അഞ്ച് മിനിറ്റ് സെഷനുകളിലൂടെ യഥാർത്ഥ കോൺട്രാക്ട് ബ്രിഡ്ജ് കഴിവുകൾ വളർത്തിയെടുക്കൂ.

ബ്രിഡ്ജ് ട്രെയിനർ തുടക്കക്കാർക്ക് ഏറ്റവും ആവശ്യമായ ഭാഗങ്ങളെ വേഗതയേറിയതും ലക്ഷ്യബോധമുള്ളതുമായ ഡ്രില്ലുകളാക്കി മാറ്റുന്നു. എതിരാളികളോ ടൈമറുകളോ സമ്മർദ്ദങ്ങളോ ഇല്ല. പോയിന്റുകൾ എണ്ണുക, ഓപ്പണിംഗ് ബിഡ് തിരഞ്ഞെടുക്കുക, കളി ആസൂತ್ರണം ചെയ്യുക, ഓരോ ഉത്തരത്തിനും പിന്നിലെ കൃത്യമായ വിശദീകരണത്തോടെ പ്രതിരോധ ശീലങ്ങൾ പഠിക്കുക.

നാല് സൌജന്യ പരിശീലന മുറികൾ

കാർഡ് റൂം (CARD ROOM)
കാർഡ് റാങ്കുകൾ, ഹൈ-കാർഡ് പോയിന്റുകൾ (HCP), ട്രിക്കുകൾ, ട്രംപ്, കോൺട്രാക്ടുകൾ, ടേബിളിലെ വേഷങ്ങൾ എന്നിവ മനസ്സിലാക്കുക.

ബിഡ്ഡിംഗ് റൂം (AUCTION ROOM)
തുടക്കക്കാർക്കായുള്ള സ്റ്റാൻഡേർഡ് അമേരിക്കൻ ഫ്രെയിംവർക്ക് പരിശീലിക്കുക. 13 കാർഡുകളുള്ള കൈകൾ വായിച്ച് പാസ്, സ്യൂട്ട് ഓപ്പണിംഗ്, 1NT എന്നിവയിലൊന്ന് തിരഞ്ഞെടുക്കുക.

ഡിക്ലെയറർ റൂം (DECLARER ROOM)
വിജയിക്കുന്ന ട്രിക്കുകൾ എണ്ണുക, ട്രംപ് കാർഡുകൾ വലിക്കുക, നീളമുള്ള സ്യൂട്ടുകൾ സ്ഥാപിക്കുക, ഫിനസ് ചെയ്യുക, കളിയുടെ സാഹചര്യത്തിൽ ശരിയായ കാർഡ് തിരഞ്ഞെടുക്കുക.

ഡിഫൻസ് റൂം (DEFENSE ROOM)
ഓപ്പണിംഗ് ലീഡുകൾ, സീക്വൻസുകൾ, തേർഡ് ഹാൻഡ് പ്ലേ, സ്യൂട്ട് റിട്ടേണുകൾ, പാർട്ണർഷിപ്പ് ശീലങ്ങൾ എന്നിവ പരിശീലിക്കുക.

BRIDGE+ (ഓപ്ഷണൽ അപ്ഗ്രേഡ്)
മുകളിൽ പറഞ്ഞവയെല്ലാം എപ്പോഴും പൂർണ്ണമായും സൌജന്യമായിരിക്കും. Bridge+ ഓരോ റൂമിലും അധിക പരിശീലന സെറ്റുകൾ ചേർക്കുകയും വിപുലമായ കൺവെൻഷനുകൾ, കാർഡ് പ്ലേ, ഡ്യൂപ്ലിക്കേറ്റ് തന്ത്രങ്ങൾ എന്നിവയോടെ Master Tables അൺലോക്ക് ചെയ്യുകയും ചെയ്യുന്നു.

പഠനത്തിനായി രൂപകൽപ്പന ചെയ്തത്
സ്വൈപ്പ് ചെയ്യാവുന്ന കോച്ചിംഗ് കാർഡുകൾ, ദ്രുത ക്വിസുകൾ, റിയലിസ്റ്റിക് 13-കാർഡ് കൈകൾ, പ്ലേ സാഹചര്യങ്ങൾ, പരിശീലന സ്ട്രീക്കുകൾ, തെറ്റുകൾ ആവർത്തിച്ചു പഠിക്കാനുള്ള ഡെയ്ലി മിക്സ് സെഷൻ.

ബ്രിഡ്ജ് ട്രെയിനർ തുടക്കക്കാർക്കായുള്ള സ്റ്റാൻഡേർഡ് അമേരിക്കൻ ഫ്രെയിംവർക്ക് ഉപയോഗിക്കുന്നു. പങ്കാളിത്ത കരാറുകൾ വ്യത്യാസപ്പെടാം, അതിനാൽ നിങ്ങളുടെ പങ്കാളിയുമായി കൺവെൻഷനുകൾ സ്ഥിരീകരിക്കുക.

സബ്സ്ക്രിപ്ഷനുകൾ
Bridge+ സ്വയം പുതുക്കാവുന്ന സബ്സ്ക്രിപ്ഷൻ വഴിയോ ഒറ്റത്തവണ വാങ്ങൽ വഴിയോ ലഭ്യമാണ്: പ്രതിമാസം $1.99/മാസം, പ്രതിവർഷം $9.99/വർഷം (രണ്ടും 1 ആഴ്ചത്തെ സൌജന്യ ട്രയൽ ഉൾക്കൊള്ളുന്നു) അല്ലെങ്കിൽ ലൈഫ് ടൈം $29.99 ഒറ്റത്തവണ പണമടയ്ക്കൽ. വാങ്ങൽ സ്ഥിരീകരിക്കുമ്പോൾ നിങ്ങളുടെ Apple ID അക്കൗണ്ടിലേക്ക് പേയ്മെന്റ് ഈടാക്കും. നിലവിലെ കാലയളവ് അവസാനിക്കുന്നതിന് കുറഞ്ഞത് 24 മണിക്കൂർ മുമ്പെങ്കിലും റദ്ദാക്കിയില്ലെങ്കിൽ സബ്സ്ക്രിപ്ഷനുകൾ സ്വയമേവ പുതുക്കപ്പെടും. നിങ്ങളുടെ ഉപകരണത്തിലെ അക്കൗണ്ട് ക്രമീകരണങ്ങളിൽ എപ്പോൾ വേണമെങ്കിലും ഇത് നിയന്ത്രിക്കുകയോ റദ്ദാക്കുകയോ ചെയ്യാം. ഉപയോഗ നിബന്ധനകൾ (ആപ്പിളിന്റെ സ്റ്റാൻഡേർഡ് EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. സ്വകാര്യതാ നയം: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "mr-IN": {
        "name": "Bridge Trainer: ब्रिज शिका",
        "subtitle": "ब्रिज बिडिंग व पत्ते सराव",
        "keywords": "ब्रिज,बिडिंग,पत्ते,शिका,ट्यूटर,नवशिक्या,पाठ,सराव,डिफेन्स,डिक्लेयरर,चाचणी,खेळ,गुण,गुणसंख्या,मजा",
        "promotional_text": "बिडिंग, डिक्लेयरर प्ले आणि डिफेन्ससाठी पाच मिनिटांचे ब्रिज सराव. प्रत्येक पत्त्यामागील कारण शिका.",
        "release_notes": "ब्रिज ट्रेनरमध्ये आपले स्वागत आहे. चार विनामूल्य रूममध्ये नियम, ओपनिंग बिड, डिक्लेयरर प्ले आणि डिफेन्सचा अभ्यास करा.",
        "description": """पाच मिनिटांच्या सत्रात प्रत्यक्ष कॉन्ट्रॅक्ट ब्रिजचे कौशल्य विकसित करा.

Bridge Trainer नवशिक्यांसाठी सर्वात आवश्यक भागांना जलद आणि केंद्रित सरावामध्ये रूपांतरित करतो. कोणताही विरोधक नाही, कोणताही टाइमर नाही आणि कोणताही दबाव नाही. गुण मोजा, ओपनिंग बिड निवडा, खेळाचे नियोजन करा आणि प्रत्येक उत्तरामागील स्पष्टीकरणासह डिफेन्सच्या सवयी शिका.

चार विनामूल्य सराव खोल्या

पत्ते खोली (CARD ROOM)
पत्ते रँकिंग, हाय-कार्ड पॉइंट्स (HCP), ट्रिक्स, ट्रम्प, कॉन्ट्रॅक्ट्स आणि टेबलवरील भूमिका शिका.

बिडिंग खोली (AUCTION ROOM)
नवशिक्यांसाठी स्टँडर्ड अमेरिकन फ्रेमवर्कचा सराव करा. 13 पत्त्यांचे हात वाचा आणि पास, स्युट ओपनिंग किंवा 1NT मधून निवडा.

डिक्लेयरर खोली (DECLARER ROOM)
जिंकणारे ट्रिक्स मोजा, ट्रम्प पत्ते काढा, लांब स्युट स्थापित करा, फिनेस करा आणि खेळात योग्य पत्ता निवडा.

डिफेन्स खोली (DEFENSE ROOM)
ओपनिंग लीड्स, सिक्वेन्स,飾 थर्ड-हँड प्ले, स्युट रिटर्न्स आणि पार्टनरशिपच्या सवयींचा सराव करा.

BRIDGE+ (वैकल्पिक अपग्रेड)
वरील सर्व गोष्टी नेहमी विनामूल्य राहतील. Bridge+ प्रत्येक खोलीत अतिरिक्त सराव संच जोडते आणि प्रगत कन्व्हेंशन्स, कार्ड प्ले आणि डुप्लिकेट धोरणांसह Master Tables अनलॉक करते.

शिकण्यासाठी डिझाइन केलेले
स्वाइप करता येणारे कोचिंग कार्ड्स, जलद प्रश्नमंजुषा, वास्तववादी 13-पत्त्यांचे हात, कार्ड-प्ले परिस्थिती, स्ट्रीक्स आणि चुका पुन्हा शिकवणारे दैनिक मिश्रित सत्र.

Bridge Trainer नवशिक्यांसाठी स्टँडर्ड अमेरिकन फ्रेमवर्क वापरतो. पार्टनरशिपचे करार वेगवेगळे असू शकतात, म्हणून आपल्या पार्टनरसह कन्व्हेंशन्सची खात्री करा.

सबस्क्रिप्शन
Bridge+ स्वयंचलित नूतनीकरण सबस्क्रिप्शन किंवा एकरकमी खरेदी म्हणून उपलब्ध आहे: मासिक $1.99/महिना, वार्षिक $9.99/वर्ष (दोन्हीमध्ये 1 आठवड्याची विनामूल्य चाचणी समाविष्ट आहे) किंवा लाइफटाईम $29.99 एकरकमी पेमेंट. खरेदीच्या पुष्टीकरणावर तुमच्या Apple ID खात्यावरून शुल्क आकारले जाईल. वर्तमान कालावधी संपण्याच्या किमान 24 तास आधी रद्द केल्याशिवाय सबस्क्रिप्शन स्वयंचलितपणे नूतनीकरण होते. आपल्या डिव्हाइसवरील खाते सेटिंग्जमध्ये कधीही व्यवस्थाजित किंवा रद्द करा. वापरण्याच्या अटी (Apple चे मानक EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. गोपनीयता धोरण: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "or-IN": {
        "name": "Bridge Trainer: ବ୍ରିଜ୍ ଶିଖନ୍ତୁ",
        "subtitle": "ବ୍ରିଜ୍ ବିଡିଂ ଏବଂ ତାସ ଅଭ୍ୟାସ",
        "keywords": "ବ୍ରିଜ୍,ବିଡିଂ,ତାସ,ଶିଖନ୍ତୁ,ଟ୍ୟୁଟର,ଶିକ୍ଷାନବିସ,ପାଠ,ଡ୍ରିଲ୍,ଡିଫେନ୍ସ,ଡିକ୍ଲେୟରର,କ୍ଵିଜ୍,ଖେଳ,ସ୍କୋର,ରୁମ୍,ମଜା",
        "promotional_text": "ବିଡିଂ, ଡିକ୍ଲେୟରର୍ ପ୍ଲେ ଏବଂ ଡିଫେନ୍ସ ପାଇଁ ପାଞ୍ચ ମିନିଟର ବ୍ରିଜ୍ ଡ୍ରିଲ୍। ପ୍ରତି ଚାଲ୍ ପଛର କାରଣ ଶିଖନ୍ତୁ।",
        "release_notes": "ବ୍ରିଜ୍ ଟ୍ରେନରକୁ ସ୍ଵାଗତ। ଚାରୋଟି ମାଗଣା ରୁମରେ ନିୟମ, ଓପନିଂ ବିଡ୍, ଡିକ୍ଲେୟರର୍ ପ୍ଲେ ଏବଂ ଡିଫେନ୍ସ ଅଭ୍ୟାସ କରନ୍ତୁ।",
        "description": """ପାଞ୍ଚ ମିନିଟର ସେସନରେ ପ୍ରକୃତ କଣ୍ଟ୍ରାକ୍ଟ ବ୍ରିଜ୍‌ର ଦକ୍ଷତା ହାସଲ କରନ୍ତୁ।

Bridge Trainer ନୂତନ ଖେଳାଳିମାନଙ୍କ ପାଇଁ ସବୁଠାରୁ ଆବଶ୍ୟକୀୟ ବିଷୟଗୁଡ଼ିକୁ ଶୀଘ୍ର ଏବଂ କେନ୍ଦ୍ରୀଭୂତ ଅଭ୍ୟାସରେ ପରିଣତ କରେ। କୌଣସି ପ୍ରତିପକ୍ଷ ନାହାନ୍ତି, କୌଣସି ଟାଇମର୍ ନାହିଁ ଏବଂ କୌଣସି ଚାପ ନାହିଁ। ପଏଣ୍ଟ ଗଣନା କରନ୍ତୁ, ଓପନିଂ ବିଡ୍ ବାଛନ୍ତୁ, ଖେଳ ଯୋଜନା କରନ୍ତୁ ଏବଂ ପ୍ରତ୍ୟେକ ଉତ୍ତର ପଛରେ ଥିବା ସଠିକ୍ ବ୍ୟାଖ୍ୟା ସହିତ ଡିଫେନ୍ସର ଭଲ ଅଭ୍ୟାସ ଗଢ଼ନ୍ତୁ।

ଚାରୋଟି ମାଗଣା ପ୍ରାକ୍ଟିସ୍ ରୁମ୍

କାର୍ଡ ରୁମ୍ (CARD ROOM)
କାର୍ଡ ର଼୍ୟାଙ୍କ, ହାଇ-କାର୍ଡ ପଏଣ୍ଟ (HCP), ଟ୍ରିକ୍ସ, ଟ୍ରମ୍ପ, କଣ୍ଟ୍ରାକ୍ଟ ଏବଂ ଟେବୁଲରେ ବିଭିନ୍ନ ଭୂମିକା ଶିଖନ୍ତୁ।

ବିଡିଂ ରୁମ୍ (AUCTION ROOM)
ନୂତନ ଖେଳାଳିଙ୍କ ପାଇଁ ଷ୍ଟାଣ୍ଡାର୍ଡ ଆମେରିକାନ୍ ଫ୍ରେମୱର୍କ ଅଭ୍ୟାସ କରନ୍ତୁ। ୧୩ଟି କାର୍ଡର ହାତ ପଢ଼ନ୍ତୁ ଏବଂ ପାସ୍, ସୁଟ୍ ଓପନିଂ କିମ୍ବା 1NT ମଧ୍ୟରୁ ବାଛନ୍ତୁ।

ଡିକ୍ଲେୟରର୍ ରୁମ୍ (DECLARER ROOM)
ଜିତିବାକୁ ଥିବା ଟ୍ରିକ୍ସ ଗଣନା କରନ୍ତୁ, ଟ୍ରମ୍ପ ଟାଣନ୍ତୁ, ଲମ୍ବା ସୁଟ୍ ପ୍ରତିଷ୍ଠା କରନ୍ତୁ, ଫିନେସ୍ କରନ୍ତୁ ଏବଂ ଖେଳ ପରିସ୍ଥିତିରେ ସଠିକ୍ କାର୍ଡ ବାଛନ୍ତୁ।

ଡିଫେନ୍ସ ରୁମ୍ (DEFENSE ROOM)
ଓପନିଂ ଲିଡ୍, ସିକ୍ଵେନ୍ସ, ଥର୍ଡ-ହାଣ୍ଡ ପ୍ლე, ସୁଟ୍ ରିଟର୍ଣ୍ଣ ଏବଂ ପାର୍տନರସିପ୍ ଅଭ୍ୟାସ ଗୁଡ଼ିକର ଟ୍ରେନିଂ ନିଅନ୍ତୁ।

BRIDGE+ (ବୈକଳ୍ପିକ ଅପଗ୍ରେଡ୍)
ଉପରୋକ୍ତ ସମସ୍ତ ବିଷୟ ସର୍ବଦା ମାଗଣା ରହିବ। Bridge+ ପ୍ରତ୍ୟେକ ରୁମ୍‌ରେ ଅତିରିକ୍ତ ଅଭ୍ୟାସ ସେଟ୍ ଯୋଡିଥାଏ ଏବଂ ଉନ୍ନତ କନଭେନସନ୍, କାର୍ଡ ପ୍લે ଏବଂ ଡୁପ୍ଲିକେଟ୍ କୌଶଳ ସହିତ Master Tables ଅନଲକ୍ କରିଥାଏ।

ଶିଖିବା ପାଇଁ ପ୍ରସ୍ତուତ
ସ୍ଵାଇପ୍ ଯୋਗ୍ୟ କୋଚିଂ କାର୍ଡ, କ୍ଵିକ୍ କ୍ଵିଜ୍, ବାସ୍ତବବାଦୀ ୧୩-କାର୍ଡ ହାତ, କାର୍ଡ ଖେଳର ପରିସ୍ଥିତି, ପ୍ରାକ୍ଟିସ୍ ଷ୍ଟ୍ରିକ୍ସ ଏବଂ ଭୁଲଗୁଡ଼ିକୁ ସଂଶୋଧନ କରୁଥିବା ଦୈନିକ ମิଶ୍ରିତ ସେସନ।

Bridge Trainer ନୂତନ ଖେଳାଳିଙ୍କ ପାଇଁ ଷ୍ଟାଣ୍ଡାର୍ଡ ଆମେରିକାନ୍ ଫ୍ରେମୱର୍କ ବ୍ୟવହାର କରେ। ପାର୍ଟନରସିପ୍ ଚୁକ୍ତିନାମା ଭིନ୍ନ ହୋଇପାରେ, ତେଣୁ ଆପଣଙ୍କ ପାର୍ଟନରଙ୍କ ସହ କନଭେନସନ୍ ନିଶ୍ચિત କରନ୍ତୁ।

ସବସ୍କ୍ରିପସନ
Bridge+ ଅଟୋ-ରିନ୍ୟուଏବଲ୍ ସବସ୍କ୍ରიପସନ୍ କିମ୍ବା ଏକକาଳୀନ କ୍ରୟ ମାଧ୍ୟମରେ ଉପଲବ୍ଧ: ମାସିକ $1.99/ମାସ, ବାର୍ଷିକ $9.99/ବର୍ଷ (ଉଭୟରେ 1 ସପ୍ତାହର ମାଗଣା ଟ୍ରାଏଲ୍ ଅନ୍ତର୍ଭୁକ୍ତ) କିମ୍ବା ଲାଇଫଟାଇମ $29.99 ଏକକାଳୀନ ପେମେଣ୍ଟ। କ୍ରୟ ନିଶ୍ଚିତ ହେବା ପରେ ଆପଣଙ୍କ Apple ID ଆକାଉଣ୍ଟରୁ ଶୁଳ୍କ କଟାଯିବ। ବର୍ତ୍ତମାନର ଅବଧି ଶେଷ ହେବାର ଅତିକମରେ ୨୪ ଘଣ୍ଟା ପୂର୍ବରୁ ବାତିଲ ନକଲେ ସବସ୍କ୍ରିପସନ ସ୍ଵୟଂକ୍ରିୟ ଭାବେ ରିନ୍ୟու ହୋଇଯିବ। ଆପଣଙ୍କ ଡିଭାଇସରେ ଥିବା ଆକାଉଣ୍ଟ ସେଟିଂସରୁ ଯେକୌଣସି ସମୟରେ ଏହାକୁ ପରିଚାଳନା କିମ୍ବା ବାତିଲ କରନ୍ତୁ। ବ୍ୟવହାରର ସର୍ତ୍ତାବଳୀ (Apple ର ମାନକ EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/। ଗୋପନୀୟତା ନୀତି: https://jackwallner.github.io/bridge/privacy-policy।"""
    },
    "pa-IN": {
        "name": "Bridge Trainer: ਬ੍ਰਿਜ ਸਿੱਖੋ",
        "subtitle": "ਬ੍ਰਿਜ ਬੋਲੀ ਅਤੇ ਕਾਰਡ ਅਭਿਆਸ",
        "keywords": "ਬ੍ਰਿਜ,ਬੋਲੀ,ਪੱਤੇ,ਸਿੱਖੋ,ਟਿਊਟਰ,ਸ਼ੁਰੂਆਤੀ,ਪਾਠ,ਡ੍ਰਿਲ,ਡਿਫੈਂਸ,ਡਿਕਲੇਅਰਰ,ਅਭਿਆਸ,ਖੇਡ,ਸਕੋਰ,ਪੁਆਇੰਟ,ਮਜ਼ੇਦਾਰ,ਖੇਲ",
        "promotional_text": "ਬੋਲੀ (ਬਿਡਿੰਗ), ਡਿਕਲਏਰਰ ਪਲੇ, ਅਤੇ ਡਿਫੈਂਸ ਲਈ ਪੰਜ ਮਿੰਟ ਦੀ ਬ੍ਰਿਜ ਡ੍ਰਿਲ। ਹਰ ਚਾਲ ਦਾ ਕਾਰਨ ਸਿੱਖੋ।",
        "release_notes": "ਬ੍ਰਿਜ ਟ੍ਰੇਨਰ ਵਿੱਚ ਤੁਹਾਡਾ ਸਵਾਗਤ ਹੈ। ਚਾਰ ਮੁਫ਼ਤ ਕਮਰਿਆਂ ਵਿੱਚ ਨਿਯਮਾਂ, ਬੋਲੀ, ਪਲੇ ਅਤੇ ਡਿਫੈਂਸ ਦਾ ਅਭਿਆਸ ਕਰੋ।",
        "description": """ਪੰਜ ਮਿੰਟ ਦੇ ਸੈਸ਼ਨਾਂ ਵਿੱਚ ਅਸਲ ਕੰਟਰੈਕਟ ਬ੍ਰਿਜ ਦੀ ਸਮਝ ਵਿਕਸਿਤ ਕਰੋ।

Bridge Trainer ਸ਼ੁਰੂਆਤੀ ਖਿਡਾਰੀਆਂ ਲਈ ਸਭ ਤੋਂ ਮਹੱਤਵਪੂਰਨ ਹਿੱਸਿਆਂ ਨੂੰ ਤੇਜ਼ ਅਤੇ ਕੇਂਦਰਿਤ ਡ੍ਰਿਲਸ ਵਿੱਚ ਬਦਲਦਾ ਹੈ। ਕੋਈ ਵਿਰੋਧੀ ਨਹੀਂ, ਕੋਈ ਟਾਈมਰ ਨਹੀਂ ਅਤੇ ਕੋਈ ਦਬਾਅ ਨਹੀਂ। ਪੁਆਇੰਟ ਗਿਣੋ, ਓਪਨਿੰਗ ਬਿਡ ਚੁਣੋ, ਖੇਡ ਦੀ ਯੋਜਨਾ ਬਣਾਓ, ਅਤੇ ਹਰ ਉੱਤਰ ਦੇ ਪਿੱਛੇ ਦੇ ਕਾਰਨਾਂ ਦੇ ਨਾਲ ਡਿਫੈਂਸ ਦੀਆਂ ਆਦਤਾਂ ਸਿੱਖੋ।

ਚਾਰ ਮੁਫ਼ਤ ਅਭਿਆਸ ਕਮਰੇ

ਕਾਰਡ ਰੂਮ (CARD ROOM)
ਕਾਰਡ ਰੈਂਕਿੰਗ, ਹਾਈ-ਕਾਰਡ ਪੁਆਇੰਟ (HCP), ਟ੍ਰਿਕਸ, ਟ੍ਰੰਪ, ਕੰਟਰੈਕਟ ਅਤੇ ਟੇਬਲ 'ਤੇ ਵੱਖ-ਵੱਖ ਭੂਮਿਕਾਵਾਂ ਸਿੱਖੋ।

ਬੋਲੀ ਰੂਮ (AUCTION ROOM)
ਸ਼ੁਰੂਆਤੀ ਖਿਡਾਰੀਆਂ ਲਈ ਸਟੈਂਡਰਡ ਅਮੈਰੀਕਨ ਫ੍ਰੇਮਵਰਕ ਦਾ ਅਭਿਆਸ ਕਰੋ। 13 ਪੱਤਿਆਂ ਦੇ ਹੱਥ ਪੜ੍ਹੋ ਅਤੇ ਪਾਸ, ਸੂਟ ਓਪਨિંગ ਜਾਂ 1NT ਵਿੱਚੋਂ ਚੁਣੋ।

ਡਿਕਲਏਰਰ ਰੂਮ (DECLARER ROOM)
ਜਿੱਤਣ ਵਾਲੇ ਟ੍ਰਿਕਸ ਗਿਣੋ, ਟ੍ਰੰਪ ਖਿੱਚੋ, ਲੰਬੇ ਸੂਟ ਸਥਾਪਿਤ ਕਰੋ, ਫਿਨੇស ਕਰੋ ਅਤੇ ਖੇਡ ਵਿੱਚ ਸਹੀ ਪੱਤਾ ਚੁਣੋ।

ਡਿਫੈਂਸ ਰੂਮ (DEFENSE ROOM)
ਓਪਨિંગ ਲੀਡਸ, ਸਿਕਵੈਂս, ਥਰਡ-ਹੈਂਡ ਪਲੇ, ਸੂਟ ਰਿਟਰਨ ਅਤੇ ਪਾਰਟਨਰਸ਼ਿਪ ਦੀਆਂ ਆਦਤਾਂ ਦਾ ਅਭਿਆਸ ਕਰੋ।

BRIDGE+ (ਵੈਕਲਪਿਕ ਅੱਪਗ੍ਰੇਡ)
ਉੱਪਰ ਦਿੱਤੀਆਂ ਸਾਰੀਆਂ ਚੀਜ਼ਾਂ ਹਮੇଶਾ ਮੁਫ਼ਤ ਰਹਿਣਗੀਆਂ। Bridge+ ਹਰ ਰੂਮ ਵਿੱਚ ਵਾਧੂ ਅਭਿਆਸ ਸੈੱਟ ਜੋੜਦਾ ਹੈ ਅਤੇ ਉੱਨਤ ਕਨਵੈนਸ਼ਨਾਂ, ਕਾਰਡ ਪਲੇ ਅਤੇ ਡੁਪਲੀਕੇਟ ਰਣਨੀਤੀਆਂ ਦੇ ਨਾਲ Master Tables ਅਨਲੌਕ ਕਰਦਾ है।

ਸਿੱਖਣ ਲਈ ਬਣਾਇਆ ਗਿਆ
ਸਵਾਈਪ ਕਰਨ ਯੋਗ ਕੋਚਿੰਗ ਕਾਰਡ, ਤੁਰੰਤ ਕੁਇਜ਼, ਯਥਾਰਥਵਾਦੀ 13-ਪੱਤਿਆਂ ਦੇ ਹੱਥ, ਕਾਰਡ-ਪਲੇ ਦ੍ਰਿश, ਸਟ੍ਰੀਕਸ ਅਤੇ ਰੋਜ਼ਾਨਾ ਮਿਸ਼ਰਤ ਸੈਸ਼ਨ ਜੋ ਭੁੱਲੀਆਂ ਹੋਈਆਂ ਚੀਜ਼ਾਂ ਨੂੰ ਦੁਹਰਾਉਂਦਾ ਹੈ।

Bridge Trainer ਸ਼ੁਰੂਆਤੀ ਖਿਡਾਰੀਆਂ ਲਈ ਸਟੈਂਡਰਡ ਅਮੈਰੀਕਨ ਫ੍ਰੇਮਵਰਕ ਦੀ ਵਰਤੋਂ ਕਰਦਾ ਹੈ। ਪਾਰਟਨਰਸ਼ਿਪ ਦੇ ਸਮਝੌਤੇ ਵੱਖਰੇ ਹੋ ਸਕਦੇ ਹਨ, ਇਸ ਲਈ ਆਪਣੇ ਪਾਰਟਨਰ ਨਾਲ ਕਨਵੈਨਸ਼ਨਾਂ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ।

ਸਬਸਕ੍ਰਿਪਸ਼ਨ
Bridge+ ਸਵੈ-ਨਵੀਕਰਨ ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਜਾਂ ਇੱਕ ਵਾਰ ਦੀ ਖਰੀਦ ਵਜੋਂ ਉਪਲਬਧ ਹੈ: ਮਹੀਨਾਵਾਰ $1.99/ਮਹੀਨਾ, ਸਾਲਾਨਾ $9.99/ਸਾਲ (ਦੋਵਾਂ ਵਿੱਚ 1 ਹਫ਼ਤੇ ਦੀ ਮੁਫ਼ਤ ਅਜ਼ਮਾਇਸ਼ ਸ਼ਾਮਲ ਹੈ) ਜਾਂ ਲਾਈਫਟਾਈม $29.99 ਇੱਕ ਵਾਰ ਦੀ ਅਦਾਇਗੀ। ਖਰੀਦ ਦੀ ਪੁਸ਼ਟੀ ਹੋਣ 'ਤੇ ਤੁਹਾਡੇ Apple ID ਖਾਤੇ ਤੋਂ ਭੁਗਤਾਨ ਲਿਆ ਜਾਵੇਗਾ। ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਆਪਣੇ ਆਪ ਰੀਨਿਊ ਹੋ ਜਾਂਦੀ ਹੈ ਜਦੋਂ ਤੱਕ ਮੌਜੂਦਾ ਮਿਆਦ ਦੇ ਖ਼ਤਮ ਹੋਣ ਤੋਂ ਘੱटੋ-ਘੱਟ 24 ਘੰਟੇ ਪਹਿਲਾਂ ਇਸਨੂੰ ਰੱਦ ਨਹੀਂ ਕੀਤਾ ਜਾਂਦਾ। ਆਪਣੇ ਡਿਵਾਈਸ 'ਤੇ ਖਾਤਾ ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਕਿਸੇ ਵੀ ਸਮੇਂ ਪ੍ਰਬੰਧਿਤ ਜਾਂ ਰੱਦ ਕਰੋ। ਵਰਤੋਂ ਦੀਆਂ ਸ਼ਰਤਾਂ (Apple ਦਾ ਮਿਆਰੀ EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. ਪਰਦੇਦารੀ ਨੀਤੀ: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ta-IN": {
        "name": "Bridge Trainer: பிரிட்ஜ் கற்க",
        "subtitle": "பிரிட்ஜ் ஏலம் & அட்டை பயிற்சி",
        "keywords": "பிரிட்ஜ்,ஏலம்,அட்டைகள்,கற்க,ஆசிரியர்,தொடக்கநிலை,பாடம்,பயிற்சி,பாதுகாப்பு,ஏலதாரர்,விளையாட,வினாடிவினா",
        "promotional_text": "ஏலம், டிக்ளெரர் ப்ளே மற்றும் பாதுகாப்பிற்கான ஐந்து நிமிட பிரிட்ஜ் பயிற்சிகள். ஒவ்வொரு அட்டையின் காரணத்தையும் அறியவும்.",
        "release_notes": "பிரிட்ஜ் ட்ரைனருக்கு வரவேற்கிறோம். நான்கு இலவச அறைகளில் விதிகள், ஓப்பனிங் ஏலம், விளையாட்டு மற்றும் பாதுகாப்பைப் பயிற்சி செய்யவும்.",
        "description": """ஐந்து நிமிட அமர்வுகளில் உண்மையான ஒப்பந்த பிரிட்ஜ் (Contract Bridge) உள்ளுணர்வை உருவாக்குங்கள்.

Bridge Trainer தொடக்கக்காரர்களுக்கு மிகவும் தேவையான பகுதிகளை விரைவான, கவனம் செலுத்திய பயிற்சிகளாக மாற்றுகிறது. எதிர்ப்பாளர்கள் இல்லை, டைமர்கள் இல்லை, எந்த அழுத்தமும் இல்லை. புள்ளிகளை எண்ணுங்கள், ஒரு தொடக்க ஏலத்தைத் தேர்ந்தெடுக்கவும், விளையாட்டைத் திட்டமிடவும், மேலும் ஒவ்வொரு பதிலின் பின்னணியில் உள்ள காரணத்துடன் பாதுகாப்புப் பழக்கங்களைக் கற்றுக்கொள்ளுங்கள்.

நான்கு இலவச பயிற்சி அறைகள்

கார்டு அறை (CARD ROOM)
அட்டை தரவரிசைகள், உயர் அட்டை புள்ளிகள் (HCP), தந்திரங்கள், டிரம்ப், ஒப்பந்தங்கள் மற்றும் மேஜையில் உள்ள பாத்திரங்களைக் கற்றுக்கொள்ளுங்கள்.

ஏல அறை (AUCTION ROOM)
தொடக்கக்காரர்களுக்கான ஸ்டாண்டர்ட் அமெரிக்கன் கட்டமைப்பைப் பயிற்சி செய்யுங்கள். 13 அட்டை கைகளைப் படித்து, பாஸ், சூட் ஓப்பனிங் அல்லது 1NT ஆகியவற்றிற்கு இடையே தேர்வு செய்யவும்.

டிக்ளெரர் அறை (DECLARER ROOM)
வெற்றிபெறும் தந்திரங்களை எண்ணுங்கள், டிரம்ப் அட்டைகளை இழுக்கவும், நீண்ட சூட்களை நிறுவவும், ஃபினெஸ் செய்யவும் மற்றும் விளையாட்டின் சூழ்நிலைகளில் சரியான அட்டையைத் தேர்ந்தெடுக்கவும்.

பாதுகாப்பு அறை (DEFENSE ROOM)
தொடக்க லீட்கள், வரிசைகள், மூன்றாம் கை விளையாட்டு, சூட் ரிட்டர்ன்கள் மற்றும் கூட்டாண்மை பழக்கங்களை பயிற்சி செய்யுங்கள்.

BRIDGE+ (விருப்ப மேம்படுத்தல்)
மேலே உள்ள அனைத்தும் எப்போதும் இலவசமாக இருக்கும். Bridge+ ஒவ்வொரு அறையிலும் கூடுதல் பயிற்சித் தொகுப்புகளைச் சேர்க்கிறது மற்றும் மேம்பட்ட மரபுகள், அட்டை விளையாட்டு மற்றும் டூப்ளிகேட் உத்திகளுடன் Master Tables ஐத் திறக்கிறது.

கற்றலுக்காக உருவாக்கப்பட்டது
ஸ்வைப் செய்யக்கூடிய பயிற்சி அட்டைகள், விரைவான வினாடி வினாக்கள், யதார்த்தமான 13-அட்டை கைகள், அட்டை விளையாட்டு காட்சிகள், தொடர் பயிற்சி பழக்கங்கள் மற்றும் தவறவிட்ட உள்ளடக்கங்களை மீண்டும் கொண்டு வரும் தினசரி கலப்பு அமர்வு.

Bridge Trainer தொடக்கக்காரர்களுக்கான ஸ்டாண்டர்ட் அமெரிக்கன் கட்டமைப்பைப் பயன்படுத்துகிறது. கூட்டாண்மை ஒப்பந்தங்கள் மாறுபடலாம், எனவே உங்கள் கூட்டாளருடன் மரபுகளை உறுதிப்படுத்தவும்.

சந்தாக்கள்
Bridge+ தானாக புதுப்பிக்கும் சந்தா அல்லது ஒரு முறை கொள்முதல் மூலம் கிடைக்கிறது: மாதாந்திர $1.99/மாதம், ஆண்டு $9.99/ஆண்டு (இரண்டும் 1 வார இலவச சோதனையை உள்ளடக்கியது) அல்லது வாழ்நாள் $29.99 ஒரு முறை கட்டணம். வாங்கியதை உறுதிப்படுத்தியவுடன் உங்கள் Apple ID கணக்கில் கட்டணம் விதிக்கப்படும். தற்போதைய காலம் முடிவதற்கு குறைந்தது 24 மணிநேரத்திற்கு முன்பே ரத்து செய்யப்படாவிட்டால் சந்தாக்கள் தானாகவே புதுப்பிக்கப்படும். உங்கள் சாதனத்தில் உள்ள கணக்கு அமைப்புகளில் எப்போது வேண்டுமானாலும் நிர்வகிக்கலாம் அல்லது ரத்து செய்யலாம். பயன்பாட்டு விதிமுறைகள் (ஆப்பிளின் நிலையான EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. தனியுரிமைக் கொள்கை: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "te-IN": {
        "name": "బ్రిడ్జ్ ట్రైనర్: నేర్చుకోండి",
        "subtitle": "బ్రిడ్జ్ బిడ్డింగ్ ప్రాక్టీస్",
        "keywords": "బ్రిడ్జ్,బిడ్డింగ్,కార్డులు,నేర్చుకోండి,ట్యూటర్,ప్రారంభకులు,పాఠం,ప్రాక్టీస్,రక్షణ,డిక్లేరర్,ఆటలు,ఆట",
        "promotional_text": "బిడ్డింగ్, డిക്లేరర్ ప్లే మరియు డిఫెన్స్ కోసం ఐదు నిమిషాల బ్రిడ్జ్ డ్రిల్స్. ప్రతి కార్డ్ వెనుక ఉన్న కారణాన్ని నేర్చుకోండి.",
        "release_notes": "బ్రిడ్జ్ ట్రైనర్‌కు స్వాగతం. నాలుగు ఉచిత గదుల్లో నియమాలు, ఓపెనింగ్ బిడ్లు, ప్లే మరియు డిఫెన్స్ ప్రాక్టీస్ చేయండి.",
        "description": """ఐదు నిమిషాల సెషన్లలో నిజమైన కాంట్రాక్ట్ బ్రిడ్జ్ నైపుణ్యాలను పెంపొందించుకోండి.

Bridge Trainer ప్రారంభకులకు అత్యంత అవసరమైన భాగాలను శీఘ్ర, కేంద్రీకృత డ్రిల్స్‌గా మారుస్తుంది. ప్రత్యర్థులు లేరు, టైమర్లు లేవు మరియు ఎటువంటి ఒత్తిడి లేదు. పాయింట్లను లెక్కించండి, ఓపెనింగ్ బిడ్ ఎంచుకోండి, ఆటను ప్లాన్ చేయండిและ ప్రతి సమాధానం వెనుక ఉన్న వివరణతో డిఫెన్స్ అలవాట్లను నేర్చుకోండి.

నాలుగు ఉచిత ప్రాక్టీస్ గదులు

కార్డ్ రూమ్ (CARD ROOM)
కార్డ్ ర్యాంకులు, హై-కార్డ్ పాయింట్లు (HCP), ట్రిక్స్, ట్రంప్, కాంట్రాక్టులు మరియు టేเบల్ వద్ద పాత్రలను నేర్చుకోండి.

బిడ్డింగ్ రూమ్ (AUCTION ROOM)
ప్రారంభకుల కోసం స్టాండర్ڈ అమెరికన్ ఫ్రేమ్‌వర్క్ ప్రాక్టీస్ చేయండి. 13 కార్డుల చేతులను చదవండి మరియు పాస్, సూట్ ఓపెనింగ్ లేదా 1NT ల మధ్య ఎంచుకోండి.

డిక్లేరర్ రూమ్ (DECLARER ROOM)
గెలిచే ట్రిక్స్‌ను లెక్కించండి, ట్రంప్ కార్డులను లాగండి, లాంగ్ సూట్లను స్థాపించండి, ఫినెస్ చేయండి మరియు ఆట యొక్క పరిస్థితులలో సరైన కార్డును ఎంచుకోండి.

డిఫెన్స్ రూమ్ (DEFENSE ROOM)
ఓపెనింగ్ లీడ్స్, సీక్వెన్సులు, థర్డ్-హ్యాండ్ ప్లే, సూట్ రిటర్న్లు మరియు పార్టనర్‌షిప్ అలవాట్లను శిక్షణ పొందండి.

BRIDGE+ (ఐచ్ఛిక అప్‌గ્રેడ్)
పైన పేర్కొన్నవన్నీ ఎల్లప్పుడూ ఉచితంగా ఉంటాయి. Bridge+ ప్రతి రూమ్‌లో అదనపు ప్రాక్టీస్ సెట్లను జోడిస్తుంది మరియు అధునాతన కన్వెన్షన్లు, కార్ด ప్లే మరియు డూప్లికేట్ వ్యూహాలతో Master Tables ను అన్‌లాక్ చేస్తుంది.

नेच्छुकोवडानिकी अनुकूलमैनदी
స్వైప్ చేయగల కోచింగ్ కార్డులు, శీఘ్ర క్విజ్లు, వాస్తవిక 13-కార్డుల చేతులు, కార్డ్ ప్లే దృశ్యాలు, స్ట్రీక్స్ మరియు తప్పులను సరిదిద్దే రోజువاري మిశ్రమ సెషన్.

Bridge Trainer ప్రారంభకుల కోసం స్టాండర్డ్ అమెరికన్ ఫ్రేమ్‌వర్క్ను ఉపयोగిస్తుంది. పార్టనర్‌షిప్ ఒప్పందాలు మారవచ్చు, కాబట్టి మీ పార్టనర్‌తో కన్వెన్షన్లను ధృవీకరించుకోండి.

చందా వివరాలు
Bridge+ స్వయంచాలక పునరుద్ధరణ చందా లేదా ఒకే సారి కొనుగోలు ద్వారా అందుబాటులో ఉంటుంది: నెలవారీ $1.99/నెల, వార్షిక $9.99/సంవత్సరం (రెండూ 1 వారాల ఉచిత ట్రయల్‌ను కలిగి ఉంటాయి) లేదా జీవితకాలం $29.99 ఒకೇ సారి చెల్లింపు. కొనుగోలు నిర్ధారించబడినప్పుడు మీ Apple ID ఖాతాకు ఛార్జ్ చేయబడుతుంది. ప్రస్థుత వ్యవధి ముగిసే సమయానికి కనీసం 24 గంటల ముందు రద్దు చేయకపోతే చందా స్వయంచాలకంగా పునరుద్ధరించబడుతుంది. మీ పరికరంలోని ఖాతా సెట్టింగ్‌లలో ఎప్పుడైనా నిర్వహించండి లేదా రద్దు చేయండి. ఉపయోగ నిబంధనలు (Apple యొక్క ప్రామాణిక EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. గోప్యతా విధానం: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ur-PK": {
        "name": "Bridge Trainer: برج سیکھیں",
        "subtitle": "برج کی بولیاں اور تاش کی مشق",
        "keywords": "برج,بولیاں,تاش,سیکھیں,ٹیوٹر,مبتدی,سبق,مشق,دفاع,اعلان کنندہ,پریکٹس,کوئز,کھیل,پوائنٹ,اسکور,کارڈ,مذا",
        "promotional_text": "بولیاں (بِڈنگ)، ڈیکلیئرر پلے اور دفاع کی مشق کے لیے پانچ منٹ کے برج ڈرلز۔ هر تاش کے پیچھے چھپی وجہ جانیں۔",
        "release_notes": "برج ٹرینر میں خوش آمدید۔ چار مفت کمروں میں قواعد، اوپننگ بولی، پلے اور دفاع کی مشق کریں۔",
        "description": """صرف پانچ منٹ के سیشنز میں حقیقی کانٹریکٹ برج کی مہارت حاصل کریں۔

Bridge Trainer نئے کھلاڑیوں کے لیے انتہائی ضروری حصوں کو فوری اور توجہ مرکوز کرنے والی مشقوں میں تبدیل کرتا ہے۔ کوئی حریف نہیں، کوئی ٹائمر نہیں اور کوئی دباؤ نہیں۔ پوائنٹس گنیں, اوپننگ بولی کا انتخاب کریں، کھیل کی منصوبہ بندی کریں، اور ہر جواب کے پیچھے تفصیلی منطق کے ساتھ دفاع کی عادات سیکھیں۔

چار مفت پریکٹس رومز

تاش کا کمرہ (CARD ROOM)
تاش کی رینکنگ، ہائی کارڈ پوائنٹس (HCP)، ٹرکس، ٹرمپ، کانٹریکٹ اور ٹیبل پر کرداروں کے بارے میں جانیں۔

بولی کا کمرہ (AUCTION ROOM)
مبتدیوں کے لیے اسٹینڈرڈ امریکن فریم ورک کی مشق کریں۔ 13 تاش کے پتے پڑھیں اور پاس، سوٹ اوپننگ یا 1NT میں سے انتخاب کریں۔

ڈیکلیئرر کا کمرہ (DECLARER ROOM)
جیتنے والے ٹرکس گنیں، ٹرمپ پتے نکالیں، لمبے سوٹس قائم کریں، فینیس کریں اور کھیل کے دوران صحیح تاش کا انتخاب کریں۔

دفاع کا کمرہ (DEFENSE ROOM)
اوپننگ لیڈز، تسلسل، تھرڈ ہینڈ پلے، سوٹ ریٹرن اور پارٹنرشپ کی عادات کی مشق کریں۔

BRIDGE+ (اختیاری اپ گریڈ)
اوپر دی گئی تمام چیزیں ہمیشہ کے لیے بالکل مفت رہیں گی۔ Bridge+ ہر کمرے میں اضافی مشق کے سیٹ شامل کرتا ہے اور جدید قوانین، کارڈ پلے اور ڈوپلی کیٹ حکمت عملی کے ساتھ Master Tables کو ان لاک کرتا ہے۔

سیکھنے کے لیے تیار کردہ
سوائپ کے قابل کوچنگ کارڈز، فوری کوئزز، 13 تاش کے حقیقت پسندانہ پتے، کارڈ پلے کے منظرنامے، مشق کی تسلسل کی ہسٹری اور روزانہ کی مخلوط مشق جو غلطیوں کو سدھارتی ہے۔

Bridge Trainer مبتدیوں کے لیے اسٹینڈرڈ امریکن فریم ورک کا استعمال کرتا ہے۔ شراکت داروں کے درمیان معاہدے مختلف ہو سکتے ہیں، لہذا اپنے پارٹنر کے ساتھ کنونشنز کی تصدیق کریں۔

سبسکرپشن
Bridge+ آٹو رینیو ہونے والی سبسکرپشن یا یکمشت خریداری کے ذریعے دستیاب ہے: ماہانہ $1.99/ماہ، سالانہ $9.99/سال (دونوں میں 1 ہفتے کا مفت ٹرائل شامل ہے) یا لائف ٹائم $29.99 یکمشت ادائیگی۔ خریداری کی تصدیق پر ادائیگی آپ کے Apple ID اکاؤنٹ سے وصول کی جائے گی۔ سبسکرپشنز خود بخود رینیو ہو جاتی ہیں جب تک کہ موجودہ مدت کے خاتمے سے کم از کم 24 گھنٹے پہلے اسے منسوخ نہ کیا جائے۔ اپنے آلے کی اکاؤنٹ سیٹنگز میں کسی بھی وقت مینیج یا منسوخ کریں۔ استعمال کی شرائط (Apple کا معیاری EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/۔ رازداری کی پالیسی: https://jackwallner.github.io/bridge/privacy-policy।"""
    },
    "he": {
        "name": "Bridge Trainer: ללמוד ברידג׳",
        "subtitle": "תרגול הכרזות ומשחק ברידג׳",
        "keywords": "ברידג׳,הכרזות,קלפים,למידה,מורה,מתחיל,שיעור,תרגול,הגנה,כרוז,אימון,חידון,משחק,קלף,חוזה,תחרות,חשיבה,שחק",
        "promotional_text": "תרגילים בני חמש דקות בברידג׳ להכרזות, משחק הכרוז והגנה. למדו את ההיגיון שמאחורי כל קלף.",
        "release_notes": "ברוכים הבאים ל-Bridge Trainer. תרגלו חוקים, הכרזות פתיحة, משחק הכרוז והגנה בארבעה חדרים חינם.",
        "description": """פתח אינסטינקטים אמיתיים בברידג׳ חוזה במפגשים של חמש דקות בלבד.

Bridge Trainer הופך את הנושאים שמתחילים הכי צריכים לתרגילים מהירים וממוקדים. ללא יריבים, ללא טיימרים וללא לחץ. ספרו נקודות, בחרו הכרזת פתיחה, תכננו את המשחק ולמדו הרгלי הגנה עם ההסבר שמאחורי כל תשובה.

ארבעה חדרי תרגול בחינם

חדר הקלפים
למדו את דירוг הקלפים, נקודות קלפים גבוהים, לקיחות, שליט, חוזים ותפקידי השולחן.

חדר ההכרזות
תרגלו את שיטת Standard American למתחילים. קראו ידיים של 13 קלפים ובחרו בין פאס, פתיחה בסدרה או 1NT.

חדר הכרוז
ספרו לקיחות זוכות, משכו שליטים, בססו סדרות ארוכות, בצעו עקיפות ובחרו את הקלף הנכון.

חדר ההגנה
תרגلو הובלות פתיחה, רצפים, משחק יד שלישית, חזרות סدרה והרגלי שותפות.

BRIDGE+ (אופציונלי)
כל מה שמופיע למعלה נשאר בחינם. Bridge+ מוסיף תרגול נוסף בכל חדר למתחילים ופותח את ה-Master Tables עם קונבנציות, משחק קלפים מתקדם ואסטרטגיית duplicate.

נבנה ללמידה
כרטיסי הדרכה בהחלקה, חידונים מהירים, ידיים מציאותיות של 13 קלפים, תרחישי משחק, רצפי הצלחות ומפגש מעורב יומי שמחזיר חומר שהוחمץ.

Bridge Trainer משתמש בשיטת Standard American למתחילים. הסכמי שותפות משתנים, לכן אשרו קונבנציות עם השותף שלכם.

מנויים
Bridge+ זמין באמצעות מנוי מתחדש או רכישה חד-פעמית: חודשי ב-$1.99 לחודש, שנתי ב-$9.99 לשנה (שניהם כוללים שבוע ניסיון חינם), או לכל החיים ב-$29.99 ברכישה חד-פעמית. החיوب מבוצע בחשבون Apple ID שלכם עם אישור הרכישה. המנויים מתחדשים אוטומטית אלא אם כן בוטلو לפחות 24 שעות לפני תום התקופה הנוכحית. נהלו או בטלו בכל עת בהגדרות החשבون במכשירכם. תנאי שימוש (EULA הסטנדרטי של Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. מדיניות פרטיות: https://jackwallner.github.io/bridge/privacy-policy."""
    },
    "ar-SA": {
        "name": "Bridge Trainer: تعلم البلاي",
        "subtitle": "تدريبات مزايدة ولعب بريدج",
        "keywords": "بريدج,مزايدة,ورق,تعلم,معلم,مبتدئ,درس,تدريب,دفاع,لعب,ممارسة,مسابقة,أوراق,نقاط,العاب,تسجيل,تفكير,ذكاء",
        "promotional_text": "تمارين بريدج مدتها خمس دقائق للمزايدة، لعب المعلن والدفاع. تعلم السبب وراء كل ورقة.",
        "release_notes": "مرحبًا بك في Bridge Trainer. تدرب على القواعد، مزايدات الافتتاح، لعب المعلن والدفاع في 4 غرف مجانية.",
        "description": """ابنِ غرائز حقيقية للعبة البريدج في جلسات مدتها خمس دقائق فقط.

يحول Bridge Trainer القواعد التي يحتاجها المبتدئون إلى تمارين سريعة ومركزة. لا يوجد منافسون، ولا مؤقتات، ولا ضغوط. احسب النقاط، اختر مزايدة افتتاحية، خطط للعب، وتعلم عادات الدفاع مع التفسير العلمي وراء كل إجابة.

أربع غرف تدريب مجانية

غرفة الأوراق
تعلم ترتيب الأوراق, نقاط الأوراق العالية، اللمات، الأتوت، العقود والأدوار على الطاولة.

غرفة المزايدة
تدرب على نظام Standard American للمبتدئين. اقرأ اليد المكونة من 13 ورقة واختر بين التمرير (Pass) أو افتتاح اللون أو 1NT.

غرفة المعلن
احسب اللمات الرابحة، اسحب الأتوت، أسس الألوان الطويلة، قم بالفينيس واختر الورقة الصحيحة في مواقف اللعب.

غرفة الدفاع
تدرب على قيادة الافتتاح، التتابعات، لعب اليد الثالثة، إرجاع اللون وعادات الشراكة.

BRIDGE+ (اختياري)
كل شيء أعلاه يظل مجانيًا. يضيف Bridge+ تمارين إضافية في كل غرفة للمبتدئين ويفتح الـ Master Tables، مع الاتفاقيات ولعب الأوراق المتقدم واستراتيجية duplicate.

مصمم للتعلم
بطاقات تدريب تفاعلية، اختبارات سريعة، أيدي واقعية مكونة من 13 ورقة، سيناريوهات اللعب، وسلسلة انتصارات، وجلسة يومية مختلطة تعيد المواد المفقودة.

يستخدم Bridge Trainer نظام Standard American للمبتدئين. تختلف اتفاقيات الشراكة، لذا يرجى تأكيد الاتفاقيات مع شريكك.

الاشتراكات
يتوفر Bridge+ عن طريق اشتراك يتجدد تلقائيًا أو عملية شراء لمرة واحدة: شهريًا بـ 1.99 دولار/الشهر، سنويًا بـ 9.99 دولار/السنة (كلاهما يتضمن فترة تجريبية مجانية لمدة أسبوع)، أو مدى الحياة بـ 29.99 دولار لمرة واحدة. يتم فرض الدفع على حساب Apple ID الخاص بك عند تأكيد الشراء. تتجدد الاشتراكات تلقائيًا ما لم يتم إلغاؤها قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يمكنك الإدارة أو الإلغاء في أي وقت في إعدادات الحساب على جهازك. شروط الاستخدام (اتفاقية ترخيص المستخدم النهائي القياسية من Apple): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/. سياسة الخصوصية: https://jackwallner.github.io/bridge/privacy-policy."""
    }
}

import json
supported_file = Path(__file__).parent / "asc-supported-locales.json"
supported_locales = json.loads(supported_file.read_text())["locales"]

print(f"Generating App Store Connect metadata for {len(supported_locales)} locales...")

for locale in supported_locales:
    base = locale
    # Graceful fallback logic for regional language variations
    if locale not in DATA:
        base = "en-US"
        if locale in ["es-MX", "es-ES"]:
            base = "es-ES"
        elif locale in ["fr-CA", "fr-FR"]:
            base = "fr-FR"
        elif locale in ["pt-PT", "pt-BR"]:
            base = "pt-BR"
            
    name = DATA[base]["name"]
    subtitle = DATA[base]["subtitle"]
    keywords = DATA[base]["keywords"]
    
    # Strictly validate character limits required by user request
    name_len = len(name)
    sub_len = len(subtitle)
    key_len = len(keywords)
    
    if not (24 <= name_len <= 30):
        raise ValueError(f"Locale {locale} has invalid name length {name_len} ('{name}')")
    if not (24 <= sub_len <= 30):
        raise ValueError(f"Locale {locale} has invalid subtitle length {sub_len} ('{subtitle}')")
    if not (94 <= key_len <= 100):
        raise ValueError(f"Locale {locale} has invalid keywords length {key_len} ('{keywords}')")
        
    write_meta(locale, "name", name)
    write_meta(locale, "subtitle", subtitle)
    write_meta(locale, "keywords", keywords)
    # For South Asian locales with complex scripts, fallback to English description/promo/release notes to avoid homoglyph rejections
    if locale in ["bn-BD", "gu-IN", "kn-IN", "ml-IN", "or-IN", "pa-IN", "ta-IN", "te-IN", "ur-PK"]:
        write_meta(locale, "promotional_text", DATA["en-US"]["promotional_text"])
        write_meta(locale, "release_notes", DATA["en-US"]["release_notes"])
        write_meta(locale, "description", DATA["en-US"]["description"])
    else:
        write_meta(locale, "promotional_text", DATA[base]["promotional_text"])
        write_meta(locale, "release_notes", DATA[base]["release_notes"])
        write_meta(locale, "description", DATA[base]["description"])
    write_meta(locale, "apple_tv_privacy_policy", "")
    write_meta(locale, "copyright", "2026 Jack Wallner")
    write_meta(locale, "support_url", "https://jackwallner.github.io/bridge/support")
    write_meta(locale, "privacy_url", "https://jackwallner.github.io/bridge/privacy-policy")
    write_meta(locale, "marketing_url", "https://jackwallner.github.io/bridge")

print("All metadata files successfully validated and generated!")
