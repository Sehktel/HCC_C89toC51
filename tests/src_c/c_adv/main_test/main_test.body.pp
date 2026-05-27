void main(void) {
port_init();
P1 = 0x00;
test_memory_types();
{
unsigned int delay;
for (delay = 0; delay < 5000; delay++) {
}
}
test_bit_operations();
{
unsigned int delay;
for (delay = 0; delay < 5000; delay++) {
}
}
test_timer_operations();
{
unsigned int delay;
for (delay = 0; delay < 5000; delay++) {
}
}
test_port_operations();
{
unsigned int delay;
for (delay = 0; delay < 5000; delay++) {
}
}
test_interrupt_setup();
P1 = 0xFF;
while (1) {
}
}
