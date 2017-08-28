int w[10][10], a, b;
boolean func1(int a, boolean e, string s)
{
	int b, c;
	b = 30;
	c = 40;
	a = b + c;
	writetext "yes!";
	return (a > b);
}
int func2(int n)
{
	a = a + 1;
	if(n == 1 || n == 2)
	{
		return 1;
	}
	else
	{
		return func2(n - 1) + func2(n - 2);
	}
}
void func3(int a, float b)
{
	//writeint a;
	writefloat b;
	return;
}

void func4()
{
	int i;
	int j;
	for(i = 0; i<10; i=i+1)
	{
		for(j = 0; j<10; j = j+1)
		{
			w[i][j] = (i + j);
		}
	}
	return;
}
void func5()
{
	int i;
	int j;
	for(i = 0; i<10; i=i+1)
	{
		for(j = 0; j<10; j = j+1)
		{
			writeint w[i][j];
			writetext " ";
		}
		writetext "\n";
	}
	return;
}
int main()
{

	a = 1;
	func4();
	func5();
//	writeint func2(18);
/*	float a[100];
	int i;
	i = 1;
	a = 0;
	writeint func2(10);
	writeint a;
	for(i = 0;i < 100 ;i = i+1)
	{
		a[i] = i * .25;
		writeint a[i];
	}
	for(i = 0; i<100; i = i+1)
	{
		//writefloat a[i];
		func3(i, a[i]);
	}*/
	return 0;
}
