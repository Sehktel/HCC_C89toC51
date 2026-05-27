sfr P0 = 0x80;
sfr P1 = 0x90;
sfr P2 = 0xA0;
sfr P3 = 0xB0;
sfr PSW = 0xD0;
sfr ACC = 0xE0;
sfr B = 0xF0;
sfr SP = 0x81;
sfr DPL = 0x82;
sfr DPH = 0x83;
sbit EA = 0xAF;
sbit ET0 = 0xA9;
sbit ET1 = 0xAB;
sbit ES = 0xAC;
sbit CY = 0xD7;
sbit AC = 0xD6;
sbit F0 = 0xD5;
sbit RS0 = 0xD3;
sbit RS1 = 0xD4;
unsigned int counter;
unsigned char status;
int data[10];
char message[20];
void timer0_isr(void) interrupt 1 using 1 {
counter++;
if (counter >= 1000) {
counter = 0;
P1 = ~P1;
}
}
void serial_isr(void) interrupt 4 {
char received;
received = SBUF;
status |= 1;
}
void init_system(void) {
counter = 0;
status = 0;
P0 = 255;
P1 = 0;
P2 = 255;
P3 = 0;
TMOD = 32;
TH1 = 253;
TR1 = 1;
SCON = 80;
EA = 1;
ET0 = 1;
ES = 1;
}
void delay(unsigned int ms) {
unsigned int i, j;
for (i = 0; i < ms; i++) {
for (j = 0; j < 123; j++) {
}
}
}
int process_data(unsigned char *buffer, int length) {
int i;
int sum = 0;
while (i < length) {
sum += buffer[i];
i++;
}
if (sum > 1000) {
return -1;
} else if (sum > 500) {
return 0;
} else {
return 1;
}
}
void main(void) {
unsigned char buffer[16];
int result;
init_system();
while (1) {
if (status & 1) {
result = process_data(buffer, 16);
switch (result) {
case -1:
P2 = 255;
break;
case 0:
P2 = 170;
break;
default:
P2 = 0;
break;
}
status &= ~1;
}
delay(100);
}
}
