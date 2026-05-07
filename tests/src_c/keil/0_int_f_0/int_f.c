#include <reg2051.h>

int foo(int a){
	return a + 1;
}

void main(void){
	int a = 5;
	while(1){
		foo(a);
	}
}