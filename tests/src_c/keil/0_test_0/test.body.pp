void light(char s, char d){

if (s == 1){ P1 = 0;}
if (s == 2){ P1 = 4;}
if (s == 3){ P1 = 8;}
if (s == 4){ P1 = 12;}
if (s == 5){ P1 = 16;}
if (s == 6){ P1 = 20;}
if (s == 7){ P1 = 24;}
if (s == 8){ P1 = 28;}

if (d == 1){P3 = 62;}
if (d == 2){P3 = 61;}
if (d == 3){P3 = 47;}
if (d == 4){P3 = 31;}
}

void wait(){
int w = 0;
int ww = 0;
for (w = 0; w < 16384; w++){
for (ww = 0; ww < 4; ww++){
;
}
}
}

void main(void){
char d;
char s;

for (d = 1; d <=4; d++){
for (s = 1; s <= 8; s ++){
light(s, d);
wait();
}
}
}
