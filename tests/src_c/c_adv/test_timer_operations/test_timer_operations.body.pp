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
