// 24oct03abu
// (c) Software Lab. Alexander Burger

import java.util.*;
import java.awt.*;
import java.awt.event.*;

public class Popup implements ActionListener {
   Pico Parent;
   String[] Lst;

   public Popup(Pico p, Component c) {
      Parent = p;
      PopupMenu menu = new PopupMenu(p.getStr());
      Lst = new String[p.getNum()];
      for (int i = 0; i < Lst.length; ++i) {
         MenuItem item = new MenuItem(Lst[i] = p.getStr());
         item.setEnabled(p.getStr().length() != 0);
         item.addActionListener(this);
         item.setActionCommand(Integer.toString(i+1));
         menu.add(item);
      }
      c.add(menu);
      menu.show(c, 30, 20);
   }

   public void actionPerformed(ActionEvent ev) {
      Parent.msg2("cmd>", Integer.parseInt(ev.getActionCommand()));
   }
}
