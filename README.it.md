<p align="center">
  <img src="assets/darkshrill-icon.png" width="96" alt="Icona di Codex Meter">
</p>

<h1 align="center">Codex Meter</h1>

<p align="center"><a href="README.md">English</a> · <strong>Italiano</strong></p>

<p align="center">
  <strong>Quanto Codex ti resta? Basta uno sguardo al desktop.</strong><br>
  Quote residue, orari di reset e attività delle chat locali in un widget Windows.<br>
  Scegli una card discreta o un pet animato che segue il lavoro di Codex.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Windows-10%20%2F%2011-0078D4?style=flat-square" alt="Windows 10 e 11">
  <img src="https://img.shields.io/badge/Qt-6-41CD52?style=flat-square" alt="Qt 6">
  <img src="https://img.shields.io/badge/versione-0.2.0-51565D?style=flat-square" alt="Versione del codice: 0.2.0">
</p>

<p align="center">
  <a href="#installazione"><strong>🚀 Prova Codex Meter</strong></a>
  &nbsp; · &nbsp;
  <a href="#funzionalita">Esplora le funzionalità</a>
</p>

<!-- TODO README: quando l'URL del repository e una release Windows sono disponibili,
     sostituire il CTA con un link https://github.com/OWNER/REPO/releases/latest
     intitolato "⬇️ Download Latest Release" e indicare il nome esatto dell'asset.
     Non pubblicare OWNER/REPO come link attivo. -->

<p align="center">
  <img src="docs/images/widget-overview.png" width="900" alt="Codex Meter attuale: card Mini, Anello e Monitor, pet DarkShrill con nuvoletta, contatore task e dettagli utilizzo">
  <br><sub>Anteprima dei widget con dati dimostrativi. I limiti effettivi dipendono dall'account Codex.</sub>
</p>

## Perché usarla

L’interfaccia è disponibile in 11 lingue. Seleziona **Lingua** dal menu tray:
il cambio è immediato e la preferenza viene salvata. Vedi [le traduzioni](translations/README.md).

Quando lavori con Codex, sapere quanta quota hai ancora e quando si rinnova ti aiuta a decidere se continuare o fare una pausa. Codex Meter tiene queste informazioni sul desktop, senza dover riaprire ogni volta la schermata dei limiti.

Puoi lasciare in vista solo la percentuale che ti interessa, vedere tre limiti insieme oppure affiancare al lavoro un pet che reagisce all'attività delle chat locali.

<a id="funzionalita"></a>

## ✨ Funzionalità

**Quota residua, subito leggibile**  
Le percentuali mostrano quanto puoi ancora usare. Un clic apre tutti i limiti disponibili con gli orari di reset: finestre di 5 ore, settimanali e riserva quando restituiti da Codex. L'aggiornamento è automatico, con intervallo regolabile e comando manuale.

**Tre modi di tenerla sott'occhio**  
Scegli **Compatto**, **3 limiti** o **Pet**. Per le viste a card hai i formati Mini, Anello e Monitor; per il pet, informazioni minimali o nuvoletta. Regola dimensioni, opacità e permanenza in primo piano, poi trascina il widget dove ti serve.

**Un pet che segue il lavoro**  
Le mascotte reagiscono a ragionamento, esecuzione, revisione, attesa di input, completamento ed errore/interruzione rilevati nei log locali. Scegli fra nove pet inclusi — Kira, DarkShrill, Germoglio, Pip, Clippy, Dario, Doraemon, Goku e Mini Elon — oppure importa il tuo da una cartella o uno ZIP compatibile.

**Le chat attive a portata di clic**  
Nella vista Pet, il contatore apre **Task attivi**, con nomi e stati delle chat rilevate. Puoi spostare la finestra anche su un altro monitor e personalizzare la posizione di informazioni e popup per ciascun pet.

**Anche nella barra di Windows**  
Attiva il monitor delle quote nella barra principale e consulta percentuali e tempo al reset. L'icona nell'area di notifica permette di mostrare o nascondere il widget, aggiornare i dati, scegliere la lingua e aprire le impostazioni. Puoi anche abilitare l'avvio con Windows.

> L'attività dei pet e la lista dei task dipendono dalle sessioni locali di Codex. I task solo cloud non vengono rilevati; alcuni stati o richieste di approvazione possono non comparire nei log. Con più chat, il pet segue quella attiva più recente. Il monitor nella barra appare quando c'è spazio libero.

## 👀 Guarda come funziona

| Aggiornamento dei dati | Integrazione con Windows |
| :---: | :---: |
| <img src="docs/images/settings-refresh.png" width="440" alt="Impostazioni: intervallo in secondi e pulsante Aggiorna adesso"> | <img src="docs/images/settings-windows.png" width="440" alt="Impostazioni: avvio con Windows, monitor nella barra e posizione del widget"> |
| Scegli ogni quanto aggiornare le quote. | Tieni il monitor dove ti è più comodo. |

<p align="center"><sub>Schermate delle impostazioni con dati dimostrativi.</sub></p>

<p align="center">
  <img src="docs/images/pet-in-action.gif" width="900" alt="DarkShrill sul desktop: riposo, scrittura di codice, revisione nel browser, attesa di input, test, completamento, errore e cambio del pet con Mini Elon e Dario">
  <br><sub>DarkShrill, Mini Elon e Dario in azione: componenti e animazioni reali del widget, con desktop, attività e quote simulati.</sub>
</p>
<!-- TODO README: aggiungere uno screenshot del pet con nuvoletta e finestra
     "Task attivi", e uno del monitor integrato nella barra di Windows. -->

<a id="installazione"></a>

## 🚀 Installazione

**Ti servono Windows 10/11 e Codex CLI già installata e autenticata.** Codex Meter usa l'accesso configurato in Codex: non richiede di inserire credenziali nell'app.

**Download pubblico:** in questa copia del progetto non sono presenti un URL GitHub, un installer o un pacchetto Windows completo. Non è quindi disponibile un link verificabile all'ultima release. Gli eseguibili nelle cartelle di build sono compilazioni locali.

Se hai già ricevuto una **cartella Windows completa dell'app**, aprila e avvia **`CodexMeter.exe`**, mantenendo insieme tutti i file forniti. Qt non va installato separatamente se le dipendenze necessarie sono incluse nel pacchetto.

Se hai soltanto i sorgenti, trovi le istruzioni di compilazione nella sezione [Sviluppo](#sviluppo).

<details>
<summary>Codex non viene trovato?</summary>

Verifica da PowerShell:

```powershell
where.exe codex
codex --version
codex app-server --help
```

Se hai appena installato Codex, riavvia Codex Meter per aggiornare il `PATH`. L'app cerca anche nelle posizioni Windows previste dal codice; per indicare esplicitamente un eseguibile puoi impostare `CODEX_CLI_PATH` sul percorso di `codex.exe` prima di avviarla.

</details>

## 🎯 Come funziona

1. **Avvia Codex Meter.** L'app avvia `codex app-server` e legge i limiti dell'account autenticato.
2. **Scegli il tuo widget.** Apri le impostazioni dall'ingranaggio o dall'icona nell'area di notifica e seleziona Compatto, 3 limiti o Pet.
3. **Sistemalo sul desktop.** Trascinalo nella posizione desiderata e regola scala, opacità e primo piano.
4. **Continua a lavorare.** Le quote si aggiornano automaticamente; clicca sul widget per i dettagli e, nella vista Pet, sul contatore per i task attivi.

## 💡 Perché esiste

Un limite raggiunto mentre stai lavorando interrompe il ritmo. Vedere in anticipo la disponibilità residua e il prossimo reset rende più facile organizzarti. Codex Meter nasce per rendere visibili queste informazioni accanto al lavoro; la vista Pet aggiunge anche un segnale visivo dell'attività locale.

## 🎨 Crea e aggiungi il tuo pet

Il tuo personaggio può diventare un widget: prepara **PNG trasparenti** per le sei sequenze `idle`, `running`, `review`, `waiting`, `jumping` e `failed`, poi descrivile in **`frames-manifest.json`** con schema `codexmeter-16-pose-extension`.

1. **Disegna le pose.** Parti da una tela coerente, per esempio 192 × 208 px. Serve almeno un fotogramma per sequenza; aggiungine altri per animarla. Non è obbligatorio averne 16.
2. **Prepara il pacchetto.** Organizza i PNG in `frames/<stato>/` e usa il [manifest di esempio](docs/pets/frames-manifest.example.json), rinominandolo `frames-manifest.json`. Gli elenchi `frames` definiscono l'ordine; `durations` indica i millisecondi per frame, con 125 ms predefiniti.
3. **Importalo.** In **Impostazioni → Aspetto → Pet → Pet / espressione**, premi **+** e scegli la cartella o lo ZIP completo. Il pet viene aggiunto alla raccolta e selezionato.
4. **Provalo.** Abilita **Anima pet**, controlla i gesti con **Prova animazioni** e sistema gli elementi con **Stato e posizioni**.

**[Leggi la guida completa: cartelle, formato JSON, animazioni e importazione →](docs/CREARE_UN_PET.md)**

## 🛠️ Tecnologie

**C++17 · Qt 6 · Qt Quick / QML · qmake.** Interfaccia con Qt Quick Controls 2 e font Poppins, integrazione Windows tramite API native. I limiti arrivano da `codex app-server` via JSON-RPC; l'attività viene letta dalle sessioni in `CODEX_HOME/sessions` oppure `~/.codex/sessions`. L'app non legge né memorizza direttamente le credenziali OpenAI.

<a id="sviluppo"></a>

## 🧑‍💻 Sviluppo

Installa un kit **Qt 6 per Windows** con Core, Gui, Widgets, Qml, Quick e QuickControls2 e il relativo compilatore. La build locale presente usa **Qt 6.9.0 con MinGW 64 bit**; il progetto non dichiara una versione minima più precisa di Qt 6.

Apri [`CodexMeter.pro`](CodexMeter.pro) in Qt Creator, seleziona il kit e usa **Build / Run**. Per compilare dal prompt configurato per Qt e MinGW, partendo dalla radice del progetto:

```bat
mkdir build\README-Release
cd build\README-Release
qmake ..\..\CodexMeter.pro CONFIG+=release
mingw32-make
release\CodexMeter.exe
```

Con un kit MSVC, usa il prompt Qt/MSVC e sostituisci `mingw32-make` con `nmake`. Per leggere le quote reali serve anche Codex CLI autenticata.

<details>
<summary>Anteprime e test</summary>

Le build Debug includono una galleria QML con dati dimostrativi:

```bat
debug\CodexMeter.exe --preview
debug\CodexMeter.exe --preview SettingsPreview.qml
```

I file delle anteprime sono in [`qml/previews`](qml/previews). I test C++ usano Qt Test nei progetti [`activity-tests.pro`](tests/activity-tests.pro), [`taskbar-tests.pro`](tests/taskbar-tests.pro), [`pet-package-tests.pro`](tests/pet-package-tests.pro) e [`localization-tests.pro`](tests/localization-tests.pro); i test QML sono in [`tests`](tests) e usano Qt Quick Test. Per aggiornare gli screenshot dai componenti attuali, usa la [procedura di acquisizione](docs/capture/README.md).

</details>

<details>
<summary>Crediti e licenze degli asset</summary>

Poppins include la [licenza SIL Open Font License](assets/fonts/OFL.txt). Il riferimento per l'atlante di Clippy già documentato nel progetto è lo [script di codex-clippy](https://github.com/Dimava/codex-clippy/blob/master/scripts/build-clippy-pet.ts).

Questa copia non contiene una licenza generale del progetto; la licenza del font riguarda il font stesso.

</details>

## ❤️ Supporta il progetto

Se Codex Meter ti è utile, lascia una ⭐ su GitHub: aiuta altre persone a scoprirlo.
