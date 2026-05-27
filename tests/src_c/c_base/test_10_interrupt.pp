sfr IE = 0xA8;
sbit EA = 0xAF;
sbit ET0 = 0xA9;
void timer0_isr(void) interrupt 1 {
P1_0 = !P1_0;
}
void main(void) {
EA = 1;
ET0 = 1;
}
