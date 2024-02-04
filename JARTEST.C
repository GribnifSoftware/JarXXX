#include "tos.h"
#include "stdio.h"

/* Test program to show the functions of JARxxx. Much of this can be
   simplified for real applications. */

#define CJar_cookie	0x434A6172L	/* "CJar" */
#define CJar_xbios	0x434A		/* "CJ" */
#define	CJar_OK		0x6172		/* "ar" */

#define my_cookie	0x74657374	/* "test" */

#define CJar( mode, cookie, value )	xbios(CJar_xbios,mode,cookie,value)

int main(void)
{
  long CJ_data, my_data=0x12345678;
  int ret;
  
  ret = CJar( 0, CJar_cookie, &CJ_data );	/* is it there? */
  if( ret == CJar_OK )				/* yes, print data */
  {
    printf( "JARxxx Version: %d\n%d entries requested by user\n\
%d allocated, %d in use\n\n", (char)(CJ_data>>24), (char)(CJ_data>>16),
(char)(CJ_data>>8), (char)CJ_data );
    ret = CJar( 1, my_cookie, &my_data );	/* make test cookie */
    if( ret==CJar_OK )				/* successful */
    {
      ret = CJar( 0, my_cookie, &CJ_data );
      if( ret==CJar_OK )
      {
        if( CJ_data==my_data ) printf( "Test OK" );
        else printf( "Test failed" );
      }
      else printf( "Could not find my new cookie!" );
    }
    else if( ret==-1 ) printf( "No room in cookie jar" );
    else printf( "Unknown error" );
  }
  else printf( "JARxxx not installed." );
  return ret;
}
