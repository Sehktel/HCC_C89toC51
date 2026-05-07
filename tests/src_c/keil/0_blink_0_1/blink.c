#include <reg2051.h>

void wait(void);


static void int0(void) interrupt 0 using 1
{
	char count = 6;
	char i;
	for(i = 0; i < count; i++){
		P1_4 ^= 1;
		wait();
	}
}

static void int1(void) interrupt 2 using 2
{
	char count = 6;
	char i;
	for(i = 0; i < count; i++){
		P1_3 ^= 1;
		wait();
	}
}

void wait(void) {
	unsigned int a = 1000;
	unsigned int i;
	
	for (i = 0; i < a; i++) { ; }
}

void main(void) {
	
	EA = 1; /* global enable interrupt */
	EX1 = 1;
	EX0 = 1;
	IT0 = 1;
	IT1 = 0;
	P1 = 0;
	for(;;){
		P1_2 ^= 1;
		wait();
	}

	//	for(;;){
//		P3_7 = 1;
//		wait();
//		P3_7 = 0;
//		wait()
//	}
}