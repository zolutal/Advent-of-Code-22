def solve(data):
    print(sum(sorted([sum([int(b) for b in a.strip().split('\n')]) for a in data.strip().split("\n\n")])[-3:]))


f = open("./input.txt", "r")
data = f.read()
solve(data)
