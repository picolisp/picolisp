# 23jan03abu
# (c) Software Lab. Alexander Burger
# Algorithm from Bengt Grahn (bengt@vikingsw.demon.co.uk)

# Use: p misc/crap.l -"crap \"file\""

# *Char *WordLengths *SentenceLength *SentenceLengths
# *1Words *2Words *3Words *4Words *BegQuads *MidQuads *EndQuads

# Get some probable value according to the frequency distribution
(de frequentValue (Lst)
   (use N
      (unless (=0 (setq N (sum cdr Lst)))
         (setq N (% (abs (rand)) N))
         (car
            (find
               '((X) (lt0 (dec 'N (cdr X))))
               Lst ) ) ) ) )

# Return next token from input stream
(de token ()
   (when
      (loop
         (NIL (setq *Char (char)))
         (T (or (low? *Char) (upp? *Char)) T) )
      (if (=0 *SentenceLength)
         (setq *Char (lowc *Char)) )
      (make
         (link *Char)
         (while (or (low? (setq *Char (char))) (upp? *Char))
            (link *Char) ) ) ) )

# Statistics training
(de learn (In)
   (in In
      (use Token
         (zero *SentenceLength)
         (off *WordLengths *SentenceLengths)
         (while (setq Token (token))
            (accu '*WordLengths (length Token))
            (inc '*SentenceLength)
            (when (member *Char '`(chop "!?.:;"))
               (accu '*SentenceLengths *SentenceLength)
               (zero *SentenceLength) )
            (case (length Token)
               (1 (accu '*1Words Token))
               (2 (accu '*2Words Token))
               (3 (accu '*3Words Token))
               (4 (accu '*4Words Token))
               (T
                  (accu '*BegQuads (head 4 Token))
                  (while (< 4 (length (setq Token (cdr Token))))
                     (accu '*MidQuads (head 4 Token)) )
                  (accu '*EndQuads Token) ) ) ) ) ) )

# Find continuation for a word under construction
(de continuation (Lst Quads)
   (setq Lst (tail 3 Lst))
   (last
      (frequentValue
         (filter
            '((L) (= Lst (head 3 (car L))))
            Quads ) ) ) )

# Compose an output word
(de compose ()
   (use (Len S C)
      (case (setq Len (frequentValue *WordLengths))
         (1 (frequentValue *1Words))
         (2 (frequentValue *2Words))
         (3 (frequentValue *3Words))
         (4 (frequentValue *4Words))
         (T
            (dec 'Len)
            (loop
               (setq S (copy (frequentValue *BegQuads)))
               (while
                  (and
                     (< (length S) Len)
                     (setq C (continuation S *MidQuads)) )
                  (conc S (list C)) )
               (T
                  (and
                     (= (length S) Len)
                     (setq C (continuation S *EndQuads)) )
                  (conc S (list C)) ) ) ) ) ) )

# Generate crap output
(de crap (In)
   (learn In)
   (use (Len W)
      (loop
         (setq
            Len (frequentValue *SentenceLengths)
            W (compose) )
         (prin (uppc (car W)) (cdr W))
         (until (=0 (dec 'Len))
            (prin " ")
            (prin (compose)) )
         (prin ". ")
         (flush) ) ) )
