// 19apr04abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.net.*;
import java.util.*;
import java.math.*;
import java.awt.*;
import java.applet.*;
import java.awt.event.*;

public class Pico extends Applet {
   String Host;
   Socket Sock;
   InOut IO;
   boolean Rdy, MiSt;

   long Seed;
   BigInteger InN, InD, OutN;
   static final BigInteger B1 = new BigInteger("1");
   static final BigInteger B2 = new BigInteger("2");
   static final BigInteger B3 = new BigInteger("3");
   static final BigInteger B6 = new BigInteger("6");

   void seed(int n) {
      if (Seed < 0)
         n ^= 1;
      Seed = Seed << 1 ^ n;
   }

   void connect(int id, int port, String gate, String sid) {
      addMouseMotionListener(new MouseMotionAdapter() {
         public void mouseMoved(MouseEvent e) {
            seed(e.getX());
            seed(e.getY());
         }
      } );
      MiSt = System.getProperty("java.vendor").startsWith("Microsoft");
      try {
         if (gate.length() == 0)
            Sock = new Socket(Host, port);
         else {
            Sock = new Socket(Host, Integer.parseInt(gate));
            Sock.getOutputStream().write(("@" + port + " ").getBytes());
         }
         IO = new InOut(Sock.getInputStream(), Sock.getOutputStream());
         IO.print(sid);
         if (id != 0)
            IO.print(id);
      }
      catch (IOException e) {showStatus(e.toString());}
      Seed ^= IO.hashCode();
      if (!Rdy)
         msg1("init>");
      msg1("start>");
      (new Thread() {
         public void run() {
            try {
               while (Sock != null) {
                  cmd(getStr());
                  seed((int)System.currentTimeMillis());
               }
            }
            catch (Exception e) {done();}
         }
      } ).start();
   }

   public void init() {
      setFont(new Font(getParameter("font"), Font.PLAIN, Integer.parseInt(getParameter("size"))));
      Seed = System.currentTimeMillis() ^ Long.parseLong(getParameter("rand"));
      Host = getDocumentBase().getHost();
   }

   public void start() {
      if (Sock == null)
         connect(Integer.parseInt(getParameter("ID")),
               Integer.parseInt(getParameter("port")),
               getParameter("gate"),
               getParameter("sid") );
   }

   public void stop() {msg1("stop>");}

   public void paint(Graphics g) {msg1("paint>");}

   void done() {
      if (Sock != null) {
         try {Sock.close();}
         catch (IOException f) {}
         Sock = null;
      }
   }

   // Switch to another URL
   void url(String s, String t) {
      try {getAppletContext().showDocument(new URL(s), t);}
      catch (MalformedURLException e) {dbg(e.toString());}
   }

   // Command dispatcher
   synchronized void cmd(String s) {
      if (s.equals("ping")) {
         try {IO.print(0);}
         catch (IOException e) {}
      }
      else if (s.equals("done"))
         done();
      else if (s.equals("beep"))
         getToolkit().beep();
      else if (s.equals("play"))
         play(getCodeBase(), getStr());
      else if (s.equals("menu"))
         new Popup(this,this);
      else if (s.equals("url"))
         {s = getStr(); url(s,getStr());}
      else if (s.equals("rsa"))
         rsa();
      else {
         dbg("cmd: " + s);
         done();
      }
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
      int n = (OutN = getBig()).bitLength();
      Random rnd = new Random(Seed);
      BigInteger p = prime(n*5/10, rnd);
      BigInteger q = prime(n*6/10, rnd);
      InN = p.multiply(q);
      InD = B1.add(B2.multiply(p.subtract(B1).multiply(q.subtract(B1)))).divide(B3);
      msg2("rsa>", InN);
   }

   String inCiph() {
      Object[] lst = null;

      try {lst = (Object[])IO.read();}
      catch (IOException e) {done();}
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

   // Write message
   synchronized void msg1(String s) {
      try {IO.prSym(s); IO.flush();}
      catch (IOException e) {done();}
   }

   synchronized void msg2(String s, Object x2) {
      try {IO.prSym(s); IO.print(x2); IO.flush();}
      catch (IOException e) {done();}
   }

   synchronized void msg2(String s, int n2) {
      try {IO.prSym(s); IO.print(n2); IO.flush();}
      catch (IOException e) {done();}
   }

   synchronized void msg3(String s, Object x2, Object x3) {
      try {IO.prSym(s); IO.print(x2); IO.print(x3); IO.flush();}
      catch (IOException e) {done();}
   }

   synchronized void msg3(String s, int n2, int n3) {
      try {IO.prSym(s); IO.print(n2); IO.print(n3); IO.flush();}
      catch (IOException e) {done();}
   }

   synchronized void msg4(String s, int n2, int n3, int n4) {
      try {IO.prSym(s); IO.print(n2); IO.print(n3); IO.print(n4); IO.flush();}
      catch (IOException e) {done();}
   }

   synchronized void msg4(String s, int n2, Object x3, int n4) {
      try {IO.prSym(s); IO.print(n2); IO.print(x3); IO.print(n4); IO.flush();}
      catch (IOException e) {done();}
   }

   synchronized void msg5(String s, int n2, int n3, int n4, int n5) {
      try {IO.prSym(s); IO.print(n2); IO.print(n3); IO.print(n4); IO.print(n5); IO.flush();}
      catch (IOException e) {done();}
   }

   // Read byte array
   byte[] getBytes(int cnt) {
      try {
         byte[] b;

         if ((b = IO.rdBytes(cnt)) != null)
            return b;
      }
      catch (IOException e) {}
      done();
      return null;
   }

   // Read string
   String getStr() {
      try {
         String s;

         if ((s = IO.rdStr()) != null)
            return s;
      }
      catch (IOException e) {}
      done();
      return null;
   }

   // Read 32-bit number
   int getNum() {
      try {return IO.rdNum();}
      catch (IOException e) {}
      done();
      return 0;
   }

   // Read BigInteger
   BigInteger getBig() {
      try {
         BigInteger b;

         if ((b = IO.rdBig()) != null)
            return b;
      }
      catch (IOException e) {}
      done();
      return null;
   }

   // Read anything
   Object read() {
      try {return IO.read();}
      catch (IOException e) {}
      done();
      return null;
   }

   synchronized void dbg(String s) {
      try {IO.print(s); IO.flush();}
      catch (IOException e) {}
   }
}
