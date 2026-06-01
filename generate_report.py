#!/usr/bin/env python3
import subprocess
import csv
from collections import defaultdict

repo_path = '/workspace'
github_base_url = 'https://github.com/MCYXG233/BAMCLaunch/blob/alpha'

# Run cloc and get per-file stats as CSV
result = subprocess.run(
    ['cloc', '--exclude-dir=.git', '--by-file', '--csv', '.'],
    cwd=repo_path,
    capture_output=True,
    text=True
)

# Parse CSV
lines = result.stdout.strip().split('\n')
header = lines[0].split(',')
data = lines[1:]

# Organize files by language
lang_files = defaultdict(list)

for line in csv.reader(lines[2:], quotechar='"'):
    if len(line) < 5:
        continue
    filename = line[1]
    language = line[0]
    blank = int(line[2])
    comment = int(line[3])
    code = int(line[4])
    
    if code > 0:
        lang_files[language].append({
            'path': filename,
            'code': code
        })

# Sort files by code lines descending
for lang in lang_files:
    lang_files[lang].sort(key=lambda x: x['code'], reverse=True)

# Get total per language
total_result = subprocess.run(
    ['cloc', '--exclude-dir=.git', '--csv', '.'],
    cwd=repo_path,
    capture_output=True,
    text=True
)

total_lines = total_result.stdout.strip().split('\n')
lang_totals = {}

for line in csv.reader(total_lines[2:], quotechar='"'):
    if len(line) < 5:
        continue
    language = line[0]
    code = int(line[4])
    lang_totals[language] = code

# Generate report
print('# 代码统计报告 - MCYXG233/BAMCLaunch (alpha 分支)\n')
print('## 按语言汇总\n')

for lang, total in sorted(lang_totals.items(), key=lambda x: x[1], reverse=True):
    print(f'- **{lang}**: {total} 行代码')

print('\n## 各语言前10个最大文件\n')

for lang in sorted(lang_totals.keys(), key=lambda x: lang_totals[x], reverse=True):
    if lang not in lang_files:
        continue
    files = lang_files[lang]
    print(f'\n### {lang}\n')
    print('| 排名 | 文件路径 | 代码行数 | GitHub 链接 |')
    print('|------|----------|----------|-------------|')
    for i, file_info in enumerate(files[:10], 1):
        github_link = f'{github_base_url}/{file_info["path"]}'
        print(f'| {i} | {file_info["path"]} | {file_info["code"]} | [查看]({github_link}) |')
