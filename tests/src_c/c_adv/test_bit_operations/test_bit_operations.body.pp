bit system_ready;
bit error_flag;
bit test_mode;
void test_bit_operations(void) {
unsigned char test_byte;
unsigned char result;
test_byte = 0x00;
((test_byte) |= (1 << (0)));
((test_byte) |= (1 << (2)));
((test_byte) |= (1 << (4)));
((test_byte) |= (1 << (6)));
if (test_byte == 0x55) {
((P1) |= (1 << (0)));
}
((test_byte) &= (~(1 << (0))));
((test_byte) &= (~(1 << (4))));
if (test_byte == 0x44) {
((P1) |= (1 << (1)));
}
((test_byte) ^= (1 << (1)));
((test_byte) ^= (1 << (3)));
((test_byte) ^= (1 << (5)));
((test_byte) ^= (1 << (7)));
if (test_byte == 0xEE) {
((P1) |= (1 << (2)));
}
result = 0;
if (((test_byte) & (1 << (1)))) result |= 0x01;
if (((test_byte) & (1 << (3)))) result |= 0x02;
if (((test_byte) & (1 << (5)))) result |= 0x04;
if (((test_byte) & (1 << (7)))) result |= 0x08;
if (result == 0x0F) {
((P1) |= (1 << (3)));
}
}
void test_bit_variables(void) {
system_ready = 0;
error_flag = 0;
test_mode = 1;
if (test_mode && !error_flag) {
system_ready = 1;
}
if (system_ready) {
((P1) |= (1 << (4)));
}
error_flag = system_ready && test_mode;
if (error_flag) {
((P1) |= (1 << (5)));
}
}
void test_sfr_bits(void) {
unsigned char original_p1 = P1;
P1_0 = 1;
P1_1 = 0;
P1_2 = 1;
if (P1_0 && !P1_1 && P1_2) {
((P1) |= (1 << (6)));
}
P1 = original_p1;
}
void bit_manipulation_demo(void) {
unsigned char status_register;
unsigned char mask;
mask = 0x0F;
status_register = 0xA5;
status_register &= ~mask;
status_register |= (0x0C & mask);
if (status_register == 0xAC) {
((P1) |= (1 << (7)));
}
}
