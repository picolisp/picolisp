// 12feb03abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.net.*;
import java.util.*;
import java.math.*;
import java.awt.*;
import java.applet.*;
import java.awt.event.*;

public class Pico extends Applet {
   int ID;
   InOut IO;
   boolean Run;

   static String H, P;
   static Pico[] Apps;
   static Socket Sock;
   static InOut IOS;

   static long Seed;
   static BigInteger InN, InD, OutN;
   static final BigInteger B1 = new BigInteger("1");  // "Global" sync
   static final BigInteger B2 = new BigInteger("2");  // "Thread" sync
   static final BigInteger B3 = new BigInteger("3");
   static final BigInteger B6 = new BigInteger("6");

   static {Seed = System.currentTimeMillis();}

   static void seed(int n) {
      synchronized (B1) {
         if (Seed < 0)
            n ^= 1;
         Seed = Seed << 1 ^ n;
      }
   }

   void connect(int id, String h, String p) {
      if (ID == 0) {
         ID = id;
         addMouseMotionListener(new MouseMotionAdapter() {
            public void mouseMoved(MouseEvent e) {
               seed(e.getX());
               seed(e.getY());
            }
         } );
         synchronized (B1) {
            if (h != null && (!h.equals(H) || !p.equals(P))) {
               if (Sock != null)
                  eof();
               H = h;  P = p;
               try {
                  if ((p = getParameter("gate")) == null)
                     Sock = new Socket(H, Integer.parseInt(P));
                  else {
                     Sock = new Socket(H, Integer.parseInt(p));
                     Sock.getOutputStream().write(("@" + P + " ").getBytes());
                  }
                  IOS = new InOut(Sock.getInputStream(), Sock.getOutputStream());
               }
               catch (IOException e) {showStatus(e.toString());}
               Apps = new Pico[8];
               Apps[id] = this;
               Seed ^= Apps.hashCode();
            }
            else {
               if (id >= Apps.length) {
                  Pico[] a = new Pico[Apps.length*2];
                  System.arraycopy(Apps, 0, a, 0, Apps.length);
                  Apps = a;
               }
               Apps[id] = this;
            }
            IO = IOS;
         }
      }
      Run = true;
      msg1("init>");
   }

   public void init() {
      connect(Integer.parseInt(getParameter("ID")),
                        getDocumentBase().getHost(), getParameter("port") );
   }

   public void start() {
      Run = true;
      msg1("start>");
      (new Thread() {
         public void run() {
            synchronized (B2) {
               while (Run) {
                  try {
                     int n;

                     if ((n = getNum()) == 0)
                        synchronized (IO) {IO.print(0);}
                     else if (n < 0)
                        Apps[-n].done();
                     else {
                        String s = getStr();
                        Pico a = Apps[n];

                        if (a == null)
                           dbg("? " + s);
                        else if (a.Run)
                           a.cmd(s);
                        else
                           a.bad(s);
                     }
                     seed((int)System.currentTimeMillis());
                  }
                  catch (Exception e) {dbg(e.toString());}
               }
            }
         }
      } ).start();
   }

   public void paint(Graphics g) {msg1("paint>");}

   public void stop() {Run = false; msg1("stop>");}

   public void destroy() {msg1("close>");}

   void done() {msg1("T"); Apps[ID] = null; ID = 0;}

   void eof() {
      for (int i = 0; i < Apps.length; ++i)
         if (Apps[i] != null)
            Apps[i].Run = false;
      H = P = null;
      try {Sock.close();}
      catch (IOException f) {}
   }

   // Switch to another URL
   void url(String s, String t) {
      try {getAppletContext().showDocument(new URL(s), t);}
      catch (MalformedURLException e) {dbg(e.toString());}
   }

   // Command dispatcher
   void cmd(String s) {
      if (s.equals("beep"))
         getToolkit().beep();
      else if (s.equals("play"))
         play(getCodeBase(), getStr());
      else if (s.equals("menu"))
         new Popup(this,this);
      else if (s.equals("dialog"))
         new Front(this,getStr());
      else if (s.equals("url"))
         {s = getStr(); url(s,getStr());}
      else if (s.equals("rsa"))
         rsa();
      else
         bye("cmd: " + s);
   }

   void bad(String s) {
      if (s.equals("beep"))
         ;
      else if (s.equals("play"))
         getStr();
      else if (s.equals("menu"))
         Popup.bad(this);
      else if (s.equals("dialog"))
         {getStr(); getNum();}
      else if (s.equals("url"))
         {getStr(); getStr();}
      else if (s.equals("rsa"))
         getBig();
      else
         bye("bad: " + s);
   }

   private BigInteger prime(int len, Random rnd) {
      BigInteger p = new BigInteger(len*2/3, 100, rnd);
      BigInteger r = new BigInteger(len/3, rnd);
      BigInteger k = p.subtract(r).remainder(B3).add(r);
      if (k.testBit(0))
         k = k.add(B3);
      for (;;) {
         r = k.multiply(p).add(B1);
         if (r.isProbablePrime(100))
            return r;
         k = k.add(B6);
      }
   }

   private void rsa() {
      synchronized (B1) {
         int n = (OutN = getBig()).bitLength();
         Random rnd = new Random(Seed);
         BigInteger p = prime(n*5/10, rnd);
         BigInteger q = prime(n*6/10, rnd);
         InN = p.multiply(q);
         InD = B1.add(B2.multiply(p.subtract(B1).multiply(q.subtract(B1)))).divide(B3);
      }
      msg2("rsa>", InN);
   }

   String inCiph() {
      Object[] lst = null;

      try {lst = (Object[])IO.read();}
      catch (IOException e) {bye(e.toString());}
      if (lst == null)
         return "";
      StringBuffer str = new StringBuffer();
      for (int i = 0; i < lst.length; ++i) {
         byte[] buf = ((BigInteger)lst[i]).modPow(InD,InN).toByteArray();
         for (int j = -(buf.length & 1);  j < buf.length;  j += 2) {
            int c = j < 0? 0 : (buf[j] & 0xFF) << 8;
            c += buf[j+1] & 0xFF;
            if (c != 0)
               str.append((char)c);
         }
      }
      return str.toString();
   }

   BigInteger[] outCiph(String s) {
      char chr[] = s.toCharArray();
      int siz = OutN.bitLength()/16/2;
      BigInteger[] res = new BigInteger[(chr.length + siz - 1) / siz];

      int pos = 0;
      for (int i = 0;  i < res.length;  ++i) {
         byte b[] = new byte[siz*2];
         for (int j = 0;  j < siz  &&  pos < chr.length;  ++j) {
            b[2*j] = (byte)(chr[pos] >> 8);
            b[2*j+1] = (byte)chr[pos++];
         }
         res[i] = (new BigInteger(b)).modPow(B3,OutN);
      }
      return res;
   }

   // Write message with id
   void msg1(String s) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   void msg2(String s, Object x2) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.print(x2); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   void msg2(String s, int n2) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.print(n2); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   void msg3(String s, Object x2, Object x3) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.print(x2); IO.print(x3); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   void msg3(String s, int n2, int n3) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.print(n2); IO.print(n3); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   void msg4(String s, int n2, int n3, int n4) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.print(n2); IO.print(n3); IO.print(n4); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   void msg4(String s, int n2, Object x3, int n4) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.print(n2); IO.print(x3); IO.print(n4); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   void msg5(String s, int n2, int n3, int n4, int n5) {
      synchronized (IO) {
         try {IO.prSym(s); IO.print(ID); IO.print(n2); IO.print(n3); IO.print(n4); IO.print(n5); IO.flush();}
         catch (IOException e) {eof();}
      }
   }

   // Read byte array
   byte[] getBytes(int cnt) {
      try {
         byte[] b;

         if ((b = IO.rdBytes(cnt)) == null)
            eof();
         return b;
      }
      catch (IOException e) {bye(e.toString());}
      return null;
   }

   // Read string
   String getStr() {
      try {
         String s;

         if ((s = IO.rdStr()) == null)
            eof();
         return s;
      }
      catch (IOException e) {bye(e.toString());}
      return null;
   }

   // Read 32-bit number
   int getNum() {
      try {return IO.rdNum();}
      catch (EOFException e) {eof();}
      catch (IOException e) {bye(e.toString());}
      return 0;
   }

   // Read BigInteger
   BigInteger getBig() {
      try {
         BigInteger b;

         if ((b = IO.rdBig()) == null)
            eof();
         return b;
      }
      catch (IOException e) {bye(e.toString());}
      return null;
   }

   // Read anything
   Object read() {
      try {return IO.read();}
      catch (IOException e) {bye(e.toString());}
      return null;
   }

   void dbg(String s) {
      synchronized (IO) {
         try {IO.print(s); IO.flush();}
         catch (IOException e) {}
      }
   }

   void bye(String s) {
      synchronized (IO) {
         try {IO.print(s); IO.print(""); IO.flush();}
         catch (IOException e) {}
      }
   }
}
