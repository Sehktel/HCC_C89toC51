#include <reg2051.h>

void main(void){
	unsigned int i;
	for(;;){ // while(1) 1 -- magic number
		P3_7 = 0;
		for(i = 0; i < 65535; i++) { ; } // wait
		P3_7 = 1;
		for(i = 0; i < 65535; i++) { ; } // wait
	}
}
