//Osnovnoy tsikl -- budet morgat' odin svetodiod v beskonechnom tsikle. 
//Po INT0 -- budet morgat' drugoy svetodiod 4 raza 
//Po INT1 -- budet morgat' tretiy svetodiod 6 raz

//The main loop will blink one LED in an infinite loop.
//INT0 will blink another LED 4 times.
//INT1 will blink a third LED 6 times.


#include <reg2051.h>

void wait(void){
	unsigned char i; // 1 - byte, positive ( 0 -- 255 )
	for (i = 0; i < 255; i++){ ; }
}


// P1.4 -- main
// P1.3 -- int0
// P1.2 -- int1

void f_int0(void) interrupt 0 // Instruction Pointer --> 0x0003h
{ 
	unsigned char i;
	P1 = 0x00;
	for(i = 0; i < 4; i++){
		P1_3 ^= 1; // toggle  --> 1
		wait();
		P1_3 ^= 1; // toggle  --> 0
		wait();
	}
	IE1 = 1;
}


void f_int1(void) interrupt 2 // Instruction Pointer --> 0x0013h
{
	unsigned char i;
	P1 = 0x00;
	for(i = 0; i < 5; i++){
		P1_2 ^= 1; // toggle  --> 1
		wait();
		P1_2 ^= 1; // toggle  --> 0
		wait();
	}
}

// sbit P1_0 = 0x90;
// sbit P1_1 = 0x91;
// sbit P1_2 = 0x92;
// sbit P1_3 = 0x93;
// sbit P1_4 = 0x94;
// sbit P1_5 = 0x95;
// sbit P1_6 = 0x96;
// sbit P1_7 = 0x97;

void main(void){
	P1 = 0x00;
	/*------------------------------------------------
IE Bit Registers
------------------------------------------------*/
//sbit EX0  = 0xA8;       /* 1=Enable External interrupt 0 */
//sbit ET0  = 0xA9;       /* 1=Enable Timer 0 interrupt */
//sbit EX1  = 0xAA;       /* 1=Enable External interrupt 1 */
//sbit ET1  = 0xAB;       /* 1=Enable Timer 1 interrupt */
//sbit ES   = 0xAC;       /* 1=Enable Serial port interrupt */
//sbit ET2  = 0xAD;       /* 1=Enable Timer 2 interrupt */

//sbit EA   = 0xAF;       /* 0=Disable all interrupts */

	EA = 1; // Enable Interrupts
	EX0 = 1; // Enable INT0
	EX1 = 1; // Enbale INT1
	
	/*------------------------------------------------
TCON Bit Registers
------------------------------------------------*/
//sbit IT0  = 0x88;
//sbit IE0  = 0x89;
//sbit IT1  = 0x8A;
//sbit IE1  = 0x8B;
//sbit TR0  = 0x8C;
//sbit TF0  = 0x8D;
//sbit TR1  = 0x8E;
//sbit TF1  = 0x8F;

	IT0 = 1; // fall - triggered on INT0
	IT1 = 1; // fall - triggered on INT1

	
	while(1){
		P1_4 ^= 1; // toggle 
		wait();
	}
}