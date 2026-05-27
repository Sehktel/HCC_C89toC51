sfr P1 = 0x90;
sbit TEST_PIN = P1^0;
sbit LED_PIN = P1^1;
void main(void) {
bit flag;
flag = 1;
TEST_PIN = flag;
LED_PIN = !TEST_PIN;
}
