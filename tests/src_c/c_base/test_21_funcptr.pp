char add(char x) {
return x + 1;
}
char sub(char x) {
return x - 1;
}
void main(void) {
char a;
char (*fptr)(char);
fptr = add;
a = fptr(5);
fptr = sub;
a = fptr(5);
}
