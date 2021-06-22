
int fibo(int n) {
  if (n <= 1) 
    return n
  
  int x = fibo(n-1)
  int y = fibo(n-2)
  return x + y
}

{
  int n = 9
  
  println(fibo(n))
}