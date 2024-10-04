import matplotlib.pyplot as plt

file = open('scale.txt', 'r')
y = []
for line in file:
    y.append(int(line))
plt.plot([x + 1 for x in range(25)], y, label='Confidencialidade via IFC')
plt.yscale('log')
plt.xlabel('Número de tags')
plt.ylabel('Número de bytes após a operação')
plt.tight_layout()
plt.legend()
plt.show()