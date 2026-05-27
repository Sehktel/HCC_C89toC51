sfr P1 = 0x90;
sfr P2 = 0xA0;
sbit TEST_BIT = P1^1;
sbit OUTPUT_BIT = P1^2;
void main(void) {
unsigned char data_byte = 85;
data_byte |= 128;
data_byte &= 127;
data_byte ^= 255;
while(1) {
if(TEST_BIT == 1) {
OUTPUT_BIT = 1;
P2 = data_byte;
} else {
OUTPUT_BIT = 0;
P2 = ~data_byte;
}
}
}
