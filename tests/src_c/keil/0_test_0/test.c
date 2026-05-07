# include <reg51.h>
// # include <abc.h>

void light(char s, char d){
//	if (s & 0x01){ P1 = 0;} 
//	if (s & 0x02){ P1 = 4;}
//	if (s & 0x04){ P1 = 8;}
//	if (s & 0x08){ P1 = 12;}
//	if (s & 0x10){ P1 = 16;}
//	if (s & 0x20){ P1 = 20;}
//	if (s & 0x40){ P1 = 24;}
//	if (s & 0x80){ P1 = 28;}

	if (s == 1){ P1 = 0;} 
	if (s == 2){ P1 = 4;}
	if (s == 3){ P1 = 8;}
	if (s == 4){ P1 = 12;}
	if (s == 5){ P1 = 16;}
	if (s == 6){ P1 = 20;}
	if (s == 7){ P1 = 24;}
	if (s == 8){ P1 = 28;}

	if (d == 1){P3 = 62;} //50;}
	if (d == 2){P3 = 61;} //49;}
	if (d == 3){P3 = 47;} //35;}
	if (d == 4){P3 = 31;} //19;}
}

void wait(){
	int w = 0;
	int ww = 0;
//	for (w = 0; w < 1024; w++){
//	for (w = 0; w < 2048; w++){
//	for (w = 0; w < 4096; w++){
//	for (w = 0; w < 8192; w++){
	for (w = 0; w < 16384; w++){
//	for (w = 0; w < 32768; w++){

//	for (w = 0; w < 256; w++){
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