// 25jun16abu
// (c) Software Lab. Alexander Burger

import java.io.*;
import java.util.*;
import java.math.*;
import java.lang.reflect.*;

// java Reflector fifo/rqst fifo/rply
public class Reflector {
   public static void main(String[] args) throws Exception {
      final InOut io = new InOut(System.in, System.out);
      final InOut rpc = new InOut(new FileInputStream(args[1]), new FileOutputStream(args[0]));

      for (;;) {
         try {
            int i;
            Object x, y, z, lst[];

            while ((lst = (Object[])io.read()) != null) {
               y = lst[1];
               switch((Integer)lst[0]) {
               // (java 'cls 'T ['any ..]) -> obj
               // (java 'cls 'msg ['any ..]) -> obj
               // (java 'obj 'msg ['any ..]) -> obj
               case 0:
                  z = lst[2];
                  i = lst.length-3;
                  Object[] arg = new Object[i];
                  Class[] par = new Class[i];
                  while (--i >= 0) {
                     Object v = lst[i+3];
                     if (v == InOut.T || v == InOut.Nil) {
                        arg[i] = v == InOut.T;
                        par[i] = Boolean.TYPE;
                     }
                     else {
                        arg[i] = v;
                        if (v instanceof Byte)
                           par[i] = Byte.TYPE;
                        else if (v instanceof Character)
                           par[i] = Character.TYPE;
                        else if (v instanceof Short)
                           par[i] = Short.TYPE;
                        else if (v instanceof Integer)
                           par[i] = Integer.TYPE;
                        else if (v instanceof Long)
                           par[i] = Long.TYPE;
                        else if (v instanceof Double)
                           par[i] = Double.TYPE;
                        else
                           par[i] = v.getClass();
                     }
                  }
                  if (z == InOut.T)
                     x = javaConstructor(Class.forName(y.toString()), par).newInstance(arg);
                  else {
                     Method m;
                     if (y instanceof String) {
                        m = javaMethod(Class.forName((String)y), z.toString(), par);
                        x = m.invoke(null, arg);
                     }
                     else {
                        m = javaMethod(y.getClass(), z.toString(), par);
                        x = m.invoke(y, arg);
                     }
                     if (m.getReturnType() == Void.TYPE)
                        x = null;
                  }
                  io.print(x);
                  break;
               // (public 'cls 'any ['any ..]) -> obj
               // (public 'obj 'any ['any ..]) -> obj
               case 1:
                  z = lst[2];
                  if (y instanceof String) {
                     Class cls = Class.forName((String)y);
                     x = cls.getField(z.toString()).get(cls);
                  }
                  else
                     x = y.getClass().getField(z.toString()).get(y);
                  for (i = 3; i < lst.length; ++i)
                     x = x.getClass().getField(lst[i].toString()).get(x);
                  io.print(x);
                  break;
               // (interface 'obj 'cls|lst 'sym 'fun ..) -> obj
               case 2:
                  final Object obj = y;
                  y = lst[2];
                  Class[] c = new Class[y instanceof Object[]? ((Object[])y).length : 1];
                  if (y instanceof Object[])
                     for (i = 0; i < c.length; ++i)
                        c[i] = Class.forName((((Object[])y)[i]).toString());
                  else
                     c[0] = Class.forName(y.toString());
                  InvocationHandler h = new InvocationHandler() {
                     public Object invoke(Object o, Method m, Object[] lst) {
                        String nm = m.getName();
                        switch (nm) {
                        case "equals":
                           return o == lst[0];
                        case "hashCode":
                           return System.identityHashCode(o);
                        case "toString":
                           return o.getClass().getName() + "@" + Integer.toHexString(System.identityHashCode(o));
                        default:
                           try {
                              rpc.print(obj);
                              rpc.prSym(nm);
                              rpc.print(lst);
                              rpc.flush();
                              return rpc.read();
                           }
                           catch (Exception e) {}
                           return null;
                        }
                     }
                  };
                  io.print(Proxy.newProxyInstance(ClassLoader.getSystemClassLoader(), c, h));
                  break;
               // (reflect 'obj) -> [lst lst]
               case 3:
                  Class cls = y instanceof Class? ((Class)y).getSuperclass() : y.getClass();
                  Field[] fld = cls.getDeclaredFields();
                  io.Out.write(InOut.BEG);
                  io.Out.write(InOut.BEG);
                  io.print(cls);
                  io.Out.write(InOut.DOT);
                  io.print(cls.getName());
                  for (i = 0; i < fld.length; ++i) {
                     if (!(y instanceof Class)) {
                        io.Out.write(InOut.BEG);
                        if (fld[i].isAccessible())
                           io.print(fld[i].get(y));
                        else {
                           fld[i].setAccessible(true);
                           io.print(fld[i].get(y));
                           fld[i].setAccessible(false);
                        }
                        io.Out.write(InOut.DOT);
                     }
                     io.prSym(fld[i].getName());
                  }
                  io.Out.write(InOut.END);
                  break;
               default:
                  System.err.println("## " + lst[0] + ": Undefined");
               }
               io.flush();
            }
         }
         catch (EOFException e) {
            io.close();
            rpc.close();
            System.exit(0);
         }
         catch (Exception e) {
            System.err.println("## " + e.getCause() == null? e : e.getCause());
            io.Out.write(InOut.NIX);
            io.flush();
            while (io.In.available() > 0)
               io.In.read();
            rpc.Out.write(InOut.NIX);
            rpc.flush();
            while (rpc.In.available() > 0)
               rpc.In.read();
         }
      }
   }

   final static Constructor javaConstructor(Class cls, Class[] par) throws NoSuchMethodException {
   looking:
      for (Constructor m : cls.getConstructors()) {
         Class<?>[] types = m.getParameterTypes();
         if (types.length == par.length) {
            for (int i = 0; i < types.length; ++i)
               if (!(types[i].isAssignableFrom(par[i])))
                  continue looking;
            return m;
         }
      }
      throw new NoSuchMethodException();
   }

   final static Method javaMethod(Class cls, String nm, Class[] par)  throws NoSuchMethodException {
   looking:
      for (Method m : cls.getMethods()) {
         if (m.getName().equals(nm)) {
            Class<?>[] types = m.getParameterTypes();
            if (types.length == par.length) {
               for (int i = 0; i < types.length; ++i)
                  if (!(types[i].isAssignableFrom(par[i])))
                     continue looking;
               return m;
            }
         }
      }
      throw new NoSuchMethodException(nm + "(" + par + ")");
   }
}
