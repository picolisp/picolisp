// 05sep00abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.util.*;
import java.lang.reflect.*;

public class Reflector extends Thread {
   String Fifo, Cls, Foo;
   Object Arg;

   // java Reflector <fifo>
   public static void main(String[] arg) throws Exception {
      InOut io = new InOut(new FileInputStream(arg[0]), new FileOutputStream(arg[0]));
      for (;;)
         new Reflector(io).start();
   }

   Reflector(InOut io) throws IOException {
      Fifo = io.rdStr();
      Cls = io.rdStr();
      Foo = io.rdStr();
      Arg = io.read();
   }

   public void run() {
      InOut io = null;

      try {  // Invoke static method 'Foo' in class 'Cls'
         Object[] arg;
         Class[] par;

         if (Arg == null) {
            arg = null;
            par = null;
         }
         else if (Arg instanceof Object[]) {
            arg = (Object[])Arg;
            par = new Class[arg.length];
            for (int i = 0; i < arg.length; ++i)
               par[i] = arg[i]==null?  arg.getClass() : arg[i].getClass();
         }
         else {
            arg = new Object[1];
            par = new Class[1];
            arg[0] = Arg;
            par[0] = Arg.getClass();
         }
         Object res = Class.forName(Cls).getMethod(Foo,par).invoke(null,arg);
         io = new InOut(null, new FileOutputStream(Fifo));
         io.print(res);
         io.flush();
      }
      catch (Exception e) {
         System.err.println(e);
         try {
            if (io == null)
               io = new InOut(null, new FileOutputStream(Fifo));
            io.print(e.toString());
            io.flush();
         }
         catch (IOException e2) {System.err.println(e2);}
      }
   }
}
