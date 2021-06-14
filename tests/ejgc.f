
int p


int fibo () {
    int j = 0
    int k = 1

    for (int i=0; i<25; i=i+1) {
        println(j)

        int temp = k
        k = j + k
        j = temp
    }

    return j
}

{   
    println(fibo())
}

