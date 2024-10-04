import os
import matplotlib.pyplot as plt

x = [1, 10, 100, 1000, 10000, 100000]

files = ['conf_var_bytes.txt', 'int_var_bytes.txt', 'some_conf.txt']
labels = ['Confidencialidade via IFC', 'Integridade via IFC', 'Criptografia por meios convencionais']
label_index = 0
plt.plot(range(len(x)), x, marker='o', label='Sem mecanismos de segurança')
plt.xticks(ticks=range(len(x)), labels=x)
for file in files:
    f = open(file, 'r')
    i=0
    values = []
    for line in f:
        if i == 6:
            break
        values.append(int(line))
        i += 1
    plt.plot(range(len(x)), values, marker='o', label=labels[label_index])
    label_index += 1
    plt.xticks(ticks=range(len(x)), labels=x)
plt.yscale('log')
plt.legend()
plt.xlabel('Número de bytes iniciais')
plt.ylabel('Número de bytes após a operação')
plt.tight_layout()
plt.show()