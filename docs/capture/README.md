# Aggiornare gli screenshot del README

Le immagini vengono renderizzate dai componenti QML di produzione, con font e risorse di `resources.qrc`. I dati di account, attività e preferenze sono dimostrativi; la cattura non avvia Codex e non modifica le impostazioni di Codex Meter.

Da PowerShell, nella radice del progetto, con un kit Qt 6 MinGW che includa Qt Quick Test:

```powershell
./docs/capture/capture.ps1 -QtBin 'C:/Qt/Qt6.9/6.9.0/mingw_64/bin' -MinGWBin 'C:/Qt/Qt6.9/Tools/mingw1310_64/bin'
```

Adatta i percorsi al tuo kit. Lo script compila un piccolo programma di acquisizione in `build/docs-capture`, registra le risorse attuali e sovrascrive i tre PNG in `docs/images`. Verifica poi visivamente le immagini prima di pubblicarle. Le due pagine delle impostazioni mantengono le dimensioni reali della finestra; la panoramica dispone i componenti su una tavola senza sovrapposizioni.

## GIF del pet in azione

Per rigenerare `docs/images/pet-in-action.gif`, usa lo stesso script con `-PetDemo` e un Python con Pillow (versione 9.1 o successiva):

```powershell
./docs/capture/capture.ps1 -QtBin 'C:/Qt/Qt6.9/6.9.0/mingw_64/bin' -MinGWBin 'C:/Qt/Qt6.9/Tools/mingw1310_64/bin' -PetDemo -PythonBin 'python'
```

`tst_pet_demo.qml` renderizza il `PetView` di produzione con DarkShrill e la nuvoletta su un desktop fittizio. La sequenza mostra riposo, scrittura di codice, revisione nel browser, attesa di input, test, completamento ed errore, poi il cambio di mascotte da DarkShrill a Mini Elon e Dario. Tutti i testi usano Poppins; i controlli e le icone sono disegnati senza glifi speciali. Le animazioni mantengono il comportamento del widget: ogni azione viene eseguita una volta. Non vengono lette sessioni o quote reali e non vengono modificate le preferenze dell'app.

La cattura produce 320 PNG a intervalli di 80 ms in `build/docs-capture/pet-frames`; `encode_pet_demo.py` li converte in una GIF di circa 26 secondi, 960 × 600, in loop, con una palette condivisa. La tavola `build/docs-capture/pet-contact-sheet.png` permette di controllare tutte le scene. Questa modalità aggiorna solo la GIF, lasciando invariati gli screenshot.
