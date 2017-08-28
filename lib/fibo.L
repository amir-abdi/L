struct s
{
	int i;
	int a[20];
};
int fibo(int n)
{
	if(n == 1 || n == 2)
	{
		return 1;
	}
	else
	{
		return fibo(n-1) + fibo(n-2);
	}
}
int main()
{
	s a;
	for(a.i = 1; a.i<20; a.i=a.i+1)
	{
		a.a[a.i] = fibo(a.i);
	}
	for(a.i = 1; a.i<20; a.i=a.i+1)
	{
		writeint a.a[a.i];
		writetext " ";
	}
	return 0;
}
