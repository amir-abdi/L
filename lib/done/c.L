struct str1
{
	int a;
	float b[10][10];
};
int main()
{
	int i, j, k;
	str1 s;
	s.a = 10;
	s.b[s.a - 5][s.a - 3] = 20.25;
	writefloat s.a * s.b[5][7] / 5;
	//s.b = 20.6;
	writetext "\n";
	writeint s.a;
	//writefloat s.b;
	return 0;
}
