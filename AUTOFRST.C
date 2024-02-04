#include "tos.h"
#include "stdlib.h"
#include "string.h"

#define TEMPDIR "AUTOFRST.$$$"

void bconws( char *s )
{
  while( *s ) Bconout(2,*s++);
}

void any_key( int stat )
{
  bconws( "\r\nPress any key to exit...\r\n" );
  Bconin(2);
  exit(stat);
}

void quiterr( int stat, char *s )
{
  bconws(s);
  any_key(stat);
}

char *pathend( char *s )
{
  char *p;
  
  if( (p=strrchr(s,'\\')) != 0 ) return p+1;
  return s;
}

int move( char *ptr )
{
  char temp[120];
  int err;

  strcpy( temp, TEMPDIR );
  strcat( temp, "\\" );
  strcat( temp, ptr );
  if( (err=Frename( 0, ptr, temp )) != 0 )
  {
    bconws( ptr );
    bconws( err==-33 ? " does not exist.\r\n" : " could not be moved.\r\n" );
    return 0;
  }
  return 1;
}

int main( int argc, char *argv[] )
{
  int err, count, i;
  char temp[120], *ptr;
  DTA dta;
  
  if( argc<2 )
  {
    bconws( "Change the physical order of files in a directory.\r\n\n\
Format:  autofrst file1 [file2 ... fileN]\r\n\
File1\'s path is automatically used for all other files.\r\n\n\
Example: autofrst C:\\AUTO\\JAR16.PRG\r\n" );
    any_key(1);
  }
  if( argv[1][1]==':' )
  {
    Dsetdrv( (argv[1][0]&0x5F)-'A' );
    argv[1] += 2;
  }
  strcpy( temp, argv[1] );
  *pathend(temp) = '\0';
  if( temp[0] && (err=Dsetpath( temp )) != 0 )
  {
    bconws(temp);
    quiterr( err, ":  Could not set path" );
  }
  if( (err=Dcreate(TEMPDIR)) != 0 ) quiterr( err, "Could not create temporary directory" );
  for( i=1, count=0; i<argc; i++ )
    if( move(pathend(argv[i])) ) count++;
  if( !count )
  {
    Ddelete(TEMPDIR);
    quiterr( 2, "No files could be reordered" );
  }
  Fsetdta(&dta);
  if( !Fsfirst( "*.*", 0x37 ) )
    do
      if( strcmp(dta.d_fname,".") && strcmp(dta.d_fname,"..") &&
          !(dta.d_attrib&FA_SUBDIR) )
        if( move( dta.d_fname ) ) count--;
    while( count && !Fsnext() );
  Dsetpath(TEMPDIR);
  if( !Fsfirst( "*.*", 0x37 ) )
    do
      if( strcmp(dta.d_fname,".") && strcmp(dta.d_fname,"..") )
      {
        strcpy( temp, "..\\" );
        strcat( temp, dta.d_fname );
        Frename( 0, dta.d_fname, temp );
      }
    while( !Fsnext() );
  Dsetpath("..");
  Ddelete(TEMPDIR);
  return 0;
}
