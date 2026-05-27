sfr SCON = 0x98;
sfr SBUF = 0x99;
sfr TMOD = 0x89;
sfr TH1 = 0x8D;
sfr IE = 0xA8;
sbit TI = 0x99;
sbit RI = 0x98;
sbit ES = 0xAC;
sbit EA = 0xAF;
sbit TR1 = 0x8E;
unsigned char rx_buffer[16];
unsigned char rx_index = 0;
void uart_init(void) {
SCON = 80;
TMOD &= 15;
TMOD |= 32;
TH1 = 253;
TR1 = 1;
ES = 1;
EA = 1;
}
void uart_send_char(unsigned char c) {
SBUF = c;
while(!TI);
TI = 0;
}
void uart_send_string(unsigned char *str) {
while(*str) {
uart_send_char(*str++);
}
}
void uart_isr(void) interrupt 4 {
if(RI) {
RI = 0;
rx_buffer[rx_index] = SBUF;
if(rx_index < 15) {
rx_index++;
}
}
}
void main(void) {
uart_init();
uart_send_string("8051 UART Test\r\n");
while(1) {
if(rx_index > 0) {
uart_send_char(rx_buffer[--rx_index]);
}
}
}
