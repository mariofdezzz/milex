
int pow(int x, int y) {
  if (y == 0)
        return 1
    else {
      int t = pow(x, y/2)
      
      if (y%2 == 0)
        return t * t
      else
        return x * t * t
    }
}

{
  int x = 5
  int y = 3
  
  println(pow(x, y))
}