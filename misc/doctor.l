# 27mar00abu
# (c) Software Lab. Alexander Burger

(de doctor ()
   (use (Mother S @X)
      (off Mother)
      (println '(Speak up))
      (while
         (prog
            (setq S (read))
            (cond
               ((match '(I am worried @X) S)
                  (println (append '(How long have you been worried) @X)) )
               ((match '(@ mother @) S)
                  (on Mother)
                  (println '(Tell me more about your family)) )
               ((match '(@ computers @) S)
                  (println '(Do machines frighten you)) )
               ((< (length S) 3)
                  (println '(Please do not be so short with me)) )
               ((find '((x) (get x 'bad)) S)
                  (println '(Please do not use words like that)) )
               (Mother
                  (off Mother)
                  (println '(Earlier you spoke of your mother)) )
               (T
                  (println '(I am sorry our time is up))
                  NIL ) ) ) ) ) )

(put 'hell T)
(put 'shit T)
(put 'fuck T)
