unsigned char interrupt_counter = 0;
bit timer_interrupt_flag = 0;
bit external_interrupt_flag = 0;
void timer0_isr(void) interrupt 1 {
TF0 = 0;
interrupt_counter++;
timer_interrupt_flag = 1;
((P1) ^= (1 << (0)));
}
void external_int0_isr(void) interrupt 0 {
IE0 = 0;
external_interrupt_flag = 1;
((P1) ^= (1 << (1)));
}
void interrupt_system_init(void) {
EA = 0;
TF0 = 0;
TF1 = 0;
IE0 = 0;
IE1 = 0;
interrupt_counter = 0;
timer_interrupt_flag = 0;
external_interrupt_flag = 0;
}
void setup_timer0_interrupt(void) {
TR0 = 0;
TMOD &= 0xF0;
TMOD |= 0x01;
TH0 = 0x3C;
TL0 = 0xB0;
ET0 = 1;
TF0 = 0;
TR0 = 1;
}
void setup_external_int0(void) {
IT0 = 1;
IE0 = 0;
EX0 = 1;
}
void test_interrupt_setup(void) {
unsigned char test_timeout;
interrupt_system_init();
setup_timer0_interrupt();
EA = 1;
test_timeout = 0;
while (!timer_interrupt_flag && test_timeout < 200) {
test_timeout++;
{
unsigned int delay;
for (delay = 0; delay < 100; delay++) {
}
}
}
if (timer_interrupt_flag) {
((P1) |= (1 << (2)));
}
setup_external_int0();
IE0 = 1;
{
unsigned int delay;
for (delay = 0; delay < 1000; delay++) {
}
}
if (external_interrupt_flag) {
((P1) |= (1 << (3)));
}
}
void interrupt_priority_demo(void) {
PX0 = 1;
PT0 = 0;
EX0 = 1;
ET0 = 1;
EA = 1;
((P1) |= (1 << (4)));
}
void interrupt_mask_test(void) {
EA = 0;
TF0 = 1;
IE0 = 1;
{
unsigned int delay;
for (delay = 0; delay < 1000; delay++) {
}
}
if (TF0 && IE0) {
((P1) |= (1 << (5)));
}
EA = 1;
{
unsigned int delay;
for (delay = 0; delay < 1000; delay++) {
}
}
if (!TF0 || !IE0) {
((P1) |= (1 << (6)));
}
}
