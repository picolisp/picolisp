// 12dec03abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.net.*;
import java.util.*;
import java.math.*;
import javax.comm.*;

// Remote Control
public class Tele {
   Socket Sock;
   InOut IO;
   InputStream In;
   OutputStream Out;

   public static void main(String[] arg) {
      if (arg.length < 2)
         giveup("Usage: java Tele <host>  <port> <dev> ..  [<port>]");
      try {
         for (int i = 2; i <= arg.length; i += 2)
            new Tele(arg[0],
                  Integer.parseInt(arg[i-1]),
                  i==arg.length? null : arg[i] );
      }
      catch (Exception e) {giveup(e.toString());}
   }

   public Tele(String host, int port, String dev) throws Exception {
      Sock = new Socket(host, port);
      IO = new InOut(Sock.getInputStream(), Sock.getOutputStream());
      if (dev == null) {
         (new Thread() {
            public void run() {
               try {
                  for (;;) {
                     int n;
                     Object[] lst = (Object[])IO.read();

                     if (lst == null)
                        System.exit(0);

                     String[] cmd = new String[n = lst.length];

                     while (--n >= 0)
                        cmd[n] = (lst[n] instanceof String)?
                           (String)lst[n] : ((BigInteger)lst[n]).toString();

                     Process p = Runtime.getRuntime().exec(cmd);
                     In = p.getInputStream();
                     while ((n = In.read()) >= 0)
                        IO.print(n);
                     IO.flush();
                     p.waitFor();
                  }
               }
               catch (Exception e) {giveup(e.toString());}
            }
         } ).start();
      }
      else {
         if (dev.startsWith("/dev/")) {
            In = new FileInputStream(dev);
            Out = new FileOutputStream(dev);
         }
         else {
            CommPort p = (CommPortIdentifier.getPortIdentifier(dev)).open("Tele", 2000);
            In = p.getInputStream();
            Out = p.getOutputStream();
         }
         (new Thread() {
            public void run() {
               try {
                  int n;

                  while ((n = In.read()) >= 0) {
                     IO.print(n);
                     IO.flush();
                  }
               }
               catch (Exception e) {giveup(e.toString());}
               System.exit(0);
            }
         } ).start();
         (new Thread() {
            public void run() {
               try {
                  Object x;

                  while ((x = IO.read()) != null)
                     if (x instanceof String)
                        Out.write(((String)x).getBytes());
                     else if (x instanceof BigInteger) {
                        byte[] buf = ((BigInteger)x).toByteArray();
                        Out.write(buf[buf.length-1]);
                     }
               }
               catch (Exception e) {giveup(e.toString());}
               System.exit(0);
            }
         } ).start();
      }
   }

	// Error exit
	static void giveup(String msg) {
		System.err.println(msg);
		System.exit(1);
	}
}
