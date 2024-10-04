import os
import matplotlib.pyplot as plt

x = [1, 2, 3, 4, 5]

files = ['conf_var_tags.txt', 'int_var_tags.txt']
labels = ['Confidencialidade via IFC', 'Integridade via IFC']
label_index = 0
plt.plot(range(len(x)), [100_000 for i in range(5)], marker='o', label='Sem mecanismos de segurança')
plt.xticks(ticks=range(len(x)), labels=x)
plt.plot(range(len(x)), [138542 for i in range(5)], marker='o', label='Criptografia por meios convencionais')
plt.xticks(ticks=range(len(x)), labels=x)
for file in files:
    f = open(file, 'r')
    i=0
    values = []
    for line in f:
        if i == 5:
            break
        values.append(int(line))
        i += 1
    plt.plot(range(len(x)), values, marker='o', label=labels[label_index])
    label_index += 1
    plt.xticks(ticks=range(len(x)), labels=x)
plt.yscale('log')
plt.xlabel('Número de tags')
plt.ylabel('Número de bytes após a operação')
plt.legend()
plt.tight_layout()
plt.show()