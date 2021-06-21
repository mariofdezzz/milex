
int n

int fibo() {
  if (n <= 1) return n

  int temp = n
  
  n = temp - 1
  int x = fibo()
  
  n = temp - 2
  int y = fibo()

  return x + y
}

{
  n = 9

  println(fibo())
}