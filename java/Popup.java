// 05aug06abu
// (c) Software Lab. Alexander Burger

import java.util.*;
import java.awt.*;
import java.awt.event.*;

public class Popup implements ActionListener {
   Pico Parent;
   String[] Lst;

   public Popup(Pico p, Component comp) {
      Parent = p;
      PopupMenu menu = new PopupMenu(p.getStr());
      menu.setFont(new Font("Monospaced", Font.PLAIN, p.getFont().getSize()));
      Lst = new String[p.getNum()];
      for (int i = 0; i < Lst.length; ++i) {
         MenuItem item = new MenuItem(Lst[i] = p.getStr());
         item.setEnabled(p.getStr().length() != 0);
         item.addActionListener(this);
         item.setActionCommand(Integer.toString(i+1));
         menu.add(item);
      }
      comp.add(menu);
      menu.show(comp, 30, 20);
   }

   public void actionPerformed(ActionEvent ev) {
      Parent.msg2("cmd>", Integer.parseInt(ev.getActionCommand()));
      Parent.flush();
   }
}
