sfr P1 = 0x90;
sfr TCON = 0x88;
sfr IE = 0xA8;
sbit LED0 = P1^0;
sbit LED1 = P1^1;
sbit IT0 = 0x89;
sbit IT1 = 0x8A;
sbit EX0 = 0xAA;
sbit EX1 = 0xAB;
sbit EA = 0xAF;
unsigned char led0_state = 0;
unsigned char led1_state = 0;
void ext_int_init(void) {
IT0 = 1;
IT1 = 1;
EX0 = 1;
EX1 = 1;
EA = 1;
}
void ext0_isr(void) interrupt 0 {
led0_state = !led0_state;
LED0 = led0_state;
}
void ext1_isr(void) interrupt 2 {
led1_state = !led1_state;
LED1 = led1_state;
}
void main(void) {
LED0 = 0;
LED1 = 0;
ext_int_init();
while(1) {
}
}
