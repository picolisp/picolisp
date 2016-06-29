// 28jun16abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.util.*;
import java.math.*;
import java.lang.reflect.*;

public class InOut {
   public InputStream In;
   public OutputStream Out;
   final static Boolean T = new Boolean(Boolean.TRUE);
   final static Boolean Nil = new Boolean(Boolean.FALSE);
   final static HashMap<Integer,Object> Obj = new HashMap<Integer,Object>();

   private int InCount;
   private boolean InMore;

   static final int NIX = 0;
   static final int BEG = 1;
   static final int DOT = 2;
   static final int END = 3;

   static final int NUMBER    = 0;
   static final int INTERN    = 1;
   static final int TRANSIENT = 2;
   static final int EXTERN    = 3;

   public InOut(InputStream in, OutputStream out) {
      In = in;
      Out = new BufferedOutputStream(out);
   }

   public void close() throws IOException {
      In.close();
      Out.close();
   }

   /*** Printing ***/
   public void flush() throws IOException {Out.flush();}

   private void outBytes(int t, byte[] b) throws IOException {
      int i, j, cnt;

      i = 0;
      if ((cnt = b.length) < 63) {
         Out.write(cnt*4 | t);
         do
            Out.write(b[i++]);
         while (--cnt > 0);
      }
      else {
         Out.write(63*4 | t);
         for (j = 0; j < 63; ++j)
            Out.write(b[i++]);
         cnt -= 63;
         while (cnt >= 255) {
            Out.write(255);
            for (j = 0; j < 255; ++j)
               Out.write(b[i++]);
            cnt -= 255;
         }
         Out.write(cnt);
         while (--cnt >= 0)
            Out.write(b[i++]);
      }
   }

   private void prNum(int t, long n) throws IOException {
      long m = n;
      int cnt;

      for (cnt = 1; (m >>>= 8) != 0; ++cnt);
      Out.write(cnt * 4 + t);
      do {
         Out.write((byte)n);
         n >>>= 8;
      } while (--cnt != 0);
   }

   public static int utfLength(String s) {
      int n = 0;
      int i = s.length();
      while (--i >= 0) {
         if (s.charAt(i) < 0x80)
            ++n;
         else if (s.charAt(i) < 0x800)
            n += 2;
         else
            n += 3;
      }
      return n;
   }

   public void prSym(String s) throws IOException {print(INTERN, s);}

   public void print(String s) throws IOException {print(TRANSIENT, s);}

   public void print(int t, String s) throws IOException {
      int c, i, j;

      if (s.length() == 0)
         Out.write(NIX);
      else {
         byte[] b = new byte[utfLength(s)];

         for (i = j = 0; i < s.length(); ++i) {
            if ((c = s.charAt(i)) < 0x80)
               b[j++] = (byte)c;
            else if (c < 0x800) {
               b[j++] = (byte)(0xC0 | c>>6 & 0x1F);
               b[j++] = (byte)(0x80 | c & 0x3F);
            }
            else {
               b[j++] = (byte)(0xE0 | c>>12 & 0x0F);
               b[j++] = (byte)(0x80 | c>>6 & 0x3F);
               b[j++] = (byte)(0x80 | c & 0x3F);
            }
         }
         outBytes(t, b);
      }
   }

   public void print(long n) throws IOException {
      prNum(NUMBER,  n >= 0? n * 2 : -n * 2 + 1);
   }

   public void print(BigInteger big) throws IOException {
      boolean sign;
      if (sign = (big.signum() < 0))
         big = big.abs();
      int i = 0;
      byte[] buf = big.toByteArray();
      int j = buf.length;
      byte[] b = new byte[j];
      for (;;) {
         b[--j] = (byte)(buf[i++] << 1);
         if (j == 0)
            break;
         if ((buf[i] & 0x80) != 0)
            b[j] |= 1;
      }
      if (sign)
         b[0] |= 1;
      outBytes(NUMBER, b);
   }

   public void print(Object x) throws IOException {
      if (x == null)
         Out.write(NIX);
      else if (x instanceof String)
         print((String)x);
      else if (x instanceof Symbol)
         prSym(((Symbol)x).Name);
      else if (x instanceof BigInteger)
         print((BigInteger)x);
      else if (x instanceof Double)
         print((long)(((Double)x).doubleValue() * 1000000.0));
      else if (x instanceof Long)
         print(((Long)x).longValue());
      else if (x instanceof Number)  // Byte, Integer, Short
         print((long)((Number)x).intValue());
      else if (x instanceof Character)
         print((long)((Character)x).charValue());
      else if (x instanceof Boolean) {
         if (((Boolean)x).booleanValue())
            prSym("T");
         else
            Out.write(NIX);
      }
      else if (x instanceof int[]) {
         if (((int[])x).length == 0)
            Out.write(NIX);
         else {
            Out.write(BEG);
            for (int i = 0;  i < ((int[])x).length;  ++i)
               print(((int[])x)[i]);
            Out.write(END);
         }
      }
      else if (x instanceof byte[]) {
         if (((byte[])x).length == 0)
            Out.write(NIX);
         else {
            Out.write(BEG);
            for (int i = 0;  i < ((byte[])x).length;  ++i)
               print(((byte[])x)[i]);
            Out.write(END);
         }
      }
      else if (x instanceof double[]) {
         if (((double[])x).length == 0)
            Out.write(NIX);
         else {
            Out.write(BEG);
            for (int i = 0;  i < ((double[])x).length;  ++i)
               print(((double[])x)[i]);
            Out.write(END);
         }
      }
      else if (x instanceof Object[]) {
         if (((Object[])x).length == 0)
            Out.write(NIX);
         else {
            Out.write(BEG);
            for (int i = 0;  i < ((Object[])x).length;  ++i)
               print(((Object[])x)[i]);
            Out.write(END);
         }
      }
      else {
         int i = x.hashCode();
         Obj.put(i, x);
         prNum(EXTERN, (long)i & 0xFFFFF | (long)(i & 0xFFF00000) << 8);
      }
   }

   /*** Reading ***/
   private int inByte1() throws IOException {
      int c;

      if ((c = In.read()) < 0)
         return -1;
      InMore = (InCount = c / 4 - 1) == 62;
      return c;
   }

   private int inByte() throws IOException {
      if (InCount == 0) {
         if (!InMore  ||  (InCount = In.read()) <= 0)
            return -1;
         InMore = InCount == 255;
      }
      --InCount;
      return In.read();
   }

   private String getStr() throws IOException {
      int c = In.read();
      StringBuffer str = new StringBuffer();
      do {
         if ((c & 0x80) != 0) {
            if ((c & 0x20) == 0)
               c &= 0x1F;
            else
               c = (c & 0xF) << 6 | inByte() & 0x3F;
            c = c << 6 | inByte() & 0x3F;
         }
         str.append((char)c);
      } while ((c = inByte()) >= 0);
      return str.toString();
   }

   private BigInteger getBig() throws IOException {
      int c, i;
      boolean sign;
      byte[] buf, b;

      sign = ((c = In.read()) & 1) != 0;
      buf = new byte[i = 63];
      for (;;) {
         buf[--i] = (byte)(c >> 1 & 0x7F);
         if ((c = inByte()) < 0)
            break;
         if ((c & 1) != 0)
            buf[i] |= 0x80;
         if (i == 0) {
            b = new byte[buf.length + 255];
            System.arraycopy(buf, 0, b, 255, buf.length);
            buf = b;
            i = 255;
         }
      }
      if (i == 0)
         b = buf;
      else {
         b = new byte[buf.length - i];
         System.arraycopy(buf, i, b, 0, b.length);
      }
      return sign? new BigInteger(-1,b) : new BigInteger(b);
   }

   // Read 32-bit number
   public int rdNum() throws IOException {
      int i, n;

      if ((n = inByte1()) < 0)
         throw new EOFException();
      if (n <= END  ||  (n & 3) != NUMBER)
         throw new IOException("Number expected");
      i = 0;
      n = In.read();
      while (--InCount >= 0)
         n |= In.read() << (i += 8);
      i = n & 1;
      n >>>= 1;
      return i == 0? n : -n;
   }

   // Read string
   public String rdStr() throws IOException {
      int c;

      if ((c = inByte1()) < 0)
         throw new EOFException();
      if (c == NIX)
         return "";
      if (c <= END)
         throw new IOException("String expected");
      if ((c & 3) == NUMBER)
         return getBig().toString();
      return getStr();
   }

   // Read BigInteger
   public BigInteger rdBig() throws IOException {
      int c;

      if ((c = inByte1()) < 0)
         throw new EOFException();
      if (c <= END  ||  (c & 3) != NUMBER)
         throw new IOException("Number expected");
      return getBig();
   }

   // Read expression
   private Object read1(int c) throws IOException {
      if ((c & ~3) != 0) {  // Atom
         if ((c & 3) == NUMBER) {
            BigInteger n = getBig();
            if (n.bitLength() < 32)
               return new Integer(n.intValue());
            return n;
         }
         if ((c & 3) == EXTERN) {
            int i = 0;
            long n = (long)In.read();
            while (--InCount >= 0)
               n |= (long)In.read() << (i += 8);
            return Obj.get((int)n & 0xFFFFF | (int)(n >> 8 & 0xFFF00000));
         }
         String s = getStr();
         if ((c & 3) == INTERN) {
            if (s.equals("T"))
               return T;
            return new Symbol(s);
         }
         return s;
      }
      if (c == NIX)
         return Nil;
      if (c != BEG)  // DOT or END
         return null;
      Object x = read();
      if ((c = inByte1()) == DOT) {  // (cnt . num)
         int n = (Integer)x;
         if (n <= 0) {
            double d = rdBig().doubleValue();
            while (++n <= 0)
               d /= 10;
            return new Double(d);
         }
         else
            switch(n) {
            case 1: return new Byte((byte)rdNum());
            case 2: return new Character((char)rdNum());
            case 3: return new Short((short)rdNum());
            case 4: return rdNum();
            case 8: return new Long(rdBig().longValue());
            case 9: return rdBig();
            default: return null;
            }
      }
      Vector<Object> v = new Vector<Object>();
      v.addElement(x);
      while (c != END) {
         v.addElement(read1(c));
         if ((c = inByte1()) == DOT)
            return null;
      }
      int i = 0;
      if (x instanceof Integer) {
         do {
            if (++i == v.size()) {
               int[] res = new int[v.size()];
               while (--i >= 0)
                  Array.setInt(res, i, (Integer)v.get(i));
               return res;
            }
         } while (v.get(i) instanceof Integer);
      }
      if (x instanceof String) {
         do {
            if (++i == v.size()) {
               String[] res = new String[v.size()];
               while (--i >= 0)
                  res[i] = (String)v.get(i);
               return res;
            }
         } while (v.get(i) instanceof String);
      }
      else if (x instanceof Byte) {
         do {
            if (++i == v.size()) {
               byte[] res = new byte[v.size()];
               while (--i >= 0)
                  Array.setByte(res, i, (Byte)v.get(i));
               return res;
            }
         } while (v.get(i) instanceof Byte);
      }
      else if (x instanceof Double) {
         do {
            if (++i == v.size()) {
               double[] res = new double[v.size()];
               while (--i >= 0)
                  Array.setDouble(res, i, (Double)v.get(i));
               return res;
            }
         } while (v.get(i) instanceof Double);
      }
      Object[] res = new Object[v.size()];
      v.copyInto(res);
      return res;
   }

   public Object read() throws IOException {
      int c;

      if ((c = inByte1()) < 0)
         throw new EOFException();
      return read1(c);
   }
}

class Symbol {
   String Name;

   Symbol(String nm) {
      Name = nm;
   }

   final public String toString() {
      return Name;
   }
}
