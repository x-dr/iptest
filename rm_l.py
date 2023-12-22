def remove_duplicates(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()

    unique_lines = list(set(lines))

    with open(filename, 'w') as file:
        file.writelines(unique_lines)

# 调用函数并传入文件名
remove_duplicates('ip.txt')
