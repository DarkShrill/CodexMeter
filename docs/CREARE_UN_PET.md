# Crea il tuo pet per Codex Meter

Un pet personalizzato è una raccolta di fotogrammi PNG, organizzati per animazione, con un file JSON che ne descrive l'ordine e i tempi. Puoi disegnarlo, renderizzarlo in 3D o generare le pose con lo strumento grafico che preferisci: l'app importa le immagini già pronte.

## 1. Prepara il personaggio

Scegli un personaggio riconoscibile anche in piccolo. Esporta ogni posa come **PNG con sfondo trasparente**, mantenendo dimensioni, scala e posizione coerenti fra i fotogrammi: evita che il personaggio cambi grandezza o salti di posizione involontariamente.

**192 × 208 px** è una buona base, usata dai pet del progetto. È una raccomandazione grafica, non un vincolo del validatore. Lascia margine per salti, mani e accessori; usa la stessa tela per tutte le pose.

Per partire bastano **sei immagini, una per ogni stato obbligatorio**. Per ottenere movimento, aggiungi più fotogrammi nelle rispettive sequenze. Il nome dello schema contiene `16`, ma **non sono obbligatori 16 fotogrammi**: ogni sequenza deve averne almeno uno.

## 2. Organizza le animazioni

| Cartella / stato | Quando viene usato | Cosa puoi disegnare |
| --- | --- | --- |
| `idle` | Riposo | Il personaggio fermo, un respiro o un battito di palpebre |
| `running` | Ragionamento ed esecuzione, se non ci sono sequenze dedicate | Una posa concentrata o il personaggio al lavoro |
| `review` | Revisione | Un gesto di controllo o osservazione |
| `waiting` | Attesa di input; fallback per avviso | Il personaggio che aspetta |
| `jumping` | Completamento; fallback per felicità | Un salto o un gesto di soddisfazione |
| `failed` | Errore o interruzione; fallback per stato critico | Una reazione sorpresa o dispiaciuta |

Puoi aggiungere `thinking`, `working`, `running-left`, `running-right` o altri stati riconosciuti dal widget per evitare il fallback. `waving` è facoltativo: la sua presenza non abilita automaticamente un saluto periodico per i pet importati.

Struttura consigliata:

```text
MioPet/
├── frames-manifest.json
└── frames/
    ├── idle/00.png
    ├── running/00.png
    ├── review/00.png
    ├── waiting/00.png
    ├── jumping/00.png
    └── failed/00.png
```

Per una sequenza animata, aggiungi per esempio `01.png`, `02.png` e così via. La numerazione è una convenzione comoda: **il manifest stabilisce l'ordine**, non il nome del file. Un GIF o un atlante/spritesheet da solo non è un pacchetto importabile: esporta prima i singoli fotogrammi.

## 3. Scrivi il manifest

Copia [questo modello completo](pets/frames-manifest.example.json), rinominalo **`frames-manifest.json`** e mettilo nella radice di `MioPet`. Cambia `name` e aggiungi all'elenco i PNG che hai creato. Il modello contiene le sei sequenze richieste, con un frame ciascuna; i PNG vanno preparati da te.

Ecco come definire una sequenza con tre fotogrammi dentro `rows`:

```json
{
  "state": "idle",
  "frames": [
    "frames/idle/00.png",
    "frames/idle/01.png",
    "frames/idle/02.png"
  ],
  "durations": [125, 125, 250]
}
```

| Campo | Formato e significato |
| --- | --- |
| `schema` | Stringa esatta: `codexmeter-16-pose-extension` |
| `name` | Nome visualizzato nella raccolta; usa un nome breve, fino a 32 caratteri |
| `rows` | Array delle animazioni |
| `state` | Nome dello stato, per esempio `idle` |
| `frames` | Array non vuoto di percorsi relativi ai PNG, nell'ordine di riproduzione |
| `durations` | Array facoltativo di tempi in millisecondi, uno per fotogramma |

Usa `/` nei percorsi ed evita riferimenti assoluti al tuo computer. Per ogni durata assente l'app usa **125 ms**, cioè 8 fotogrammi al secondo; i tempi vengono limitati all'intervallo **20–2000 ms**. Un frame più lungo rende una pausa, uno più breve accelera il gesto.

Il manifest può anche stare dentro `frames/`: in quel caso usa percorsi come `idle/00.png`. Per un nuovo pacchetto, la struttura con manifest nella radice e percorsi `frames/idle/00.png` è la più semplice da condividere.

## 4. Aggiungilo all'app

1. Apri **Impostazioni → Aspetto**, scegli **Pet** e cerca **Pet / espressione**.
2. Premi il riquadro **+**. Scegli la cartella `MioPet`, oppure uno ZIP che contenga manifest e fotogrammi nella stessa struttura.
3. Dopo un'importazione riuscita, il pet entra nella raccolta ed è selezionato automaticamente. L'app ne conserva una copia autonoma nei propri dati: non dipende più dalla cartella originale.
4. Abilita **Anima pet**, apri **Prova animazioni** e verifica i gesti. Le sequenze del pet importato si riproducono al cambio di stato e mantengono l'ultima posa fino allo stato successivo.
5. Usa **Stato e posizioni** per sistemare nuvoletta/info, barra task e popup. Le posizioni si salvano per il pet selezionato.

Per uno ZIP, comprimi l'intera cartella `MioPet` o il suo contenuto, conservando le sottocartelle. Se l'app non riesce a estrarlo, decomprimilo e importa la cartella: l'importazione ZIP usa il comando `tar` di Windows.

## Se qualcosa non funziona

- **Manifest non trovato:** controlla che il file si chiami `frames-manifest.json`, senza un'estensione `.txt` aggiunta.
- **Schema non riconosciuto:** copia esattamente il valore di `schema` dal modello.
- **Animazioni mancanti:** tutte le sei sequenze obbligatorie devono comparire in `rows` con almeno un PNG valido.
- **Immagine mancante o non valida:** verifica il percorso nel manifest e che il PNG sia leggibile. Aggiungere una cartella senza aggiornare il manifest non basta.
- **Il pet rimane fermo:** controlla **Anima pet** e prova le animazioni dall'anteprima. Un solo fotogramma per sequenza produce pose statiche; gli stati durante il lavoro dipendono dagli eventi delle sessioni locali di Codex.

Torna al [README](../README.md).
