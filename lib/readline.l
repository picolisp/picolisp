# 05dec08abu
# (c) Software Lab. Alexander Burger

(load "@lib/gcc.l")

(gcc "readline" '("-lreadline") '_led)

#include <readline/readline.h>
#include <readline/history.h>

any _led(any ex __attribute__((unused))) {
   char *p;
   any x;

   rl_already_prompted = YES;
   if ((p = readline(": ")) && *p)
      add_history(p);
   x = mkStr(p);
   free(p);
   return x;
}

/**/

# Enable line editing
(de *Led (_led))

# vi:et:ts=3:sw=3
