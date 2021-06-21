
int g

int f() {
  if (g<5){
    println(g)
    g = ++g
    return g + 2
    f()
  }
}

{
  g = 0
  println(f())
}