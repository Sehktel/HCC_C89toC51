sfr SP = 0x81;
sfr DPL = 0x82;
sfr DPH = 0x83;
sfr PCON = 0x87;
sfr TCON = 0x88;
sfr TMOD = 0x89;
sfr TL0 = 0x8A;
sfr TL1 = 0x8B;
sfr TH0 = 0x8C;
sfr TH1 = 0x8D;
sfr P1 = 0x90;
sfr SCON = 0x98;
sfr SBUF = 0x99;
sfr IE = 0xA8;
sfr P3 = 0xB0;
sfr IP = 0xB8;
sfr PSW = 0xD0;
sfr ACC = 0xE0;
sfr B = 0xF0;
sbit IT0 = 0x88;
sbit IE0 = 0x89;
sbit IT1 = 0x8A;
sbit IE1 = 0x8B;
sbit TR0 = 0x8C;
sbit TF0 = 0x8D;
sbit TR1 = 0x8E;
sbit TF1 = 0x8F;
sbit P1_0 = 0x90;
sbit P1_1 = 0x91;
sbit P1_2 = 0x92;
sbit P1_3 = 0x93;
sbit P1_4 = 0x94;
sbit P1_5 = 0x95;
sbit P1_6 = 0x96;
sbit P1_7 = 0x97;
sbit AIN0 = 0x90;
sbit AIN1 = 0x91;
sbit RI = 0x98;
sbit TI = 0x99;
sbit RB8 = 0x9A;
sbit TB8 = 0x9B;
sbit REN = 0x9C;
sbit SM2 = 0x9D;
sbit SM1 = 0x9E;
sbit SM0 = 0x9F;
sbit EX0 = 0xA8;
sbit ET0 = 0xA9;
sbit EX1 = 0xAA;
sbit ET1 = 0xAB;
sbit ES = 0xAC;
sbit ET2 = 0xAD;
sbit EA = 0xAF;
sbit P3_0 = 0xB0;
sbit P3_1 = 0xB1;
sbit P3_2 = 0xB2;
sbit P3_3 = 0xB3;
sbit P3_4 = 0xB4;
sbit P3_5 = 0xB5;
sbit P3_7 = 0xB7;
sbit RXD = 0xB0;
sbit TXD = 0xB1;
sbit INT0 = 0xB2;
sbit INT1 = 0xB3;
sbit T0 = 0xB4;
sbit T1 = 0xB5;
sbit AOUT = 0xB6;
sbit PX0 = 0xB8;
sbit PT0 = 0xB9;
sbit PX1 = 0xBA;
sbit PT1 = 0xBB;
sbit PS = 0xBC;
sbit P = 0xD0;
sbit FL = 0xD1;
sbit OV = 0xD2;
sbit RS0 = 0xD3;
sbit RS1 = 0xD4;
sbit F0 = 0xD5;
sbit AC = 0xD6;
sbit CY = 0xD7;
typedef struct {
unsigned char id;
unsigned char status;
unsigned int value;
} TestData8051;
typedef union {
unsigned int word;
struct {
unsigned char low;
unsigned char high;
} bytes;
} TimerValue;
void test_memory_types(void);
void test_bit_operations(void);
void test_timer_operations(void);
void test_port_operations(void);
void test_interrupt_setup(void);
void timer0_init(unsigned int reload_value);
void timer1_init(unsigned int reload_value);
unsigned int timer0_read(void);
unsigned int timer1_read(void);
void port_init(void);
unsigned char read_port1(void);
void write_port1(unsigned char value);
unsigned char port_test_pattern = 0x55;
bit port_test_flag = 0;
void port_init(void) {
P1 = 0xFF;
}
unsigned char read_port1(void) {
return P1;
}
void write_port1(unsigned char value) {
P1 = value;
}
void test_port_operations(void) {
unsigned char test_value;
unsigned char original_value;
original_value = P1;
write_port1(0xAA);
test_value = read_port1();
if (test_value == 0xAA) {
((P1) |= (1 << (0)));
}
write_port1(0x55);
test_value = read_port1();
if (test_value == 0x55) {
((P1) |= (1 << (1)));
}
write_port1(0x00);
((P1) |= (1 << (2)));
((P1) |= (1 << (4)));
((P1) |= (1 << (6)));
test_value = read_port1();
if ((test_value & 0x54) == 0x54) {
((P1) |= (1 << (3)));
}
}
void test_port_bits(void) {
P1 = 0x00;
P1_0 = 1;
P1_2 = 1;
P1_4 = 1;
P1_6 = 1;
if (P1 == 0x55) {
P1_7 = 1;
}
P1_0 = 0;
P1_4 = 0;
if (P1 == 0xA4) {
P1_1 = 1;
}
}
void port_scan_demo(void) {
unsigned char i;
unsigned char pattern;
pattern = 0x01;
for (i = 0; i < 8; i++) {
P1 = pattern;
pattern = pattern << 1;
{
unsigned int delay;
for (delay = 0; delay < 1000; delay++) {
}
}
}
pattern = 0x80;
for (i = 0; i < 8; i++) {
P1 = pattern;
pattern = pattern >> 1;
{
unsigned int delay;
for (delay = 0; delay < 1000; delay++) {
}
}
}
}
void test_input_reading(void) {
unsigned char input_state;
P1 = 0xFF;
input_state = P1;
if (((input_state) & (1 << (0)))) {
port_test_flag = 1;
}
if (((input_state) & (1 << (7)))) {
((P1) ^= (1 << (1)));
}
}
void port_mask_demo(void) {
unsigned char mask_lower;
unsigned char mask_upper;
unsigned char port_value;
mask_lower = 0x0F;
mask_upper = 0xF0;
P1 = 0x00;
P1 |= (0x0A & mask_lower);
P1 |= (0x50 & mask_upper);
port_value = P1;
if (port_value == 0x5A) {
((P1) ^= (1 << (7)));
}
}
