
int p

void a() {
    println(999)
    return
}
void b() {
    p = p - 8
    print(0)
}

int fibo () {
    int j = 0
    int k = 1

    for (int i=0; i<25; i=i+1) {
        println(j)

        if (i % 2 == 0) {
            b()
        } else {
            if (i % 3 != 0) a() else b()
        }
        int temp = k
        k = j + k
        j = temp
    }

    return j
}

{   
    p = 0
    
    while (p >= -8) {
        println(fibo())
    }
}

