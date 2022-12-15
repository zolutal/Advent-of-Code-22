def solve(data):
    print(max(sorted([sum([int(b) for b in a.strip().split('\n')]) for a in data.strip().split("\n\n")])))

f = open("./input.txt", "r")
data = f.read()
solve(data)
