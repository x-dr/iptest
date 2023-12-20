import pandas as pd

# 读取CSV文件
df = pd.read_csv('latest.csv')

# 创建一个新的列，其中包含"峰值速度"列的值，但是已经去掉了单位（kB/s）
df['峰值速度数值'] = df['峰值速度'].str.replace(' kB/s', '').astype(float)

# 按照"峰值速度数值"列的值进行排序
df_sorted = df.sort_values(by='峰值速度数值', ascending=False)

# 将排序后的DataFrame保存回CSV文件
df_sorted.to_csv('latest_sorted.csv', index=False)