
float n

float fibo() {
  if (n <= 1.) return n

  float temp = n
  
  n = temp - 1.
  float x = fibo()
  
  n = temp - 2.
  float y = fibo()

  return x + y
}

{
  n = 9.

  println(fibo())
}