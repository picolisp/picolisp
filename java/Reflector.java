// 01may07abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.util.*;
import java.lang.reflect.*;

public class Reflector extends Thread {
   String Fifo, Cls, Foo;
   Object Obj;
   Object[] Args;
   InOut IO;

   // java Reflector <fifo>
   public static void main(String[] arg) throws Exception {
      InOut io = new InOut(new FileInputStream(arg[0]), new FileOutputStream(arg[0]));
      for (;;)
         new Reflector(io).start();
   }

   Reflector(InOut io) throws IOException {
      Fifo = io.rdStr();
      Cls = io.rdStr();
      if ((Obj = io.read()) instanceof String)
         Foo = (String)Obj;   // Invoke static function
      else
         Foo = io.rdStr();    // Invoke method on a new Object
      Args = (Object[])io.read();
      IO = new InOut(null, new FileOutputStream(Fifo));
   }

   public void run() {
      Class cls;
      Object[] args;
      Class[] par;

      try {
         cls = Class.forName(Cls);
         if (Obj instanceof String)
            Obj = null;
         else {
            if (Obj == null)
               Obj = cls.newInstance();
            else {
               args = (Object[])Obj;
               par = new Class[args.length];
               for (int i = 0; i < args.length; ++i) {
                  if (args[i] == null)
                     args[i] = "";
                  par[i] = args[i].getClass();
               }

               Obj = cls.getConstructor(par).newInstance(args);
            }
         }

         if (Args == null)
            par = null;
         else {
            par = new Class[Args.length];
            for (int i = 0; i < Args.length; ++i) {
               if (Args[i] == null)
                  Args[i] = "";
               par[i] = Args[i].getClass();
            }
         }
         Object res = cls.getMethod(Foo,par).invoke(Obj,Args);
         IO.prSym("T");
         IO.print(res);
         IO.Out.close();
      }
      catch (Exception e) {
         try {
            IO.prSym("");
            IO.print(e.toString());
            IO.Out.close();
         }
         catch (IOException e2) {System.err.println(e2);}
      }
   }
}
