// Qlib.c 3.7.3     BIBLIOTECA DE Q

// Se permite su modificacion, en cuyo caso ha de recompilarse IQ (ver Qman.txt)

// Conservar la siguiente línea
#include "Q.h"


// Definiciones auxiliares (rutinas, variables, ...)

/* inv_str() permite invertir el orden de las strings en Q para       
acomodarlo al de las rutinas de la biblioteca de C, y reinv_str()     
realiza la operación inversa, para lo cual precisa de los punteros de 
comienzo y final */                                                   

void reinv_str(unsigned char *p, unsigned char *r) {             
  while (p<r) {
    unsigned char t=*p;
    *p++=(unsigned char)*r;
    *r--=(unsigned char)t; 
  }
}                                                                     
                                                                      
unsigned char *inv_str(unsigned char *r) {
  unsigned char *p=(unsigned char *)r;                    
  while (*p) p--;    // va al '\0'
  reinv_str(p,r);    // invierte                                    
  return p;                                                           
}                                                                     


/* Rutinas de biblioteca de Q
*****************************

Utilizables tanto para código Q compilado como interpretado.
Segmentos de código Q sin restricciones (podemos usar construcciones
C) que implementan las distintas rutinas.  No tienen por qué seguir
el mismo esquema de paso de argumentos que nuestro código generado.
Se apoyan en las anteriores (y extendibles) definiciones
auxiliares.

Manténgase el esquema BEGINLIB {etiqueta: codigo-C} ENDLIB

Opcionalmente, defínanse macros para etiquetas en Qlib.h
*/
 

BEGINLIB

// void exit(int)                    
// Entrada: R0=código de salida
// No retorna
L exit_: exit(R0);  // termina el programa con código en R0

// void* new(int_size)           
// Entrada: R0=etiqueta de retorno
//          R1=tamaño (>=0)
// Salida: R0=puntero al tramo de memoria asignado 
// Sólo modifica R0                            
L new_: {//entre llaves por usar variable local
         int r=R0;
         IF(R1<0) GT(exit_);         // no permite tamaños negativos
         NH(R1);                     // reserva tramo de memoria en heap   
         R0=HP;                      // devuelve dirección más baja del tramo 
         GT(r);                      // retorna                  
        }                            

// void print(int)
// Entrada: I(R7) = valor entero a visualizar
//	    R5 = etiqueta de retorno
// No modifica ningún registro
L print: {printf("%d\n", I(R7));
          GT(R5);                   // retorna
	 }                                                          

ENDLIB
