// Fibonacci (Reescrito durante la exposicion)

float x
bool b
float fibo(int n) {

  int m = n-2
  x = 1.
  b = n == 0

  if (n == 1)
    return x
  else 
    if (b)
      return 0.
  
  return fibo(n-1) + fibo(m)
}
float y

{
  int i
  for (i=0; i<15; i++) {
    println(fibo(i))
  }
}
