# 24nov16abu
# (c) Software Lab. Alexander Burger

# (xmlrpc "localhost" 8080 "user:passwd" "foo.bar" 'int 41 'string "abc" ..)
(de xmlrpc (Host Port Auth Meth . @)
   (let? Sock (connect Host Port)
      (let Xml (tmp 'xmlrpc)
         (out Xml
            (xml? T)
            (xml
               (list 'methodCall NIL
                  (list 'methodName NIL Meth)
                  (make
                     (link 'params NIL)
                     (while (args)
                        (link
                           (list 'param NIL
                              (list 'value NIL (list (next) NIL (next))) ) ) ) ) ) ) )
         (prog1
            (out Sock
               (prinl "POST /RPC2 HTTP/1.0^M")
               (prinl "Host: " Host "^M")
               (let? L (mapcar char (chop Auth))
                  (prin "Authorization: Basic ")  # 7-bit ASCII
                  (while (ext:Base64 (++ L) (++ L) (++ L)))
                  (prinl "^M") )
               (prinl "User-Agent: PicoLisp^M")
               (prinl "Content-Type: text/xml^M")
               (prinl "Accept-Charset: utf-8^M")
               (prinl "Content-Length: " (car (info Xml)) "^M")
               (prinl "^M")
               (in Xml (echo))
               (flush)
               (in Sock
                  (while (line))
                  (let? L (and (xml?) (xml))
                     (when (== 'methodResponse (car L))
                        (xmlrpcValue
                           (car (body L 'params 'param 'value)) ) ) ) ) )
            (close Sock) ) ) ) )

(de xmlrpcKey (Str)
   (or (format Str) (intern Str)) )

(de xmlrpcValue (Lst)
   (let X (caddr Lst)
      (casq (car Lst)
         (string
            (if (cdddr Lst) (apply pack (cddr Lst)) X) )
         ((i4 int) (format X))
         (boolean (= "1" X))
         (double (format X *Scl))
         (array
            (when (== 'data (car X))
               (mapcar
                  '((L)
                     (and (== 'value (car L)) (xmlrpcValue (caddr L))) )
                  (cddr X) ) ) )
         (struct
            (extract
               '((L)
                  (when (== 'member (car L))
                     (cons
                        (xmlrpcKey (caddr (assoc 'name L)))
                        (xmlrpcValue (caddr (assoc 'value L))) ) ) )
               (cddr Lst) ) ) ) ) )

# SSL transactions
# By meingbg <meingbg@gmail.com>
(de xmlrpcssl (Url Meth . @)
   (let Xml (tmp "xmlrpcssl")
      (out Xml
         (xml? T)
         (xml
            (list 'methodCall NIL
               (list 'methodName NIL Meth)
               (make
                  (link 'params NIL)
                  (while (args)
                     (link
                        (list 'param NIL
                           (list 'value NIL (list (next) NIL (next))) ) ) ) ) ) ) )
      (in (list "wget" "--no-http-keep-alive" "--no-check-certificate" (pack "--post-file=" Xml) "-O" "-" "-o" "/dev/null" Url)
         (let? L (and (xml?) (xml))
            (when (== 'methodResponse (car L))
               (xmlrpcValue
                  (car (body L 'params 'param 'value)) ) ) ) ) ) )

# vi:et:ts=3:sw=3
