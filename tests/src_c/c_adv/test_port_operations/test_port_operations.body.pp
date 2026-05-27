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
