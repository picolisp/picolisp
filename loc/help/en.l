# 19sep02abu
# (c) Software Lab. Alexander Burger

(html "Browser GUI Help"
   (software-lab)
   (<head> "Function Keys")

   (<pre>
      "  TAB               Go to next field"
      "  Shift-TAB         Go to previous field"
      "  Enter             Next field / Scroll table"
      "  Space             Button: Press"
      "  ESC               Dialog cancel"
      NIL
      "  F1                Help"
      "  F2                Choice List"
      "  F3                Field action (= double click), e.g. follow link"
      "  F4                Form action, e.g. choose-dialog"
      "  F5                Undo"
      "  F6                Redo"
      NIL
      "  Left-Arrow        Character left"
      "  Shift-Left        Extend selection to the left"
      "  Right-Arrow       Character right"
      "  Shift-Right       Extend selection to the right"
      NIL
      "  Up-Arrow          Up in table or text area"
      "  Down-Arrow        Down in table or text area"
      "  Ctrl-Up           Up in table"
      "  Ctrl-Down         Down in table"
      NIL
      "  Pos1              Go to beginning of field"
      "  Ctrl-Pos1         Go to beginning of table"
      "  Shift-Pos1        Select till beginning of field"
      NIL
      "  End               Go to end of field"
      "  Ctrl-End          Go to end of table"
      "  Shift-End         Select till end of field"
      NIL
      "  Page-Up           Page up in table or text area"
      "  Page-Down         Page down in table or text area"
      "  Ctrl-Page-Up      Page up in table"
      "  Ctrl-Page-Down    Page down in table"
      NIL
      "  Backspace         Delete left selection or character"
      "  Delete            Cut selection or delete right character"
      "  Insert            Paste a previously cut selection"
      NIL
      "  Ctrl-Delete       Cut a line from table"
      "  Ctrl-Insert       Paste a previously cut line into table" )

   (<head> "General Notes")
   (<list>
      "Usually upper and lower case is treated differently"
      "Blue font in text fields indicates a link to another object"
      "Light blue background indicates a tolerant search field"
      '(prog
         (prinl "In date fields it is sufficient to input (with or without punctuation)")
         (<list>
            "only the day"
            "only day and month"
            "day, month, and two digits for the year" ) ) )
   (software-lab)
   <hr> )
