# Mascotte PNG

In Impostazioni > Aspetto selezionare Widget: Pet, poi la quinta miniatura
(Germoglio pixel art). Il toggle Anima pet controlla frame e micro-movimenti.

Le cartelle idle, thinking, happy, warning e critical contengono 8 PNG ciascuna;
blink ne contiene 4. Tutti i frame hanno canvas trasparente 96x96, scala comune
e punto di appoggio uniforme. Non ritagliare ogni PNG con dimensioni diverse.
Le cinque sequenze di stato derivano dallo sprite sheet idle disponibile:
sono asset iniziali, sostituibili con espressioni dedicate. Idle esclude il blink
continuo; blink viene riprodotto una volta ogni 6-12 secondi in idle.

## Nuove sequenze

1. Salvare assets/mascot/<nome>/00.png, 01.png, ecc., con canvas e scala comuni.
2. Aggiungere ogni PNG a resources.qrc nel prefisso /.
3. Aggiungere <nome>: { frames: N, fps: 8 } al dizionario animations in
   qml/components/Mascot.qml. fps nel dizionario e facoltativo.
4. Per un gesto occasionale aggiungere il nome a occasionalAnimations;
   oppure invocare mascot.playOnce("celebrate"). Al termine torna allo stato
   generale. Un cambio state interrompe il gesto e riparte dal frame 0.
5. Rieseguire qmake e compilare. CodexMeter.pro include gia resources.qrc.

Non aggiungere uno stato QML State per ogni cartella: il componente usa la
proprieta state ereditata da Item per scegliere la sequenza.

## Configurazione

Mascot {
    width: 88; height: 88
    fps: 8
    mascotScale: 1.0
    playing: true
    state: "idle"
}

Modificare width/height insieme in PetView.qml per il canvas; mascotScale
modifica solo il contenuto visivo. playing=false ferma frame e movimento.
fps e globale, salvo override della singola sequenza. Tutti i frame di una
sequenza vengono caricati prima dell'avanzamento e restano in cache.

PetView usa rateModel.get(0).remainingPercent e ascolta le notifiche del modello.
Soglie: >70 happy, >40 idle, >20 thinking, >10 warning, altrimenti critical.
Il cambiamento viene applicato dopo 1,8 secondi di stabilita. In assenza di dati
si usa idle. Nessun monitoraggio Codex aggiuntivo e stato introdotto.

Test: qmltestrunner -input tests/tst_mascot.qml -platform offscreen
