# 26jan15abu
# (c) Software Lab. Alexander Burger

#: pil @java/lib.l @java/test.l +

(javac "Test" NIL NIL "java.util.*" "java.math.*" "java.security.*")
   public String Name;
   public Object Val;
   public int Cnt;

   public Test(String nm, Object val, int cnt) {
      Name = nm;
      Val = val;
      Cnt = cnt;
   }

   public Test(String nm, int cnt) {
      Name = nm;
      Val = this;
      Cnt = cnt;
   }

   public static String type(boolean b) {return "boolean";}
   public static String type(byte b) {return "byte";}
   public static String type(char n) {return "char";}
   public static String type(short s) {return "short";}
   public static String type(int i) {return "int";}
   public static String type(long n) {return "long";}
   public static String type(double d) {return "double";}
   public static String type(BigInteger b) {return "big";}
   public static String type(String s) {return "String";}
   public static String type(byte[] lst) {return "byte[]";}
   public static String type(int[] lst) {return "int[]";}
   public static String type(double[] s) {return "double[]";}
   public static String type(String[] s) {return "String[]";}
   public static String type(Object[] lst) {return "Array";}

   public static Object echo(byte b) {
      System.err.println("byte");
      return b;
   }

   public static Object echo(char c) {
      System.err.println("char");
      return c;
   }

   public static Object echo(short s) {
      System.err.println("short");
      return s;
   }

   public static Object echo(int i) {
      System.err.println("int");
      return i;
   }

   public static Object echo(long n) {
      System.err.println("long");
      return n;
   }

   public static Object echo(double d) {
      System.err.println("double");
      return d;
   }

   public static byte[] echo(byte[] lst) {
      System.err.println("byte[]");
      return lst;
   }

   public static int[] echo(int[] lst) {
      System.err.println("init[]");
      return lst;
   }

   public static double[] echo(double[] s) {
      System.err.println("double[]");
      return s;
   }

   public static String[] echo(String[] s) {
      System.err.println("String[]");
      return s;
   }

   public static Object echo(Object x) {
      System.err.println("Object");
      return x;
   }

   public static BigInteger add(BigInteger a, BigInteger b) {
      return a.add(b);
   }

   public static BigInteger md5(String msg) throws Exception {
      return new BigInteger(MessageDigest.getInstance("MD5").digest(msg.getBytes()));
   }
/**/

(java (public "java.lang.System" "err") 'println "Hello world")

(test "boolean" (java "Test" 'type T))
(test "boolean" (java "Test" 'type NIL))
(test "byte" (java "Test" 'type (1 . 42)))
(test "char" (java "Test" 'type (2 . 42)))
(test "short" (java "Test" 'type (3 . 42)))
(test "int" (java "Test" 'type 123))
(test "int" (java "Test" 'type (4 . 123)))
(test "long" (java "Test" 'type (8 . 123)))
(test "double" (java "Test" 'type (-3 . 123456)))
(test "big" (java "Test" 'type (9 . 123)))
(test "String" (java "Test" 'type "String"))
(test "byte[]" (java "Test" 'type '((1 . 1) (1 . 2) (1 . 3))))
(test "int[]" (java "Test" 'type (1 2 3)))
(test "double[]" (java "Test" 'type '((-1 . 1) (-2 . 2) (-3 . 3))))
(test "String[]" (java "Test" 'type '("abc" "def" "ghi")))
(test "Array" (java "Test" 'type (1 a "b")))

(with (java "Test" T "Fred" 7)
   (test "Fred" (: Name))
   (test This (: Val))
   (test 7 (: Cnt)) )

(test 7 (java "Test" 'add (9 . 3) (9 . 4)))

(test 24691357802469135780 (java "Test" 'add 12345678901234567890 12345678901234567890))
(test 87704939138141002822102625569266896500 (java "Test" 'md5 "This is a string"))

# vi:et:ts=3:sw=3
