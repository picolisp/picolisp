// 03jul04abu
// (c) Software Lab. Alexander Burger

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;

public class Z3dField extends Pico {
   int DX, DY, OrgX, OrgY, PosX, PosY, SnapX, SnapY;
   int[] Frame, Zbuff, XMin, XMax, ZMin, ZMax;
   MemoryImageSource Source;
   Image Img;
   Z3dText Marks, Labels;
   static long Tim;

   // Applet entry point
   public void init() {
      super.init();
      DX = Integer.parseInt(getParameter("WIDTH"));
      DY = Integer.parseInt(getParameter("HEIGHT"));
      OrgX = DX / 2;
      OrgY = DY / 2;
      Frame = new int[DX * DY];
      Zbuff = new int[DX * DY];
      XMin = new int[DY];  XMax = new int[DY];
      ZMin = new int[DY];  ZMax = new int[DY];
      Source = new MemoryImageSource(DX, DY, Frame, 0, DX);
      Source.setAnimated(true);
      Img = createImage(Source);

      addKeyListener(new KeyAdapter() {
         public void keyPressed(KeyEvent ev) {
            switch (ev.getKeyCode()) {
            case KeyEvent.VK_CONTROL:
               msg4("mov>", InputEvent.CTRL_MASK, PosX, PosY);
               break;
            case KeyEvent.VK_ESCAPE:
               msg1("esc>");
               break;
            case KeyEvent.VK_PAGE_UP:
               msg1("PGUP>");
               break;
            case KeyEvent.VK_PAGE_DOWN:
               msg1("PGDN>");
               break;
            case KeyEvent.VK_END:
               msg1("END>");
               break;
            case KeyEvent.VK_HOME:
               msg1("BEG>");
               break;
            case KeyEvent.VK_LEFT:
               msg1("LE>");
               break;
            case KeyEvent.VK_UP:
               msg1("UP>");
               break;
            case KeyEvent.VK_RIGHT:
               msg1("RI>");
               break;
            case KeyEvent.VK_DOWN:
               msg1("DN>");
               break;
            case KeyEvent.VK_DELETE:
               msg1("DEL>");
               break;
            case KeyEvent.VK_INSERT:
               msg1("INS>");
               break;
            }
            ev.consume();
         }
         public void keyReleased(KeyEvent ev) {
            if (ev.getKeyCode() == KeyEvent.VK_CONTROL)
               msg4("mov>", 0, PosX, PosY);
         }
      } );

      addMouseListener(new MouseAdapter() {
         public void mouseClicked(MouseEvent ev) {
            msg4("clk>",
               ev.getModifiers(),
               PosX = ev.getX()-OrgX,
               PosY = ev.getY()-OrgY );
            ev.consume();
         }
      } );

      addMouseMotionListener(new MouseMotionAdapter() {
         public void mouseMoved(MouseEvent ev) {
            msg4("mov>",
               ev.getModifiers(),
               PosX = ev.getX()-OrgX,
               PosY = ev.getY()-OrgY );
            ev.consume();
         }
      } );
   }

   synchronized void cmd(String s) {
      if (s.equals("draw"))
         draw();
      else if (s.equals("text"))
         text();
      else
         super.cmd(s);
   }

   public void paint(Graphics g) {update(g);}

   public void update(Graphics g) {
      Object[] a;
      Z3dText t;

      g.drawImage(Img,0,0,this);
      g.setPaintMode();
      for (t = Marks; t != null; t = t.Link)
         g.drawString(t.Text, t.X, t.Y);
      for (t = Labels; t != null; t = t.Link)
         if (t.Z < Zbuff[t.X * DY + t.Y])
            g.drawString(t.Text, t.X, t.Y);
      if (SnapX != 32767) {
         g.setXORMode(Color.white);
         g.fillOval(OrgX+SnapX-4, OrgY+SnapY-4, 8, 8);
      }
   }

   final void mkEdge(int x1, int y1, int z1, int x2, int y2, int z2) {
      int a, dx, dy, dz, sx, xd, xe, sz, zd, ze;

      if (y2 < y1) {
         a = x1;  x1 = x2;  x2 = a;
         a = y1;  y1 = y2;  y2 = a;
         a = z1;  z1 = z2;  z2 = a;
      }
      if (y1 > OrgY  ||  ((y2 += OrgY) <= 0))
         return;
      if ((dy  =  y2 - (y1 += OrgY)) == 0)
         return;
      dx = x2 - x1;  dz = z2 - z1;
      if (y1 < 0) {
         x1 += -y1 * dx / dy;
         z1 += -y1 * dz / dy;
         y1 = 0;
         if ((dy = y2) == 0)
            return;
         dx = x2 - x1;  dz = z2 - z1;
      }
      if (y2 > DY) {
         x2 += (DY - y2) * dx / dy;
         z2 += (DY - y2) * dz / dy;
         y2 = DY;
         if ((dy = y2 - y1) == 0)
            return;
         dx = x2 - x1;  dz = z2 - z1;
      }
      sx = 0;
      if (dx > 0)
         sx = 1;
      else if (dx < 0)
         {dx = -dx;  sx = -1;}
      xd = 0;
      if (dx > dy)
         {xd = dx/dy;  dx -= xd*dy;  xd *= sx;}
      xe = (dx *= 2) - dy;
      sz = 0;
      if (dz > 0)
         sz = 1;
      else if (dz < 0)
         {dz = -dz;  sz = -1;}
      zd = 0;
      if (dz > dy)
         {zd = dz/dy;  dz -= zd*dy;  zd *= sz;}
      ze = (dz *= 2) - dy;
      dy *= 2;
      x1 += OrgX;
      do {
         if ((a = x1) < 0)
            a = 0;
         else if (a > DX)
            a = DX;
         if (a < XMax[y1]) {
            XMin[y1] = a;
            ZMin[y1] = z1;
         }
         else {
            XMin[y1] = XMax[y1];
            ZMin[y1] = ZMax[y1];
            XMax[y1] = a;
            ZMax[y1] = z1;
         }
         x1 += xd;
         if (xe >= 0)
            {x1 += sx;  xe -= dy;}
         xe += dx;
         z1 += zd;
         if (ze >= 0)
            {z1 += sz;  ze -= dy;}
         ze += dz;
      } while (++y1 < y2);
   }

   final void zDots(int i, int x1, int x2, int z1, int z2) {
      if (z1 < Zbuff[i = i * DX + x1]) {
         Zbuff[i] = z1;
         Frame[i] = 0xFF000000;
      }
      if (z2 < Zbuff[i += x2 - x1]) {
         Zbuff[i] = z2;
         Frame[i] = 0xFF000000;
      }
   }

   final void zLine(int c, int i, int x1, int x2, int z1, int z2) {
      int d, e, dx, dz, sz;

      if ((dx = x2 - x1) != 0) {
         i = i * DX + x1;
         sz = 0;
         if ((dz = z2 - z1) > 0)
            sz = 1;
         else if (dz < 0)
            {dz = -dz;  sz = -1;}
         d = 0;
         if (dz > dx)
            {d = dz/dx;  dz -= d*dx;  d *= sz;}
         e = (dz *= 2) - dx;
         dx *= 2;
         do {
            if (z1 < Zbuff[i]) {
               Zbuff[i] = z1;
               Frame[i] = c;
            }
            z1 += d;
            if (e >= 0)
               {z1 += sz;  e -= dx;}
            ++i;
            e += dz;
         } while (++x1 < x2);
      }
   }

   void draw() {
      int n, c, i, x0, y0, z0, x1, y1, z1, x2, y2, z2;
      String s;
      long t;

      if ((n = DX * (getNum() + OrgY)) > Frame.length)  // Horizon
         n = Frame.length;
      c = getNum() | 0xFF000000;  // Sky color
      for (i = 0; i < n; ++i) {
         Frame[i] = c;
         Zbuff[i] = 0x7FFFFFFF;
      }
      c = getNum() | 0xFF000000;  // Ground color
      for (; i < Frame.length; ++i) {
         Frame[i] = c;
         Zbuff[i] = 0x7FFFFFFF;
      }
      Labels = null;
      while ((n = getNum()) != 0) {
         for (i = 0; i < DY; ++i)
            XMax[i] = 0;
         x0 = x1 = getNum();
         y0 = y1 = getNum();
         z0 = z1 = getNum();
         if ((s = getStr()).length() != 0  &&
               (x2 = OrgX + x0) >= 0  &&  x2 < DX  &&
               (y2 = OrgY + y0) >= 0  &&  y2 < DY )
            Labels = new Z3dText(x2, y2, z0, s, Labels);
         for (;;) {
            x2 = getNum();
            y2 = getNum();
            z2 = getNum();
            mkEdge(x1, y1, z1, x2, y2, z2);
            if (--n == 0)
               break;
            x1 = x2;  y1 = y2;  z1 = z2;
         }
         mkEdge(x2, y2, z2, x0, y0, z0);
         if ((c = getNum()) < 0) {
            for (i = 0; i < DY; ++i)
               if (XMax[i] != 0)
                  zDots(i, XMin[i], XMax[i], ZMin[i], ZMax[i]);
         }
         else {
            c |= 0xFF000000;  // Face color
            for (i = 0; i < DY; ++i)
               if (XMax[i] != 0)
                  zLine(c, i, XMin[i], XMax[i], ZMin[i], ZMax[i]);
         }
      }
      if ((SnapX = getNum()) != 32767)
         SnapY = getNum();
      msg1("ok>");
      Source.newPixels();
      update(getGraphics());
      t = System.currentTimeMillis();
      if (Tim > t) {
         try {Thread.currentThread().sleep(Tim - t);}
         catch (InterruptedException e) {}
         t = Tim;
      }
      Tim = t + 40;
   }

   void text() {
      int n = getNum();
      Marks = null;
      while (--n >= 0) {
         int x = OrgX + getNum();
         int y = OrgY + getNum();
         Marks = new Z3dText(x, y, 0, getStr(), Marks);
      }
      update(getGraphics());
   }
}

class Z3dText {
   int X, Y, Z;
   String Text;
   Z3dText Link;

   Z3dText(int x, int y, int z, String s, Z3dText link) {
      X = x;  Y = y;  Z = z;  Text = s;  Link = link;
   }
}
