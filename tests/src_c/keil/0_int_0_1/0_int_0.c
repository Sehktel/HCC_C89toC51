#include <reg2051.h>

void wait (void){
	unsigned int i, j;
	for (i = 0; i < 255; i++) {
		for (j = 0; j < 255; j++) {
			;
		}
	}
}


// External Interrupt 0
void P12_Blink(void) interrupt 0 using 1 {
	int i = 0;
	for (i = 0; i < 8; i++){
		P1_2 ^= 1;
		wait();
	}
}

// External Interrupt 0
void P13_Blink(void) interrupt 2 using 2 {
	int i = 0;
	for (i = 0; i < 4; i++){
		P1_3 ^= 1;
		wait();
	}
}

void P14_Blink(void){
	while(1){
		P1_4 ^= 1;
		wait();
	}
}




void main(void){
	P1 = 0;
	P3 = 0xFF;

	/*------------------------------------------------
	TCON Bit Registers
	------------------------------------------------*/
	IT0  = 1; // Int0 Falling Edge Mode
	EX0  = 1; // Int0 Enable
	IT1  = 1; // Int1 Falling Edge Mode
	EX1  = 1; // Int1 Enable
	
	EA   = 1; // Global Interrupt Enable
	
	P14_Blink();
}