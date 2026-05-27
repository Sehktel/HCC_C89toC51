void wait(void){
unsigned char i;
for (i = 0; i < 255; i++){ ; }
}

void f_int0(void) interrupt 0
{
unsigned char i;
P1 = 0x00;
for(i = 0; i < 4; i++){
P1_3 ^= 1;
wait();
P1_3 ^= 1;
wait();
}
IE1 = 1;
}

void f_int1(void) interrupt 2
{
unsigned char i;
P1 = 0x00;
for(i = 0; i < 5; i++){
P1_2 ^= 1;
wait();
P1_2 ^= 1;
wait();
}
}

void main(void){
P1 = 0x00;
EA = 1;
EX0 = 1;
EX1 = 1;
IT0 = 1;
IT1 = 1;
while(1){
P1_4 ^= 1;
wait();
}
}
