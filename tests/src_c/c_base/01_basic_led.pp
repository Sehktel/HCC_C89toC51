sfr P1 = 0x90;
sbit LED = P1^0;
void delay(unsigned int count) {
unsigned int i;
for(i = 0; i < count; i++);
}
void main(void) {
while(1) {
LED = 0;
delay(10000);
LED = 1;
delay(10000);
}
}
