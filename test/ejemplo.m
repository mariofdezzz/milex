
int f() {
    int x = 25

    for ( 
        int a = -1; 
        a < 5; 
        a = ++a
    ) {
        if (a > 4) {
            println(a)
        }else{println(x)}
    }

    return 2
}

{
    f()
}

