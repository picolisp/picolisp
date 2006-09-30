// 05aug06abu
// (c) Software Lab. Alexander Burger

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public class JPopUp implements ActionListener {
   Pico Parent;
   String[] Lst;

   public JPopUp(Pico p, Component comp) {
      Parent = p;
      JPopupMenu menu = new JPopupMenu(p.getStr());
      menu.setFont(new Font("Monospaced", Font.PLAIN, p.getFont().getSize()));
      Lst = new String[p.getNum()];
      for (int i = 0; i < Lst.length; ++i) {
         JMenuItem item = new JMenuItem(Lst[i] = p.getStr());
         item.setEnabled(p.getStr().length() != 0);
         item.addActionListener(this);
         item.setActionCommand(Integer.toString(i+1));
         menu.add(item);
      }
      menu.show(comp, 30, 20);
      menu.repaint();  //??
   }

   public void actionPerformed(ActionEvent ev) {
      Parent.msg2("cmd>", Integer.parseInt(ev.getActionCommand()));
      Parent.flush();
   }
}
