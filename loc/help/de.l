# 19sep02abu
# (c) Software Lab. Alexander Burger

(html "Browser GUI Help"
   (software-lab)
   (<head> "Funktionstasten")

   (<pre>
      "  TAB               Wechsel zum nächsten Feld"
      "  Shift-TAB         Wechsel zum vorherigen Feld"
      "  Enter             Nächstes Feld / Scrollen in Tabelle"
      "  Leertaste         Button: Auslösen"
      "  ESC               Dialog abbrechen"
      NIL
      "  F1                Hilfe"
      "  F2                Auswahl-Liste"
      "  F3                Feld-Aktion (= Doppelklick), z.B. Link verfolgen"
      "  F4                Form-Aktion, z.B. Auswahl-Dialog"
      "  F5                Undo (Rückgängig)"
      "  F6                Redo (Wiederholen)"
      NIL
      "  Pfeil-Links       Zeichen links"
      "  Shift-Links       Selektion nach links erweitern"
      "  Pfeil-Rechts      Zeichen rechts"
      "  Shift-Rechts      Selektion nach rechts erweitern"
      NIL
      "  Pfeil-Oben        In Tabelle bzw. Text-Area nach oben"
      "  Pfeil-Unten       In Tabelle bzw. Text-Area nach unten"
      "  Ctrl-Oben         In Tabelle nach oben"
      "  Ctrl-Unten        In Tabelle nach unten"
      NIL
      "  Pos1              Zum Feld-Anfang"
      "  Ctrl-Pos1         An den Anfang der Tabelle"
      "  Shift-Pos1        Selektion bis an den Anfang des Feldes"
      NIL
      "  Ende              Zum Feld-Ende"
      "  Ctrl-Ende         Ans Ende der Tabelle"
      "  Shift-Ende        Selektion bis ans Ende des Feldes"
      NIL
      "  Bild-Oben         Blättern in Tabelle bzw. Text-Area"
      "  Bild-Unten        Blättern in Tabelle bzw. Text-Area"
      "  Ctrl-Bild-Oben    Blättern in Tabelle"
      "  Ctrl-Bild-Unten   Blättern in Tabelle"
      NIL
      "  Rückschritt       Selektion bzw. Zeichen links löschen"
      "  Entf              Selektion ausschneiden bzw. Zeichen rechts löschen"
      "  Einfg             Ausgeschnittene Zeichenfolge einfügen"
      NIL
      "  Ctrl-Entf         Zeile aus Tabelle ausschneiden"
      "  Ctrl-Einfg        Ausgeschnittene Zeile in Tabelle einfügen" )

   (<head> "Allgemeine Anmerkungen")
   (<list>
      "Grundsätzlich wird zwischen Groß- und Kleinschreibung unterschieden"
      "Blaue Schrift zeigt eine Verknüpfung zu einem anderen Objekt an"
      "Hellblauer Hintergrund kennzeichnet ein tolerantes Suchfeld"
      '(prog
         (prinl "Bei Datumsfeldern reicht auch die Eingabe (mit oder ohne Punkte) von")
         (<list>
            "nur Tag"
            "nur Tag und Monat"
            "Tag, Monat und zwei Jahresstellen" ) ) )
   (software-lab)
   <hr> )
