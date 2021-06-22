
float sum(float x, float y) {
  return x + y
}

{
  int i=0
  while (i<5) {
    println(i)

    if (i>2) break
    i++
  }

  for (int j=0; j<10; j++) {
    println(j)
    
    if (j>2) break
  }

  // break
  // println(2222)
}