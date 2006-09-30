/* 03sep06abu
 * (c) Software Lab. Alexander Burger
 */

extern void main2(int ac, char *av[]) __attribute__ ((noreturn));
int main(int ac, char *av[]) __attribute__ ((noreturn));

int main(int ac, char *av[]) {
   main2(ac,av);
}
