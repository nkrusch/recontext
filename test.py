def l132(c):
    i, j, t = 0, 48 - c, c - 48
    for n in range(10):
        j = i + i
        t = c - 48
        i = j + t
        j2 = (2 * t) * (2**n - 1)
        i2 = j2 + t
        print(n, t, i, i2, '|', j, j2)




from random import randint
l132(randint(49,56))