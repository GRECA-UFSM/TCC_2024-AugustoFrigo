import os
import matplotlib.pyplot as plt
import re
import pdb
x = [1, 10, 100, 1000, 10000, 100000]

result_files = []
for root, dirs, files in os.walk('./'):
    for file in files:
        if file.startswith('results'):
            result_files.append(os.path.join(root, file))

print(result_files)

names = ["base", "conf", "int", "some_confidentiality"]
name_mapping = {"base": "Sem mecanismos de segurança",
                "some_confidentiality": "Criptografia por meios convencionais",
                "conf": "Confidencialidade via IFC",
                "int": "Integridade via IFC"
                }
organized_files = {}
for name in names:
    organized_files[name] = []
for file in result_files:
    for name in names:
        if name + "\\" in file:
            organized_files[name].append(file)
graph_log = open('graph_values', 'w')
for key, file_list in organized_files.items():
    means = []
    for file_name in file_list:
        file = open(file_name, "r")
        time_values = []
        for line in file:
            match = re.search(r"Execution time: (\d+\.?\d*)", line)
            if match:
                time_values.append(float(match.group(1)))
        graph_log.write(file_name + " ")
        for time_value in time_values:
            graph_log.write(str(time_value) + " ")
        graph_log.write("\n\n\n")
        time_values.sort()
        time_values = time_values[3:-3]
        print(f"tamanho da lista: {len(time_values)}")
        mean = sum(time_values) / len(time_values)
        print("tamanho:")
        print(len(time_values))
        means.append(mean)

    print(x)
    print(means)
    plt.plot(range(len(x)), means, marker='o', label=name_mapping[key])
    plt.xticks(ticks=range(len(x)), labels=x)
graph_log.close()
plt.xlabel('Número de bytes iniciais')
plt.ylabel('Tempo médio em segundos')
plt.legend()
plt.show()
