sfr P1 = 0x90;
sfr TMOD = 0x89;
sfr TH0 = 0x8C;
sfr TL0 = 0x8A;
sfr IE = 0xA8;
sbit OUTPUT_PIN = P1^0;
sbit ET0 = 0xA9;
sbit EA = 0xAF;
sbit TR0 = 0x8C;
void timer0_init(void) {
TMOD &= 240;
TMOD |= 1;
TH0 = 252;
TL0 = 24;
ET0 = 1;
EA = 1;
TR0 = 1;
}
void timer0_isr(void) interrupt 1 {
TH0 = 252;
TL0 = 24;
OUTPUT_PIN = !OUTPUT_PIN;
}
void main(void) {
OUTPUT_PIN = 0;
timer0_init();
while(1) {
}
}
