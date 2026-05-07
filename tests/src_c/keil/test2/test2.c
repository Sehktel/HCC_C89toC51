#include <reg2051.h>

void main(){

  long a = 5;
  P3 =  a;
  while(a) {
    a--;
    P3 =  a;
  }
   P3 =  a;
}