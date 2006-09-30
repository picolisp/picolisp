// 05aug06abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.net.*;
import java.util.*;
import java.math.*;
import javax.comm.*;

// Remote Control
public class Tele {
   CommPort Device;
   InputStream NetIn, DevIn;
   OutputStream NetOut, DevOut;
   static byte Pw[];
   ServerSocket Server;
   Thread RdThread, WrThread;

   public static void main(String[] arg) {
      if (arg.length < 3)
         giveup("Usage: java Tele <pw> [<host>]  <port> <dev>  ..");
      try {
         Pw = arg[0].getBytes();
         if (arg[1].length() <= 5)
            for (int i = 1; i < arg.length; i += 2)
               new Tele(Integer.parseInt(arg[i]), arg[i+1]);
         else
            for (int i = 2; i < arg.length; i += 2)
               new Tele(arg[1], Integer.parseInt(arg[i]), arg[i+1]);
      }
      catch (Exception e) {giveup(e.toString());}
   }

   public Tele(String host, int port, String dev) throws Exception {
      tele(host, port, dev);
   }

   public Tele(final int port, final String dev) throws Exception {
      Server = new ServerSocket(port);
      (new Thread() {
         public void run() {
            for (;;) {
               try {
                  if (tele(null, port, dev)) {
                     if (RdThread != null)
                        RdThread.join();
                     if (WrThread != null)
                        WrThread.join();
                  }
               }
               catch (Exception e) {}
            }
         }
      } ).start();
   }

   private boolean tele(String host, int port, String dev) {
      try {
         Socket sock;

         if (host != null)
            sock = new Socket(host, port);
         else
            sock = Server.accept();

         NetIn = sock.getInputStream();
         NetOut = new BufferedOutputStream(sock.getOutputStream());

         if (host != null) {
            NetOut.write(Pw);
            NetOut.write('\n');
         }
         else {
            for (int i = 0; i < Pw.length; ++i)
               if (NetIn.read() != Pw[i])
                  throw new Exception();
         }
      }
      catch (Exception e) {
         closeNet();
         return false;
      }
      try {
         if (dev.startsWith("/dev/")) {
            DevIn = new FileInputStream(dev);
            DevOut = new BufferedOutputStream(new FileOutputStream(dev));
         }
         else {
            Device = (CommPortIdentifier.getPortIdentifier(dev)).open("Tele", 2000);
            DevIn = Device.getInputStream();
            DevOut = Device.getOutputStream();
         }
      }
      catch (Exception e) {giveup(e.toString());}
      if (DevIn != null)
         (RdThread = new Thread() {
            public void run() {
               try {
                  byte buf[] = new byte[8192];
                  int n;

                  while ((n = DevIn.read(buf)) >= 0) {
                     NetOut.write(buf, 0, n);
                     NetOut.flush();
                  }
               }
               catch (IOException e) {}
               catch (Exception e) {giveup(e.toString());}
               closeNet();
               closeDev();
            }
         } ).start();
      if (DevOut != null)
         (WrThread = new Thread() {
            public void run() {
               try {
                  byte buf[] = new byte[8192];
                  int n;

                  while ((n = NetIn.read(buf)) >= 0) {
                     DevOut.write(buf, 0, n);
                     DevOut.flush();
                  }
               }
               catch (IOException e) {}
               catch (Exception e) {giveup(e.toString());}
               closeNet();
               closeDev();
            }
         } ).start();
      return true;
   }

   private void closeNet() {
      try {NetIn.close();}
      catch (IOException e) {}
      try {NetOut.close();}
      catch (IOException e) {}
   }

   private void closeDev() {
      if (DevIn != null) {
         try {DevIn.close();}
         catch (IOException e) {}
      }
      if (DevOut != null) {
         try {DevOut.close();}
         catch (IOException e) {}
      }
      if (Device != null)
         Device.close();
   }

	// Error exit
	static void giveup(String msg) {
		System.err.println(msg);
		System.exit(1);
	}
}
