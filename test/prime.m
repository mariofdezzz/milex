void prime(int N) {
  int i
  int j
  int flag
 
  for (i = 1; i <= N; i++) {
    if (i == 1 || i == 0)
      continue

    flag = 1
 
    for (j = 2; j <= i / 2; ++j) {
      if (i % j == 0) {
        flag = 0
        break
      }
    }

    if (flag == 1)
      println(i)
  }
}

{
  prime(60)
}