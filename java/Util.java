// 01mar01abu
// (c) Software Lab. Alexander Burger

import java.util.*;
import java.math.*;
import java.security.*;

public class Util {
   // (java "Util" "test")
   public static String test() {return "Ok";}

   // (java "Util" "add" (3 4))
   public static BigInteger add(BigInteger a, BigInteger b) {
      return a.add(b);
   }

   // (java "Util" "md5" "This is a string")
   public static Object md5(String msg) throws Exception {
      return new BigInteger(MessageDigest.getInstance("MD5").digest(msg.getBytes()));
   }
}
