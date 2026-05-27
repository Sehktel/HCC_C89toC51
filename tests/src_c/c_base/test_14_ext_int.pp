sfr P1 = 0x90;
sfr TCON = 0x88;
sfr IE = 0xA8;
sbit IT0 = 0x89;
sbit EX0 = 0xAA;
sbit EA = 0xAF;
void ext0_isr(void) interrupt 0 {
P1 = 255;
}
void main(void) {
IT0 = 1;
EX0 = 1;
EA = 1;
}
