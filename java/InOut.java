// 28oct05abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.util.*;
import java.math.*;

public class InOut {
   public InputStream In;
   public OutputStream Out;

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
      Out = out;
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

   public void print(String s) throws IOException {print(TRANSIENT, s);}
   public void prSym(String s) throws IOException {print(INTERN, s);}

   public void print(int t, String s) throws IOException {
      int c, i, j;

      if (s.length() == 0)
         Out.write(NIX);
      else {
         byte b[] = new byte[utfLength(s)];

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

   public void print(int n) throws IOException {
      n = n >= 0? n * 2 : -n * 2 + 1;
      if ((n & 0xFFFFFF00) == 0) {
         Out.write(1*4);
         Out.write(n);
      }
      else if ((n & 0xFFFF0000) == 0) {
         Out.write(2*4);
         Out.write(n);
         Out.write(n>>8);
      }
      else if ((n & 0xFF000000) == 0) {
         Out.write(3*4);
         Out.write(n);
         Out.write(n>>8);
         Out.write(n>>16);
      }
      else {
         Out.write(4*4);
         Out.write(n);
         Out.write(n>>8);
         Out.write(n>>16);
         Out.write(n>>24);
      }
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
      else if (x instanceof Boolean)
         prSym(((Boolean)x).booleanValue()? "T" : "");
      else if (x instanceof BigInteger)
         print((BigInteger)x);
      else if (x instanceof String)
         print((String)x);
      else {
         Out.write(BEG);
         for (int i = 0;  i < ((Object[])x).length;  ++i)
            print(((Object[])x)[i]);
         Out.write(END);
      }
   }

   /*** Reading ***/
	public byte[] rdBytes(int cnt) throws IOException {
		int i, n;

		byte[] b = new byte[cnt];
      for (i = 0;  cnt > 0;  i += n, cnt -= n)
         if ((n = In.read(b,i,cnt)) < 0)
            throw new EOFException();
		return b;
	}

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
      Object x;
      BigInteger n;

      if ((c & ~3) != 0)  // Atom
         return (c & 3) == NUMBER? (Object)getBig() : (Object)getStr();
      if (c != BEG)  // NIX, DOT or END
         return null;
      Vector v = new Vector();
      v.addElement(read());
      while ((c = inByte1()) != END  &&  c != DOT)
         v.addElement(read1(c));
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
