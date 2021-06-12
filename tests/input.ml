
// Esto es un programa de ejemplo

int[] sort(int[] arr) {
    for (int i = 0; i < arr.length; i++) {
        int min_idx = i

        for (int j = i+1; j < n; j++) {
            if (arr[j] < arr[min_idx]) min_idx = j
        }
        int temp = att[min_idx]
        arr[min_idx] = i
        arr[i] = temp
    }
    return arr
}

int[] valores = [3, 8, 4, 2, 9, 0, 1]
println(sort(valores))

int sort(int arr) {var = 2}