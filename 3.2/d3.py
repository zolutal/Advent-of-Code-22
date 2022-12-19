def solve(data):
    total = 0
    split = data.strip().split('\n')
    for i in range(0, len(split), 3):
        l1, l2, l3 = split[i:i+3]
        for c in l1.strip():
            if c in l2 and c in l3:
                t = ((((ord(c) >> 5) & 1) ^ 1) * 26)
                l = ((ord(c) & 0xdf) - 0x40)
                print(f"{c} {hex(ord(c))}: {t} ; {l} ; {t+l}")
                total += t+l
                print(hex(total))
                break


f = open("./input.txt", "r")
data = f.read()
solve(data)
