# 27dec00abu
# (c) Software Lab. Alexander Burger

(seed (in "/dev/urandom" (rd 8)))

(de train ()
   (let Sum 0
      (do 10
         (let C (char (rand `(char "a") `(char "z")))
            (do 72
               (prin C)
               (flush)
               (T (= C (key 100)))
               (inc 'Sum)
               (prin "^H ") ) )
         (prinl) )
      Sum ) )
