// 23dec06abu
// (c) Software Lab. Alexander Burger

import java.util.*;
import java.awt.*;
import java.applet.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.text.*;
import javax.swing.border.*;

public class Front extends Pico {
   JComponent[] Fields;
   JScrollBar[] SBars;
   Hashtable Skip;
   Vector Sync, Rid, Crypt;
   int Focus, Dirty;
   boolean Req;
   JDialog Dialog;
   Front Parent;
   static final Color Gray = new Color(0xE0,0xE0,0xE0);

   public Front() {}

   public Front(Front p, int port, String sid, String ttl) {
      Parent = p;
      Host = p.Host;
      Seed = p.Seed;
      Scale = p.Scale;
      InN = p.InN;
      InD = p.InD;
      OutN = p.OutN;
      Dialog = new JDialog(p.frame(), ttl, false);
      Dialog.getContentPane().add(this, BorderLayout.CENTER);
      Dialog.addWindowListener(new WindowAdapter() {
         public void windowClosing(WindowEvent ev) {stop();}
      } );
      connect(0, port, sid);
   }

   Frame frame() {
      Container c = getParent();
      while (!(c instanceof Frame))
         c = c.getParent();
      return (Frame)c;
   }

   public void stop() {
      msg1("at>");
      change();
      super.stop();
      Rdy = false;
   }

   void done() {
      if (Dialog != null) {
         Dialog.dispose();
         Dialog = null;
         Parent.Seed ^= Seed;
      }
      super.done();
   }

   // Switch to another URL
   void url(String s, String t) {
      if (Parent == null)
         super.url(s,t);
      else {
         stop();
         Parent.url(s,t);
      }
   }

   public AppletContext getAppletContext() {
      return Parent==null? super.getAppletContext() : Parent.getAppletContext();
   }

   // Command dispatcher
   void cmd(String s) {
      if (s.equals("ack"))
         {Req = false; relay(); flush();}
      else if (s.equals("able"))
         able(Fields[getNum()-1], getStr().length() != 0);
      else if (s.equals("focus"))
         Fields[(Focus = getNum())-1].requestFocus();
      else if (s.equals("next"))
         Fields[Focus-1].transferFocus();
      else if (s.equals("text"))
         text(getNum());
      else if (s.equals("type"))
         type(getNum());
      else if (s.equals("feed"))
         feed(getNum());
      else if (s.equals("bCol"))
         Fields[getNum()-1].setBackground(new Color(getNum()));
      else if (s.equals("fCol"))
         Fields[getNum()-1].setForeground(new Color(getNum()));
      else if (s.equals("grow"))
         grow(Fields[getNum()-1]);
      else if (s.equals("img"))
         img(getNum());
      else if (s.equals("lock"))
         lock(getStr().length() == 0);
      else if (s.equals("scrl"))
         scrl(SBars[getNum()-1], getNum(), getNum(), getNum());
      else if (s.equals("menu"))
         new JPopUp(this, Fields[getNum()-1]);
      else if (s.equals("make"))
         make();
      else if (s.equals("rdy"))
         Rdy = true;
      else if (s.equals("dialog"))
         new Front(this, getNum(), getStr(), getStr());
      else
         super.cmd(s);
   }

   void make() {
      int i, j, k, k2, k3, m, n, p, vFlg, hFlg;
      Vector fld, sb;
      JComponent f;
      JScrollBar b;
      JScrollPane jsp;
      JPanel panel, flow;
      Color back, fore;
      String s, font;
      float size;
      Font fnt;
      Dimension d;
      Border border;
      GridBagLayout gridbag;

      fld = new Vector();
      sb = new Vector();
      Sync = new Vector();
      Rid = new Vector();
      Crypt = new Vector();
      i = j = k = k2 = k3 = p = 0;
      f = null;
      b = null;
      panel = flow = null;
      back = fore = null;
      Skip = new Hashtable();
      border = new CompoundBorder(BorderFactory.createRaisedBevelBorder(), new EmptyBorder(6,6,6,6));
      getContentPane().setLayout(gridbag = new GridBagLayout());
      while ((s = getStr()).length() != 0) {
         if (s.charAt(0) == '*' || s.charAt(0) == '&' || s.charAt(0) == '/') {
            if (panel != null) {
               constrain(getContentPane(), panel, 0, p++, 1, 1, 1.0, 1.0,
                     GridBagConstraints.NORTHWEST, GridBagConstraints.NONE,
                     6, 0 );
            }
            j = k = k2 = 0;
            panel = new JPanel(gridbag);
            if (back != null)
               panel.setBackground(back);
            if (s.charAt(0) != '*') {
               panel.setBorder(border);
               if (s.charAt(0) == '/') {
                  k = k2 = 1;
                  b = new JScrollBar(Adjustable.VERTICAL, 1, 1, 1, 2);
               }
            }
         }
         else if (s.charAt(0) == '=' || s.charAt(0) == ':') {
            j = 0;
            k = k2 = k3;
            if (s.charAt(0) == ':') {
               ++k;
               ++k2;
               b = new JScrollBar(Adjustable.VERTICAL, 1, 1, 1, 2);
            }
         }
         else if (s.charAt(0) == '+')
            {++j;  k = k2;}
         else if (s.charAt(0) != '-') {
            if (s.charAt(0) == '[') {
               FlowLayout fl = (FlowLayout)(flow = new JPanel()).getLayout();
               if (back != null)
                  flow.setBackground(back);
               fl.setAlignment(FlowLayout.LEFT);
               fl.setVgap(0);
               fl.setHgap(0);
            }
            else if (s.charAt(0) == ']') {
               constrain(panel, flow, k++, j, 1, 1, 1.0, 1.0,
                     GridBagConstraints.NORTHWEST, GridBagConstraints.BOTH,
                     0, 0 );
               flow = null;
            }
            else if (s.equals("able"))
               able(f,false);
            else if (s.equals("sync"))
               Sync.addElement(f);
            else if (s.equals("back")) {
               back = new Color(getNum());
               if (panel == null)
                  getContentPane().setBackground(back);
            }
            else if (s.equals("fore"))
               fore = new Color(getNum());
            else if (s.equals("bCol"))
               f.setBackground(new Color(getNum()));
            else if (s.equals("fCol"))
               f.setForeground(new Color(getNum()));
            else if (s.equals("tip"))
               ((JComponent)f).setToolTipText(getStr());
            else if (s.equals("rid"))
               Rid.addElement(f);
            else if (s.equals("rsa"))
               Crypt.addElement(f);
            else {  // Font name
               fnt = new Font(s, Font.PLAIN, (n=getNum())==0? getFont().getSize() : n);
               f.setFont(fnt);
               msg3("adv>", i, getFontMetrics(fnt).charWidth('o'));
            }
            continue;
         }

         s = getStr();
         n = getNum();
         if (s.length() > 0) {
            f = new JLabel(s, n<=0? JLabel.LEFT : JLabel.RIGHT);
            if (fore != null)
               f.setForeground(fore);
            fnt = f.getFont();
            f.setFont(fnt.deriveFont(Scale * fnt.getSize()));
            constrain(panel, f, k++, j, 1, 1, 0.0, 1.0,
                  n==0?  GridBagConstraints.SOUTH :
                     n<0?  GridBagConstraints.WEST : GridBagConstraints.EAST,
                  GridBagConstraints.NONE,
                  0, n<=0? 0 : 2 );
         }
         if (n > 0) {
            if (b != null) {
               b.addAdjustmentListener(new PicoAdjustmentListener(this,i));
               constrain(panel, b, k2-1, 1, 1, GridBagConstraints.REMAINDER, 0.0, 1.0,
                     GridBagConstraints.EAST, GridBagConstraints.VERTICAL,
                     0, 0 );
            }
            sb.addElement(b);
            jsp = null;
            font = null;
            size = Scale;
            b = null;
            switch(n) {
            case 'B':  // Button
               f = new JButton(getStr());
               ((JButton)f).setActionCommand(Integer.toString(i+1));
               ((JButton)f).addActionListener(new ActionListener() {
                  public void actionPerformed(ActionEvent ev) {
                     if (Req || !Rdy)
                        getToolkit().beep();
                     else {
                        msg1("at>");
                        change();
                        Req = true;
                        msg2("act>", Integer.parseInt(ev.getActionCommand()));
                        flush();
                     }
                  }
               } );
               ((JButton)f).setMargin(new Insets(0,3,0,3));
               size *= 0.8f;
               break;
            case 'c':  // Check box
               f = new JCheckBox();
               ((JCheckBox)f).addItemListener(new PicoItemListener(this,i));
               break;
            case 'C':  // Choice box
               f = new JComboBox();
               n = getNum();
               while (--n >= 0)
                  ((JComboBox)f).addItem(getStr());
               ((JComboBox)f).addItemListener(new PicoItemListener(this,i));
               size *= 0.8f;
               break;
            case 'L':  // Label
               f = new JLabel(getStr());
               if (fore != null)
                  f.setForeground(fore);
               break;
            case 'T':  // TextField
               if ((m = getNum()) == 0)         // dx
                  f = new JPasswordField(getNum());
               else if ((n = getNum()) == 0)    // dy
                  f = new JTextField(m);
               else {
                  vFlg = JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED;
                  hFlg = JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED;
                  if (m < 0)
                     {m = -m;  hFlg = JScrollPane.HORIZONTAL_SCROLLBAR_NEVER;}
                  if (n < 0)
                     {n = -n;  vFlg = JScrollPane.VERTICAL_SCROLLBAR_NEVER;}
                  jsp = new JScrollPane(f = new JTextArea(n, m), vFlg, hFlg);
               }
               f.addMouseListener(new PicoMouseAdapter(this,i));
               f.setBackground(Color.white);
               font = "Monospaced";
               break;
            case 'P':  // PictField
               f = new PictField(this,i);
               break;
            }
            size *= (fnt = f.getFont()).getSize();
            if (font == null)
               f.setFont(fnt.deriveFont(size));
            else
               f.setFont(new Font(font, Font.PLAIN, (int)size));
            f.setMinimumSize(f.getPreferredSize());
            if (jsp != null)
               jsp.setMinimumSize(jsp.getPreferredSize());
            f.addFocusListener(new PicoFocusListener(this,i));
            f.addKeyListener(new PicoKeyAdapter(this,i));
            ++i;
            fld.addElement(f);
            if (flow != null)
               flow.add(f);
            else
               constrain(panel, jsp==null? f : jsp, k++, j, 1, 1, 1.0, 1.0,
                     GridBagConstraints.NORTHWEST, GridBagConstraints.NONE,
                     0, 0 );
         }
         if (k > k3)
            k3 = k;
      }
      constrain(getContentPane(), panel, 0, p, 1, 1, 1.0, 1.0,
            GridBagConstraints.NORTHWEST, GridBagConstraints.NONE,
            6, 0 );
      fld.copyInto(Fields = new JComponent[fld.size()]);
      sb.copyInto(SBars = new JScrollBar[sb.size()]);
      validate();

      if (Dialog == null) {
         d = getPreferredSize();
         msg3("siz>", d.width, d.height);
      }
      else {
         Dialog.pack();
         d = Dialog.getToolkit().getScreenSize();
         Rectangle r = Dialog.getBounds();
         r.x = (d.width - r.width)/2;
         r.y = (d.height - r.height)/2;
         Dialog.setBounds(r);
         Dialog.show();
      }
      flush();
   }

   // Add component to container
   private static void constrain(Container cont, JComponent comp,
                  int x, int y, int w, int h, double wx, double wy,
                  int anchor, int fill, int ins, int insX ) {
      GridBagConstraints c = new GridBagConstraints(
         x, y, w, h, wx, wy, anchor, fill,
         new Insets(ins, x==0? ins : ins+6*insX, ins, ins+insX),
         0, 0 );
      ((GridBagLayout)cont.getLayout()).setConstraints(comp,c);
      cont.add(comp);
   }

   // Set field value
   void text(int fld) {
      JComponent f = Fields[fld-1];

      String txt = Crypt.contains(f)? inCiph() : getStr();
      int len = txt.length();
      if (f instanceof JButton)
         ((JButton)f).setText(txt);
      else if (f instanceof JComboBox)
         ((JComboBox)f).setSelectedItem(txt);
      else if (f instanceof JCheckBox)
         ((JCheckBox)f).setSelected(len > 0);
      else if (f instanceof JLabel)
         ((JLabel)f).setText(txt);
      else {
         ((JTextComponent)f).setText(txt);
         if (f instanceof JTextField) {
            if (len > ((JTextField)f).getColumns())
               len = 0;
            ((JTextField)f).select(len,len);
         }
      }
   }

   // Type text (string or list of strings) into field
   void type(int fld) {
      JComponent f = Fields[fld-1];

      Object o = Crypt.contains(f)? inCiph() : read();
      if (f instanceof JTextComponent) {
         String txt;

         if (o instanceof String)
            txt = (String)o;
         else {
            StringBuffer buf = new StringBuffer();

            for (int i = 0;  i < ((Object[])o).length;  ++i)
               buf.append((String)((Object[])o)[i]);
            txt = buf.toString();
         }
         int i = ((JTextComponent)f).getSelectionStart();
         ((JTextComponent)f).replaceSelection(txt);
         if (o instanceof String)
            ((JTextComponent)f).select(i+1, i+txt.length());
         Dirty = fld;
         if (Sync.contains(Fields[fld-1])) {
            change();
            flush();
         }
      }
   }

   // Feed line to TextArea
   void feed(int fld) {
      JComponent f = Fields[fld-1];
      String s;
      int n;

      if ((n = getNum()) > 0) {
         s = ((JTextArea)f).getText();
         for (int i = 0;  (i = s.indexOf('\n', i)) >= 0;  ++i)
            if (--n == 0) {
               ((JTextArea)f).replaceRange("", 0, 1+((JTextArea)f).getText().indexOf('\n'));
               break;
            }
      }
      s = Crypt.contains(f)? inCiph() : getStr();
      ((JTextArea)f).append(s);
      ((JTextArea)f).append("\n");
   }

   // Grow/shrink field
   void grow(JComponent f) {
      Dimension d = f.getSize();
      f.setSize(d.width + getNum(), d.height + getNum());  // getHeight/getWidth
   }

   // Set image
   void img(int fld) {
      PictField f = (PictField)Fields[fld-1];
      int n = getNum();

      f.Img = n==0? null : getToolkit().createImage(getBytes(n));
      f.repaint();
   }

   // Enable or disable
   void able(JComponent f, boolean a) {
      if (!(f instanceof JTextComponent))
         f.setEnabled(a);
      else if (!a) {
         Skip.put(f,f);
         if (f.getBackground() == Color.white)
            f.setBackground(Gray);
      }
      else {
         Skip.remove(f);
         if (f.getBackground() == Gray)
            f.setBackground(Color.white);
      }
   }

   void lock(boolean a) {
      for (int i = 0;  i < Fields.length;  ++i)
         if (!Rid.contains(Fields[i]))
            able(Fields[i],a);
   }

   // Set scroll bar values
   void scrl(JScrollBar sb, int val, int vis, int max) {
      if (sb != null) {
         ((PicoAdjustmentListener)(sb.getAdjustmentListeners()[0])).Val = val;
         sb.setValues(val, vis, 1, 2+Math.max(vis,max));
      }
   }

   // Signal field value change
   void change() {
      int fld, sel;
      JComponent f;
      String txt;

      synchronized (Fields) {
         if ((fld = Dirty) != 0) {
            if (Rdy  &&  !Skip.containsKey(f = Fields[fld-1])) {
               Dirty = 0;
               if (f instanceof JComboBox) {
                  txt = (String)((JComboBox)f).getSelectedItem();
                  sel = 0;
               }
               else if (f instanceof JCheckBox) {
                  txt = ((JCheckBox)f).isSelected()? "T": "";
                  sel = 0;
               }
               else {
                  txt = ((JTextComponent)f).getText();
                  if (f instanceof JTextField)
                     txt = txt.trim();
                  else {
                     int i = txt.length();
                     while (i > 0  &&  txt.charAt(i-1) <= ' ')
                        --i;
                     txt = txt.substring(0,i);
                  }
                  sel = ((JTextComponent)f).getSelectionStart();
               }
               if (Crypt.contains(f)  &&  txt.length() != 0)
                  msg4("chg>", fld, outCiph(txt), sel);
               else
                  msg4("chg>", fld, txt, sel);
               relay();
            }
         }
      }
   }

   // Signal state change
   void relay() {
      if (Parent != null)
         msg1("able>");
      else {
         Enumeration e = getAppletContext().getApplets();
         while (e.hasMoreElements()) {
            JApplet a = (JApplet)e.nextElement();
            if (a instanceof Front)
               ((Front)a).msg1("able>");
         }
      }
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
      if (Home.Rdy  &&  Home.Focus != 0  &&  Home.Focus != Ix) {
         Home.msg2("nxt>", Home.Focus = Ix);
         Home.relay();
         Home.flush();
      }
   }

   public void focusLost(FocusEvent ev) {
      Home.change();
      Home.flush();
   }
}

class PicoAdjustmentListener implements AdjustmentListener {
   Front Home;
   int Ix, Val;

   PicoAdjustmentListener(Front h, int i) {Home = h; Ix = i+1;}

   public void adjustmentValueChanged(AdjustmentEvent ev) {
      if (Home.Rdy  &&  Val != ev.getValue()) {
         Home.change();
         Home.msg3("scr>", Ix, Val = ev.getValue());
         Home.relay();
         Home.flush();
      }
   }
}

class PicoMouseAdapter extends MouseAdapter {
   Front Home;
   int Ix;

   PicoMouseAdapter(Front h, int i) {Home = h; Ix = i+1;}

   public void mousePressed(MouseEvent ev) {
      if (!Home.Rdy)
         ev.consume();
      else if (ev.getClickCount() == 2) {
         if (Home.Req)
            Home.getToolkit().beep();
         else {
            Home.msg1("at>");
            Home.change();
            Home.Req = true;
            Home.msg2("act>", Ix);
            Home.flush();
         }
         ev.consume();
      }
   }
}

class PicoKeyAdapter extends KeyAdapter {
   Front Home;
   int Ix;
   static String Clip;

   PicoKeyAdapter(Front h, int i) {Home = h; Ix = i+1;}

   public void keyTyped(KeyEvent ev) {
      char c;
      JComponent f;

      if (!Home.Rdy) {
         ev.consume();
         return;
      }
      f = Home.Fields[Ix-1];
      if ((c = ev.getKeyChar()) == KeyEvent.VK_ENTER) {
         Home.change();
         if (!(f instanceof JTextArea))
            Home.msg2("ret>", Ix);
         else if (Home.Skip.containsKey(f))
            Home.getToolkit().beep();
         else
            key(f, "\n");
         Home.relay();
         ev.consume();
      }
      else if (Home.Skip.containsKey(f))
         ev.consume();
      else if (f instanceof JTextComponent  &&  c >= KeyEvent.VK_SPACE  &&  c != KeyEvent.VK_DELETE) {
         if (Home.Sync.contains(f))
            Home.change();
         char[] chr = {c};
         key(f, new String(chr));
         ev.consume();
      }
      Home.flush();
   }

   public void keyPressed(KeyEvent ev) {
      int m, c, i, j;
      JComponent f;

      if (!Home.Rdy) {
         ev.consume();
         return;
      }
      if (((m = ev.getModifiers()) & (InputEvent.META_MASK | InputEvent.ALT_MASK)) != 0) {
         ev.consume();
         return;
      }
      Home.msg1("at>");
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
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof JTextArea) {
            i = j = goPgUp((JTextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((JTextArea)f).getSelectionEnd();
            ((JTextArea)f).select(i,j);
         }
         else {
            Home.change();
            Home.msg1("PGUP>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_PAGE_DOWN:
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof JTextArea) {
            i = j = goPgDn((JTextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((JTextArea)f).getSelectionStart();
            ((JTextArea)f).select(i,j);
         }
         else {
            Home.change();
            Home.msg1("PGDN>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_END:
         if ((m & InputEvent.CTRL_MASK) != 0) {
            Home.change();
            Home.msg1("END>");
            Home.relay();
         }
         else if (f instanceof JTextComponent) {
            i = j = ((JTextComponent)f).getText().length();
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((JTextComponent)f).getSelectionStart();
            ((JTextComponent)f).select(i,j);
         }
         ev.consume();
         break;
      case KeyEvent.VK_HOME:
         if ((m & InputEvent.CTRL_MASK) != 0) {
            Home.change();
            Home.msg1("BEG>");
            Home.relay();
         }
         else if (f instanceof JTextComponent) {
            i = j = 0;
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((JTextComponent)f).getSelectionEnd();
            ((JTextComponent)f).select(i,j);
         }
         ev.consume();
         break;
      case KeyEvent.VK_LEFT:
         if (f instanceof JTextComponent) {
            i = j = ((JTextComponent)f).getSelectionStart()-1;
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((JTextComponent)f).getSelectionEnd();
            ((JTextComponent)f).select(i,j);
            ev.consume();
         }
         break;
      case KeyEvent.VK_UP:
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof JTextArea) {
            i = j = goUp((JTextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               j = ((JTextArea)f).getSelectionEnd();
            ((JTextArea)f).select(i,j);
         }
         else {
            Home.change();
            Home.msg1("UP>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_RIGHT:
         if (f instanceof JTextComponent) {
            i = j = ((JTextComponent)f).getSelectionEnd()+1;
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((JTextComponent)f).getSelectionStart();
            ((JTextComponent)f).select(i,j);
            ev.consume();
         }
         break;
      case KeyEvent.VK_DOWN:
         if ((m & InputEvent.CTRL_MASK) == 0  &&  f instanceof JTextArea) {
            i = j = goDn((JTextArea)f);
            if ((m & InputEvent.SHIFT_MASK) != 0)
               i = ((JTextArea)f).getSelectionStart();
            ((JTextArea)f).select(i,j);
         }
         else {
            Home.change();
            Home.msg1("DN>");
            Home.relay();
         }
         ev.consume();
         break;
      case KeyEvent.VK_DELETE:
         if (Home.Skip.containsKey(f))
            Home.getToolkit().beep();
         else if ((m & InputEvent.CTRL_MASK) != 0) {
            Home.change();
            Home.msg1("DEL>");
            Home.relay();
         }
         else {
            Home.Dirty = Ix;
            if (f instanceof JTextComponent) {
               i = ((JTextComponent)f).getSelectionStart();
               j = ((JTextComponent)f).getSelectionEnd();
               if (i == j)
                  ((JTextComponent)f).select(i, j+1);
               else
                  Clip = ((JTextComponent)f).getSelectedText();
               ((JTextComponent)f).replaceSelection("");
            }
         }
         ev.consume();
         break;
      case KeyEvent.VK_INSERT:
         if (Home.Skip.containsKey(f))
            Home.getToolkit().beep();
         else if ((m & InputEvent.CTRL_MASK) != 0) {
            Home.change();
            Home.msg1("INS>");
            Home.relay();
         }
         else if (Clip != null)
            for (i = 1;  i <= Clip.length();  ++i)
               key(f, Clip.substring(i-1,i));
         ev.consume();
         break;
      default:
         if (c >= KeyEvent.VK_F1  &&  c <= KeyEvent.VK_F12) {
            Home.change();
            Home.msg1("F" + (1 + c - KeyEvent.VK_F1) + ">");
            Home.relay();
            ev.consume();
         }
         else if (c == KeyEvent.VK_TAB) {
            if (f instanceof JTextArea) {
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
         else if (c == KeyEvent.VK_BACK_SPACE) {
            if (f instanceof JTextComponent)
               Home.msg2("bs>", Home.Dirty = Ix);
         }
         else if (ev.isControlDown())
            Home.Dirty = Ix;
         else if (f instanceof JTextComponent)
            ev.consume();
      }
      Home.flush();
   }

   /* Send keystroke */
   private void key(JComponent f, String s) {
      if (Home.Crypt.contains(f))
         Home.msg3("key>", Ix, Home.outCiph(s));
      else
         Home.msg3("key>", Ix, s);
   }

   /* TextArea movements */
   private int goUp(JTextArea f) {
      int i, j, k;

      String s = f.getText();
      if ((i = f.getSelectionStart()) == 0)
         return 0;
      if ((j = s.lastIndexOf('\n',i-1)) < 0)
         return i;
      return (k = s.lastIndexOf('\n',j-1) + i - j) > j?  j : k;
   }

   private int goDn(JTextArea f) {
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

   private int goPgUp(JTextArea f) {
      int n, i;

      String s = f.getText();
      n = f.getRows()-1;
      for (i = f.getSelectionStart()-1;  n > 0 && i > 0;  --i)
         if (s.charAt(i) == '\n')
            --n;
      return i;
   }

   private int goPgDn(JTextArea f) {
      int n, i;

      String s = f.getText();
      n = f.getRows()-1;
      for (i = f.getSelectionEnd();  n > 0 && i < s.length();  ++i)
         if (s.charAt(i) == '\n')
            --n;
      return i;
   }
}

class PictField extends JPanel {
   Front Home;
   int Ix, DX, DY;
   Image Img;

   PictField(Front h, int i) {
      Home = h;
      Ix = i+1;
      DX = h.getNum();
      DY = h.getNum();
      setOpaque(false);
      setBorder(BorderFactory.createLineBorder(Color.black));

      addMouseListener(new MouseAdapter() {
         public void mousePressed(MouseEvent ev) {
            if (Home.Rdy) {
               Home.msg1("at>");
               Home.msg5(ev.getClickCount()==2? "dbl>" : "clk>", Ix, ev.getModifiers(), ev.getX(), ev.getY());
               Home.flush();
            }
            ev.consume();
         }
      } );

      addMouseMotionListener(new MouseMotionAdapter() {
         public void mouseDragged(MouseEvent ev) {
            if (Home.Rdy) {
               Home.msg1("at>");
               Home.msg5("drg>", Ix, ev.getModifiers(), ev.getX(), ev.getY());
               Home.flush();
            }
            ev.consume();
         }
      } );
   }

   public Dimension getPreferredSize() {return new Dimension(DX,DY);}

   public void paint(Graphics g) {
      if (Img != null)
         g.drawImage(Img, 0, 0, this);
      paintBorder(g);
   }
}
