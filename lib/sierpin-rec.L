/* Draws a Sierpinski Triangle */
/* Author: Saeed Nejati */
/* Note: Hey, sierpinski triangle has just nice properties,
 * I don't have an obsession on it! ;) */

string map[512][1024];

int pow2(int n)
{
	int i, p;
	p = 1;
	for(i=0; i<n; i=i+1)
	{
		p = p * 2;
	}
	return p;
}

void draw(int n, int x, int y)
{
	if ( n == 1 )
	{
		map[x][y] = "/";
		map[x-1][y+1] = "/";
		map[x][y+1] = "_";
		map[x][y+2] = "_";
		map[x][y+3] = "\\";
		map[x-1][y+2] = "\\";
		return;
	}
	int f;
	f = pow2(n-1);
	draw (n-1, x, y);
	draw (n-1, x, y+2*f);
	draw (n-1, x-f, y+f);
	return;
}


int main()
{
	int n, xlen, ylen;

	readint n;
	xlen= pow2(n);
	ylen = 2*xlen;

	int i, j;
	for( i=0; i<xlen; i=i+1 )
	{
		for( j=0; j<ylen; j=j+1 )
		{
			map[i][j] = " ";
		}
	}
	draw(n, xlen-1, 0);
	for( i=0; i<xlen; i=i+1 )
	{
		for( j=0; j<ylen; j=j+1 )
		{
			writetext map[i][j];
		}
		writetext "\n";
	}
	return 0;
}

