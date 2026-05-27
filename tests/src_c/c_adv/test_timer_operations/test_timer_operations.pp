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
unsigned int timer0_overflow_count = 0;
unsigned int timer1_overflow_count = 0;
bit timer0_flag = 0;
bit timer1_flag = 0;
void timer0_init(unsigned int reload_value) {
TR0 = 0;
TMOD &= 0xF0;
TMOD |= 0x01;
TH0 = (unsigned char)(reload_value >> 8);
TL0 = (unsigned char)(reload_value & 0xFF);
TF0 = 0;
TR0 = 1;
}
void timer1_init(unsigned int reload_value) {
TR1 = 0;
TMOD &= 0x0F;
TMOD |= 0x20;
TH1 = (unsigned char)(reload_value & 0xFF);
TL1 = (unsigned char)(reload_value & 0xFF);
TF1 = 0;
TR1 = 1;
}
unsigned int timer0_read(void) {
unsigned char high_byte, low_byte;
low_byte = TL0;
high_byte = TH0;
return ((unsigned int)high_byte << 8) | low_byte;
}
unsigned int timer1_read(void) {
return (unsigned int)TL1;
}
void test_timer_operations(void) {
unsigned int initial_value, current_value;
unsigned char delay_counter;
timer0_init(0x8000);
for (delay_counter = 0; delay_counter < 100; delay_counter++) {
}
current_value = timer0_read();
if (current_value > 0x8000) {
((P1) |= (1 << (0)));
}
timer1_init(0x80);
for (delay_counter = 0; delay_counter < 50; delay_counter++) {
}
current_value = timer1_read();
if (current_value > 0x80) {
((P1) |= (1 << (1)));
}
}
void test_timer_overflow(void) {
unsigned char timeout_counter;
timer0_init(0xFFF0);
timeout_counter = 0;
while (!TF0 && timeout_counter < 255) {
timeout_counter++;
}
if (TF0) {
((P1) |= (1 << (2)));
TF0 = 0;
}
timer1_init(0xF0);
timeout_counter = 0;
while (!TF1 && timeout_counter < 255) {
timeout_counter++;
}
if (TF1) {
((P1) |= (1 << (3)));
TF1 = 0;
}
}
void timer_delay_demo(void) {
unsigned char i;
for (i = 0; i < 5; i++) {
timer0_init(0xFC18);
while (!TF0) {
}
TF0 = 0;
((P1) ^= (1 << (4)));
}
((P1) |= (1 << (5)));
}
void test_timer_modes(void) {
TR0 = 0;
TMOD &= 0xF0;
TH0 = 0x1F;
TL0 = 0xE0;
TR0 = 1;
if (TR0) {
((P1) |= (1 << (6)));
}
TR0 = 0;
TMOD &= 0xF0;
TMOD |= 0x03;
TH0 = 0x80;
TL0 = 0x80;
TR0 = 1;
if (TR0) {
((P1) |= (1 << (7)));
}
}
