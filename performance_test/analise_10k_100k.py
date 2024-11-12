import os
import matplotlib.pyplot as plt
import re
import statistics
import math
x = [10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]

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
graph_log = open('graph_values_10_100k', 'w')
for key, file_list in organized_files.items():
    means = []
    file_list = filter(lambda x: "10000" in x or "20000" in x or "30000" in x or "40000" in x or "50000" in x or "60000" in x or "70000" in x or "80000" in x or "90000" in x or "100000" in x, file_list)
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
        time_values.sort()
        mean = statistics.mean(time_values)
        stddev = statistics.stdev(time_values)
        z = 1.96
        n = len(time_values)  # Tamanho da amostra
        error_margin = z * (stddev / math.sqrt(n))
        print(f"mean: {mean}")
        print(f"stdev: {stddev}")
        print(f"error_margin: {error_margin}")
        print("tamanho:")
        print(len(time_values))
        graph_log.write(f"z:{z} ")
        graph_log.write(f"mean:{mean} ")
        graph_log.write(f"stdev:{stddev} ")
        graph_log.write(f"error_margin:{error_margin}")
        graph_log.write("\n\n\n")
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
