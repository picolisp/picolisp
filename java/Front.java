// 18mar03abu
// (c) Software Lab. Alexander Burger

import java.util.*;
import java.awt.*;
import java.applet.*;
import java.awt.event.*;

public class Front extends Pico {
   GridBagLayout Gridbag;
   Component[] Fields;
   Scrollbar[] SBars;
   Hashtable Skip;
   Vector Sync, Rid, Crypt;
   int Focus, Dirty;
   boolean Req;
   Dialog Dialog;
   final Pico Parent;

   public Front() {Parent = null;}

   public Front(Pico p, String ttl) {
      if ((Parent = p) != null) {
         connect(p.getNum(), null, null);
         Container c = p.getParent();
         while (!(c instanceof Frame))
            c = c.getParent();
         Dialog = new Dialog((Frame)c, ttl, true);
         Dialog.add(this, BorderLayout.CENTER);
         Dialog.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent ev) {stop();}
         } );
      }
   }

   public void stop() {
      change("chg>");
      super.stop();
   }

   void done() {
      if (Dialog != null) {
         Dialog.dispose();
         Dialog = null;
         synchronized (Parent) {Parent.notify();}
      }
      super.done();
   }

   // Switch to another URL
   void url(final String s, final String t) {
      if (Parent == null)
         super.url(s,t);
      else {
         stop();
         (new Thread() {
            public void run() {
               synchronized (Parent) {
                  while (Dialog != null) {
                     try {Parent.wait();}
                     catch (InterruptedException e) {break;}
                  }
               }
               Parent.url(s,t);
            }
         } ).start();
      }
   }

   public AppletContext getAppletContext() {
      return Parent==null? super.getAppletContext() : Parent.getAppletContext();
   }

   // Command dispatcher
   void cmd(String s) {
      if (s.equals("ack"))
         {Req = false; relay();}
      else if (s.equals("focus"))
         focus(getNum());
      else if (s.equals("next"))
         Fields[Focus-1].transferFocus();
      else if (s.equals("text"))
         text(getNum());
      else if (s.equals("type"))
         type(getNum());
      else if (s.equals("feed"))
         feed(getNum());
      else if (s.equals("bCol"))
         bCol(getNum());
      else if (s.equals("fCol"))
         fCol(getNum());
      else if (s.equals("siz"))
         ((DrawField)Fields[getNum()-1]).siz(getNum());
      else if (s.equals("set"))
         ((DrawField)Fields[getNum()-1]).set();
      else if (s.equals("tmp"))
         ((DrawField)Fields[getNum()-1]).tmp();
      else if (s.equals("img"))
         img(getNum());
      else if (s.equals("able"))
         able(getNum());
      else if (s.equals("lock"))
         lock(getStr().length() == 0);
      else if (s.equals("scrl"))
         scrl(getNum());
      else if (s.equals("menu"))
         new Popup(this, Fields[getNum()-1]);
      else if (s.equals("make"))
         make();
      else
         super.cmd(s);
   }

   void bad(String s) {
      int n;

      if (s.equals("ack"))
         Req = false;
      else if (s.equals("focus"))
         getNum();
      else if (s.equals("next"))
         ;
      else if (s.equals("text"))
         {getNum(); read();}
      else if (s.equals("type"))
         {getNum(); read();}
      else if (s.equals("feed"))
         {getNum(); getNum(); read();}
      else if (s.equals("bCol"))
         {getNum(); getNum();}
      else if (s.equals("fCol"))
         {getNum(); getNum();}
      else if (s.equals("siz"))
         {getNum(); getNum();}
      else if (s.equals("set") || s.equals("tmp"))
         getGraf();
      else if (s.equals("img")) {
         getNum();
         if ((n = getNum()) != 0)
            getBytes(n);
      }
      else if (s.equals("able"))
         {getNum(); getStr();}
      else if (s.equals("lock"))
         getStr();
      else if (s.equals("scrl"))
         {getNum(); getNum(); getNum(); getNum();}
      else if (s.equals("menu"))
         {getNum(); Popup.bad(this);}
      else if (s.equals("make")) {
         while ((s = getStr()).length() != 0) {
            if ("*/=:+-".indexOf(s.charAt(0)) < 0) {
               if (s.equals("able"))
                  ;
               else if (s.equals("sync"))
                  ;
               else if (s.equals("bCol"))
                  getNum();
               else if (s.equals("fCol"))
                  getNum();
               else if (s.equals("rid"))
                  ;
               else if (s.equals("crypt"))
                  ;
               else if (s.equals("pw"))
                  ;
               else // Font name
                  getNum();
               continue;
            }
            getStr();
            if ((n = getNum()) > 0) {
               switch(n) {
               case 'B':  // Button
                  getStr();
               case 'c':  // Check box
                  break;
               case 'C':  // Choice box
                  n = getNum();
                  while (--n >= 0)
                     getStr();
                  break;
               case 'L':  // Label
                  getStr();
                  break;
               case 'T':  // TextField
               case 'P':  // PictField
                  getNum(); getNum();
                  break;
               }
            }
         }
      }
      else
         super.bad(s);
   }

   void make() {
      int i, j, k, k2, k3, m, n, p, flgs;
      Vector fld, sb;
      Component f;
      Scrollbar b;
      Panel panel, flow;
      String s;

      fld = new Vector();
      sb = new Vector();
      Sync = new Vector();
      Rid = new Vector();
      Crypt = new Vector();
      i = j = k = k2 = k3 = p = 0;
      f = null;
      b = null;
      panel = flow = null;
      Skip = new Hashtable();
      setLayout(Gridbag = new GridBagLayout());
      while ((s = getStr()).length() != 0) {
         if (s.charAt(0) == '*' || s.charAt(0) == '/') {
            if (panel != null) {
               constrain(this, panel, 0, p++, 1, 1, GridBagConstraints.NONE,
                     GridBagConstraints.NORTHWEST, 6, 1.0, 1.0 );
            }
            panel = new Panel(Gridbag);
            j = k = k2 = 0;
            if (s.charAt(0) == '/') {
               k = k2 = 1;
               b = new Scrollbar(Scrollbar.VERTICAL, 1, 1, 1, 1);
            }
         }
         else if (s.charAt(0) == '=' || s.charAt(0) == ':') {
            j = 0;
            k = k2 = k3;
            if (s.charAt(0) == ':') {
               ++k;
               ++k2;
               b = new Scrollbar(Scrollbar.VERTICAL, 1, 1, 1, 1);
            }
         }
         else if (s.charAt(0) == '+')
            {++j;  k = k2;}
         else if (s.charAt(0) != '-') {
            if (s.charAt(0) == '[') {
               FlowLayout fl = (FlowLayout)(flow = new Panel()).getLayout();
               fl.setAlignment(FlowLayout.LEFT);
               fl.setVgap(0);
               fl.setHgap(0);
            }
            else if (s.charAt(0) == ']') {
               constrain(panel, flow, k++, j, 1, 1, GridBagConstraints.BOTH,
                                 GridBagConstraints.NORTHWEST, 0, 1.0, 1.0 );
               flow = null;
            }
            else if (s.equals("able"))
               able(f,false);
            else if (s.equals("sync"))
               Sync.addElement(f);
            else if (s.equals("bCol"))
               f.setBackground(new Color(getNum()));
            else if (s.equals("fCol"))
               f.setForeground(new Color(getNum()));
            else if (s.equals("rid"))
               Rid.addElement(f);
            else if (s.equals("crypt"))
               Crypt.addElement(f);
            else if (s.equals("pw"))
               ((TextField)f).setEchoChar('*');
            else {  // Font name
               Font fnt = new Font(s, Font.PLAIN, getNum());
               f.setFont(fnt);
               msg3("adv>", i, getFontMetrics(fnt).charWidth('o'));
            }
            continue;
         }

         s = getStr();
         n = getNum();
         if (s.length() > 0)
            constrain(panel,
                  new Label(s, n<=0? Label.LEFT : Label.RIGHT),
                  k++, j, 1, 1,
                  GridBagConstraints.NONE,
                  n==0?  GridBagConstraints.SOUTH :
                     n<0?  GridBagConstraints.WEST : GridBagConstraints.EAST,
                  0, 0.0, 1.0 );
         if (n > 0) {
            if (b != null) {
               b.addAdjustmentListener(new PicoAdjustmentListener(this,i));
               constrain(panel, b, k2-1, 1, 1,
                     GridBagConstraints.REMAINDER,
                     GridBagConstraints.VERTICAL,
                     GridBagConstraints.EAST, 0, 0.0, 1.0 );
            }
            sb.addElement(b);
            b = null;
            switch(n) {
            case 'B':  // Button
               f = new Button(getStr());
               ((Button)f).setActionCommand(Integer.toString(i+1));
               ((Button)f).addActionListener(new ActionListener() {
                  public void actionPerformed(ActionEvent ev) {
                     if (Req)
                        getToolkit().beep();
                     else {
                        change("log>");
                        Req = true;
                        msg2("act>", Integer.parseInt(ev.getActionCommand()));
                     }
                  }
               } );
               break;
            case 'c':  // Check box
               f = new Checkbox();
               ((Checkbox)f).addItemListener(new PicoItemListener(this,i));
               break;
            case 'C':  // Choice box
               f = new Choice();
               n = getNum();
               while (--n >= 0)
                  ((Choice)f).addItem(getStr());
               ((Choice)f).addItemListener(new PicoItemListener(this,i));
               break;
            case 'L':  // Label
               f = new Label(getStr());
               break;
            case 'T':  // TextField
               m = getNum();  // dx
               if ((n = getNum()) == 0)
                  f = new TextField(m);
               else {
                  flgs = TextArea.SCROLLBARS_BOTH;
                  if (m < 0)
                     {m = -m;  flgs |= TextArea.SCROLLBARS_VERTICAL_ONLY;}
                  if (n < 0)
                     {n = -n;  flgs |= TextArea.SCROLLBARS_HORIZONTAL_ONLY;}
                  f = new TextArea("", n, m, flgs);
               }
               f.addMouseListener(new PicoMouseAdapter(this,i));
               break;
            case 'D':  // DrawField
               f = new DrawField(this,i);
               break;
            case 'P':  // PictField
               f = new PictField(this,i);
               break;
            }
            f.addFocusListener(new PicoFocusListener(this,i));
            f.addKeyListener(new PicoKeyAdapter(this,i));
            ++i;
            if (flow != null)
               flow.add(f);
            else
               constrain(panel, f, k++, j, 1, 1, GridBagConstraints.NONE,
                                 GridBagConstraints.NORTHWEST, 0, 1.0, 1.0 );
            fld.addElement(f);
         }
         if (k > k3)
            k3 = k;
      }
      constrain(this, panel, 0, p, 1, 1, GridBagConstraints.NONE,
                              GridBagConstraints.NORTHWEST, 0, 1.0, 1.0 );
      Fields = new Component[fld.size()];
      fld.copyInto(Fields);
      SBars = new Scrollbar[sb.size()];
      sb.copyInto(SBars);
      validate();

      if (Parent != null) {
         Dialog.pack();
         Dimension d = Dialog.getToolkit().getScreenSize();
         Rectangle r = Dialog.getBounds();
         r.x = (d.width - r.width)/2;
         r.y = (d.height - r.height)/2;
         Dialog.setBounds(r);

         (new Thread() {
            public void run() {Dialog.setVisible(true);}
         } ).start();
      }
   }

   // Add component to container
   private static void constrain(Container cont, Component comp, int x, int y,
                                          int w, int h, int fill, int anchor,
                                             int ins, double wx, double wy ) {
      GridBagConstraints c = new GridBagConstraints();

      c.gridx = x;
      c.gridy = y;
      c.gridwidth = w;
      c.gridheight = h;
      c.fill = fill;
      c.anchor = anchor;
      if (ins != 0)
         c.insets = new Insets(ins, ins, ins, ins);
      c.weightx = wx;
      c.weighty = wy;
      ((GridBagLayout)cont.getLayout()).setConstraints(comp,c);
      cont.add(comp);
   }

   // Set focus
   void focus(int fld) {Fields[(Focus = fld)-1].requestFocus();}

   // Set field value
   void text(int fld) {
      Component f = Fields[fld-1];

      String txt = Crypt.contains(f)? inCiph() : getStr();
      if (f instanceof Button)
         ((Button)f).setLabel(txt);
      else if (f instanceof Choice)
         ((Choice)f).select(txt);
      else if (f instanceof Checkbox)
         ((Checkbox)f).setState(txt.length() > 0);
      else if (f instanceof Label)
         ((Label)f).setText(txt);
      else {
         ((TextComponent)f).setText(txt);
         ((TextComponent)f).select(0,0);
      }
   }

   // Type text (string or list of strings) into field
   void type(int fld) {
      Component f = Fields[fld-1];

      Object o = Crypt.contains(f)? inCiph() : read();
      if (f instanceof TextComponent) {
         String txt;

         if (o instanceof String)
            txt = (String)o;
         else {
            StringBuffer buf = new StringBuffer();

            for (int i = 0;  i < ((Object[])o).length;  ++i)
               buf.append((String)((Object[])o)[i]);
            txt = buf.toString();
         }
         int i = ((TextComponent)f).getSelectionStart();
         int j = ((TextComponent)f).getSelectionEnd();
         String s = ((TextComponent)f).getText();

         /*** Bug in Netscape VM? ***/
         if (i > s.length())
            i = s.length();
         if (j > s.length())
            j = s.length();
         /***************************/

         ((TextComponent)f).setText(s.substring(0,i) + txt + s.substring(j));
         if (o instanceof String) {
            ((TextComponent)f).setSelectionStart(i + 1);
            ((TextComponent)f).setSelectionEnd(i + txt.length());
         }
         Dirty = fld;
         if (Sync.contains(Fields[fld-1]))
            change("log>");
      }
   }

   // Feed line to TextArea
   void feed(int fld) {
      Component f = Fields[fld-1];
      String s;
      int n;

      if ((n = getNum()) > 0) {
         s = ((TextArea)f).getText();
         for (int i = 0;  (i = s.indexOf('\n', i)) >= 0;  ++i)
            if (--n == 0) {
               ((TextArea)f).replaceRange("", 0, 1+((TextArea)f).getText().indexOf('\n'));
               break;
            }
      }
      s = Crypt.contains(f)? inCiph() : getStr();
      ((TextArea)f).append(s);
      ((TextArea)f).append("\n");
   }

   // Set background/foreground color
   void bCol(int fld) {(Fields[fld-1]).setBackground(new Color(getNum()));}
   void fCol(int fld) {(Fields[fld-1]).setForeground(new Color(getNum()));}

   // Set image
   void img(int fld) {
      PictField f = (PictField)Fields[fld-1];
      int n = getNum();

      f.Img = n==0? null : getToolkit().createImage(getBytes(n));
      f.repaint();
   }

   // Enable or disable
   void able(int fld) {able(Fields[fld-1], getStr().length() != 0);}

   void able(Component f, boolean a) {
      if (!(f instanceof TextComponent))
         f.setEnabled(a);
      else if (!a)
         Skip.put(f,f);
      else
         Skip.remove(f);
      repaint();
   }

   void lock(boolean a) {
      for (int i = 0;  i < Fields.length;  ++i)
         if (!Rid.contains(Fields[i]))
            able(Fields[i],a);
   }

   // Set scroll bar values
   void scrl(int fld) {
      int val = getNum();
      int vis = getNum();
      if (SBars[fld-1] == null)
         getNum();
      else
         SBars[fld-1].setValues(val, vis, 1, 2+Math.max(vis,getNum()));
   }

   // Signal field value change
   synchronized void change(String msg) {
      if (Dirty != 0) {
         Component f = Fields[Dirty-1];
         String txt;
         int sel;

         if (f instanceof Choice) {
            txt = ((Choice)f).getSelectedItem();
            sel = 0;
         }
         else if (f instanceof Checkbox) {
            txt = ((Checkbox)f).getState()? "T": "";
            sel = 0;
         }
         else {
            txt = ((TextComponent)f).getText();
            if (f instanceof TextField)
               txt = txt.trim();
            else {
               int i = txt.length();
               while (i > 0  &&  txt.charAt(i-1) <= ' ')
                  --i;
               txt = txt.substring(0,i);
            }
            sel = ((TextComponent)f).getSelectionStart();
         }
         if (Crypt.contains(f)  &&  txt.length() != 0)
            msg4(msg, Dirty, outCiph(txt), sel);
         else
            msg4(msg, Dirty, txt, sel);
         Dirty = 0;
         relay();
      }
   }

   // Signal state change
   void relay() {
      if (Parent != null)
         msg1("able>");
      else {
         Enumeration e = getAppletContext().getApplets();
         while (e.hasMoreElements()) {
            Applet a = (Applet)e.nextElement();
            if (a instanceof Front)
               ((Front)a).msg1("able>");
         }
      }
   }

   Graf[] getGraf() {
      int n, i;
      Graf[] lst;

      if ((n = getNum()) == 0)
         return null;
      lst = new Graf[n];
      for (i = 0; i < n; ++i) {
         switch (getNum()) {
         case 'L':
            lst[i] = new GLine(getNum(), getNum(), getNum(), getNum());
            break;
         case 'R':
            lst[i] = new GRect(getNum(), getNum(), getNum(), getNum());
            break;
         case 'O':
            lst[i] = new GOval(getNum(), getNum(), getNum(), getNum());
            break;
         case 'T':
            lst[i] = new GText(getNum(), getNum(), getStr());
            break;
         default:
            dbg("Bad Graf");
         }
      }
      return lst;
   }
}

class PicoItemListener implements ItemListener {
   Front Home;
   int Ix;

   PicoItemListener(Front h, int i) {Home = h; Ix = i+1;}

   public void itemStateChanged(ItemEvent ev) {
      Home.Dirty = Ix;
      Home.Fields[Ix-1].transferFocus();
   }
}

class PicoFocusListener implements FocusListener {
   Front Home;
   int Ix;

   PicoFocusListener(Front h, int i) {Home = h; Ix = i+1;}

   public void focusGained(FocusEvent ev) {
      if (Home.Focus != Ix) {
         Home.msg2("nxt>", Home.Focus = Ix);
         Home.relay();
      }
   }

   public void focusLost(FocusEvent ev) {
      Home.change("log>");
      if (Home.Fields[Ix-1] instanceof TextComponent)
         ((TextComponent)Home.Fields[Ix-1]).select(0,0);
   }
}

class PicoAdjustmentListener implements AdjustmentListener {
   Front Home;
   int Ix, Val;

   PicoAdjustmentListener(Front h, int i) {Home = h; Ix = i+1;}

   public void adjustmentValueChanged(AdjustmentEvent ev) {
      if (Val != ev.getValue()) {
         Home.change("log>");
         Home.msg3("scr>", Ix, Val = ev.getValue());
         Home.relay();
      }
   }
}

class PicoMouseAdapter extends MouseAdapter {
   Front Home;
   int Ix;

   PicoMouseAdapter(Front h, int i) {Home = h; Ix = i+1;}

   public void mousePressed(MouseEvent ev) {
      if (ev.getClickCount() == 2) {
         if (Home.Req)
            Home.getToolkit().beep();
         else {
            Home.change("log>");
            Home.Req = true;
            Home.msg2("act>", Ix);
            ev.consume();
         }
      }
   }
}

class PicoKeyAdapter extends KeyAdapter {
   Front Home;
   int Ix;
   static long Tim;
   static String Clip;

   PicoKeyAdapter(Front h, int i) {Home = h; Ix = i+1;}

   public void keyTyped(KeyEvent ev) {
      char c;
      Component f;

      f = Home.Fields[Ix-1];
      if ((c = ev.getKeyChar()) == KeyEvent.VK_ENTER) {
         Home.change("log>");
         if (!(f instanceof TextArea))
            Home.msg1("ret>");
         else if (Home.Skip.containsKey(f))
            Home.getToolkit().beep();
         else
            key(f, "\n");
         Home.relay();
         ev.consume();
      }
      else if (!Home.Skip.containsKey(f)  &&  f instanceof TextComponent  &&
               c >= KeyEvent.VK_SPACE  &&  c != KeyEvent.VK_DELETE  &&
               !(f instanceof TextField  && ((TextField)f).getEchoChar()=='*') ) {
         if (Home.Sync.contains(f))
            Home.change("chg>");

         long n = System.currentTimeMillis();
         if (Tim > n) {
            try {Thread.currentThread().sleep(Tim - n);}
            catch (InterruptedException e) {}
         }
         Tim = n + 100;

         char[] chr = {c};
         key(f, new String(chr));
         ev.consume();
      }
   }

   public void keyPressed(KeyEvent ev) {
      int m, c, i, j;
      Component f;

      if (((m = ev.getModifiers()) & (InputEvent.META_MASK | InputEvent.ALT_MASK)) != 0) {
         ev.consume();
         return;
      }
      f = Home.Fields[Ix-1];
      switch (c = ev.getKeyCode()) {
      case KeyEvent.VK_SHIFT:
      case KeyEvent.VK_CONTROL:
      case KeyEvent.VK_META:
      case KeyEvent.VK_ALT:
         break;
      case KeyEvent.VK_ESCAPE:
         if (Home.Parent != null)
            Home.stop();
         else
            Home.msg1("esc>");
         ev.consume();
         break;
      case KeyEvent.VK_PAGE_UP:
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof TextArea) {
            i = j = goPgUp((TextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((TextArea)f).getSelectionEnd();
            ((TextArea)f).select(i,j);
         }
         else {
            Home.change("log>");
            Home.msg1("PGUP>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_PAGE_DOWN:
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof TextArea) {
            i = j = goPgDn((TextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((TextArea)f).getSelectionStart();
            ((TextArea)f).select(i,j);
         }
         else {
            Home.change("log>");
            Home.msg1("PGDN>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_END:
         if ((m & InputEvent.CTRL_MASK) != 0) {
            Home.change("log>");
            Home.msg1("END>");
            Home.relay();
         }
         else if (f instanceof TextComponent) {
            i = j = ((TextComponent)f).getText().length();
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((TextComponent)f).getSelectionStart();
            ((TextComponent)f).select(i,j);
         }
         ev.consume();
         break;
      case KeyEvent.VK_HOME:
         if ((m & InputEvent.CTRL_MASK) != 0) {
            Home.change("log>");
            Home.msg1("BEG>");
            Home.relay();
         }
         else if (f instanceof TextComponent) {
            i = j = 0;
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((TextComponent)f).getSelectionEnd();
            ((TextComponent)f).select(i,j);
         }
         ev.consume();
         break;
      case KeyEvent.VK_LEFT:
         if (f instanceof TextComponent) {
            i = j = ((TextComponent)f).getSelectionStart()-1;
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((TextComponent)f).getSelectionEnd();
            ((TextComponent)f).select(i,j);
            ev.consume();
         }
         break;
      case KeyEvent.VK_UP:
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof TextArea) {
            i = j = goUp((TextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((TextArea)f).getSelectionEnd();
            ((TextArea)f).select(i,j);
         }
         else {
            Home.change("log>");
            Home.msg1("UP>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_RIGHT:
         if (f instanceof TextComponent) {
            i = j = ((TextComponent)f).getSelectionEnd()+1;
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((TextComponent)f).getSelectionStart();
            ((TextComponent)f).select(i,j);
            ev.consume();
         }
         break;
      case KeyEvent.VK_DOWN:
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof TextArea) {
            i = j = goDn((TextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((TextArea)f).getSelectionStart();
            ((TextArea)f).select(i,j);
         }
         else {
            Home.change("log>");
            Home.msg1("DN>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_DELETE:
         if (Home.Skip.containsKey(f)) {
            ev.consume();
            Home.getToolkit().beep();
         }
         else if ((m & InputEvent.CTRL_MASK) != 0) {
            Home.change("log>");
            Home.msg1("DEL>");
            Home.relay();
            ev.consume();
         }
         else {
            Home.Dirty = Ix;
            if (f instanceof TextComponent) {
               String s = ((TextComponent)f).getSelectedText();
               if (s.length() != 0)
                  Clip = s;
            }
         }
         break;
      case KeyEvent.VK_INSERT:
         if (Home.Skip.containsKey(f))
            Home.getToolkit().beep();
         else {
            if ((m & InputEvent.CTRL_MASK) != 0) {
               Home.change("log>");
               Home.msg1("INS>");
               Home.relay();
            }
            else if (Clip != null) {
               for (i = 1;  i <= Clip.length();  ++i)
                  key(f, Clip.substring(i-1,i));
            }
         }
         ev.consume();
         break;
      default:
         if (c >= KeyEvent.VK_F1  &&  c <= KeyEvent.VK_F12) {
            Home.change("log>");
            Home.msg1("F" + (1 + c - KeyEvent.VK_F1) + ">");
            Home.relay();
            ev.consume();
         }
         else if (c == KeyEvent.VK_TAB) {
            if (f instanceof TextArea) {
               f.transferFocus();
               ev.consume();
            }
         }
         else if (c == '\r'  ||  c == '\n')
            ev.consume();
         else if (Home.Skip.containsKey(f)) {
            ev.consume();
            Home.getToolkit().beep();
         }
         else if (c < KeyEvent.VK_SPACE  ||
                  f instanceof TextField  && ((TextField)f).getEchoChar()=='*' )
            Home.Dirty = Ix;
         else if (f instanceof TextComponent)
            ev.consume();
      }
   }

   /* Send keystroke */
   private void key(Component f, String s) {
      if (Home.Crypt.contains(f))
         Home.msg2("key>", Home.outCiph(s));
      else
         Home.msg2("key>", s);
   }

   /* TextArea movements */
   private int goUp(TextArea f) {
      int i, j, k;

      String s = f.getText();
      if ((i = f.getSelectionStart()) == 0)
         return 0;
      if ((j = s.lastIndexOf('\n',i-1)) < 0)
         return i;
      return (k = s.lastIndexOf('\n',j-1) + i - j) > j?  j : k;
   }

   private int goDn(TextArea f) {
      int i, j, k;

      String s = f.getText();
      i = f.getSelectionEnd();
      if ((j = s.indexOf('\n',i)) < 0)
         return i;
      i -= s.lastIndexOf('\n',i-1);
      if ((k = s.indexOf('\n',j+1)) < 0)
         k = s.length();
      return Math.min(k, j + i);
   }

   private int goPgUp(TextArea f) {
      int n, i;

      String s = f.getText();
      n = f.getRows()-1;
      for (i = f.getSelectionStart()-1;  n > 0 && i > 0;  --i)
         if (s.charAt(i) == '\n')
            --n;
      return i;
   }

   private int goPgDn(TextArea f) {
      int n, i;

      String s = f.getText();
      n = f.getRows()-1;
      for (i = f.getSelectionEnd();  n > 0 && i < s.length();  ++i)
         if (s.charAt(i) == '\n')
            --n;
      return i;
   }
}

abstract class Graf {
   abstract void draw(Graphics g);
   abstract void mark(Graphics g);

   static void mark(Graphics g, int x, int y) {g.fillRect(x-2, y-2, 4, 4);}

   boolean match(Graf graf) {return false;}
}

class GLine extends Graf {
   int X1, Y1, X2, Y2;

   GLine(int x1, int y1, int x2, int y2) {X1 = x1; Y1 = y1; X2 = x2; Y2 = y2;}

   void draw(Graphics g) {g.drawLine(X1,Y1,X2,Y2);}

   void mark(Graphics g) {
      mark(g, X1, Y1);
      mark(g, X2, Y2);
   }

   boolean match(Graf d) {
      return  d instanceof GLine  &&
            X1 == ((GLine)d).X2  &&  Y1 == ((GLine)d).Y2  &&
                  X2 == ((GLine)d).X1  &&  Y2 == ((GLine)d).Y1;
   }
}

class GRect extends Graf {
   int X, Y, DX, DY;

   GRect(int x, int y, int dx, int dy) {X = x; Y = y; DX = dx; DY = dy;}

   void draw(Graphics g) {g.drawRect(X,Y,DX,DY);}

   void mark(Graphics g) {
      mark(g, X, Y);
      mark(g, X+DX, Y);
      mark(g, X+DX, Y+DY);
      mark(g, X, Y+DY);
   }
}

class GOval extends Graf {
   int X, Y, DX, DY;

   GOval(int x, int y, int dx, int dy) {X = x; Y = y; DX = dx; DY = dy;}

   void draw(Graphics g) {g.drawOval(X,Y,DX,DY);}

   void mark(Graphics g) {
      mark(g, X, Y);
      mark(g, X+DX/2, Y);
      mark(g, X+DX, Y);
      mark(g, X+DX, Y+DY/2);
      mark(g, X+DX, Y+DY);
      mark(g, X+DX/2, Y+DY);
      mark(g, X, Y+DY);
      mark(g, X, Y+DY/2);
   }
}

class GText extends Graf {
   int X, Y;
   String Str;

   GText(int x, int y, String s) {X = x; Y = y; Str = s;}

   void draw(Graphics g) {g.drawString(Str,X,Y);}

   void mark(Graphics g) {
      int w = g.getFontMetrics().stringWidth(Str);
      int a = g.getFontMetrics().getMaxAscent();
      int d = g.getFontMetrics().getMaxDescent();

      mark(g, X, Y-a);
      mark(g, X+w, Y-a);
      mark(g, X+w, Y+d);
      mark(g, X, Y+d);
   }
}

class GField extends Panel implements AdjustmentListener  {
   Front Home;
   int Ix, DX, DY, OrgX, OrgY;
   Scrollbar HSBar, VSBar;

   GField(Front h, int i) {
      Home = h;
      Ix = i;
      DX = h.getNum();
      DY = h.getNum();

      setLayout(new BorderLayout());

      addMouseListener(new MouseAdapter() {
         public void mousePressed(MouseEvent ev) {
            Home.msg5("clk>", Ix+1,
               ev.getModifiers(),
               ev.getX()-OrgX,
               ev.getY()-OrgY );
            ev.consume();
         }
      } );

      addMouseMotionListener(new MouseMotionAdapter() {
         public void mouseDragged(MouseEvent ev) {
            Home.msg5("drg>", Ix+1,
               ev.getModifiers(),
               ev.getX()-OrgX,
               ev.getY()-OrgY );
            ev.consume();
         }
      } );
   }

   public Dimension getPreferredSize() {return new Dimension(DX,DY);}

   public void adjustmentValueChanged(AdjustmentEvent ev) {
      OrgX = HSBar==null? 0 : -HSBar.getValue();
      OrgY = VSBar==null? 0 : -VSBar.getValue();
      update(getGraphics());
   }

   void siz(int x, int y) {
      if (HSBar != null) {
         if (x > DX)
            HSBar.setMaximum(x);
         else {
            remove(HSBar);
            HSBar.removeAdjustmentListener(this);
            HSBar = null;
            OrgX = 0;
         }
      }
      else if (x > DX) {
         add("South", HSBar = new Scrollbar(Scrollbar.HORIZONTAL));
         HSBar.addAdjustmentListener(this);
         int vis = DX - HSBar.getPreferredSize().height;
         HSBar.setValues(OrgX = 0, vis, 0, x);
         HSBar.setUnitIncrement(vis/8);
         HSBar.setBlockIncrement(vis);
         validate();
      }
      if (VSBar != null) {
         if (y > DY)
            VSBar.setMaximum(y);
         else {
            remove(VSBar);
            VSBar.removeAdjustmentListener(this);
            VSBar = null;
            OrgY = 0;
         }
      }
      else if (y > DY) {
         add("East", VSBar = new Scrollbar(Scrollbar.VERTICAL));
         VSBar.addAdjustmentListener(this);
         int vis = DY - VSBar.getPreferredSize().width;
         VSBar.setValues(OrgY = 0, vis, 0, y);
         VSBar.setUnitIncrement(vis/8);
         VSBar.setBlockIncrement(vis);
         validate();
      }
   }
}

class DrawField extends GField {
   Graf[] Lst, Tmp;

   DrawField(Front h, int i) {super(h,i);}

   public void paint(Graphics g) {
      g.translate(OrgX, OrgY);
      if (Lst != null)
         for (int i = 0; i < Lst.length; ++i)
            Lst[i].draw(g);
      if (Tmp != null) {
         g.setXORMode(getBackground());
         drawTmp(g);
         g.setPaintMode();
      }
      super.paint(g);
   }

   void siz(int x) {super.siz(x, Home.getNum());}

   void set() {
      Lst = Home.getGraf();
      repaint();
   }

   void tmp() {
      Graphics g = getGraphics();

      g.translate(OrgX, OrgY);
      g.setXORMode(getBackground());
      if (Tmp != null)
         drawTmp(g);
      if ((Tmp = Home.getGraf()) != null)
         drawTmp(g);
      g.setPaintMode();
   }

   void drawTmp(Graphics g) {
      drawing:
      for (int i = 0; i < Tmp.length; ++i) {
         for (int j = 0; j < i; ++j)
            if (Tmp[j].match(Tmp[i]))
               continue drawing;
         Tmp[i].draw(g);  Tmp[i].mark(g);
      }
   }
}

class PictField extends GField {
   Image Img;

   PictField(Front h, int i) {super(h,i);}

   public void paint(Graphics g) {
      if (Img != null) {
         siz(Img.getWidth(this), Img.getHeight(this));
         g.drawImage(Img, OrgX, OrgY, this);
      }
   }
}
