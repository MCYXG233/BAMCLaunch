#!/usr/bin/env python3
import os
import re
from collections import defaultdict

# Language definitions with comment patterns
LANGUAGES = {
    'Dart': {
        'extensions': ['.dart'],
        'single_comment': r'//.*',
        'multi_comment_start': r'/\*',
        'multi_comment_end': r'\*/',
        'string_literal': r'"(?:[^"\\]|\\.)*"|r"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
    },
    'Python': {
        'extensions': ['.py'],
        'single_comment': r'#.*',
        'multi_comment_start': r'"""',
        'multi_comment_end': r'"""',
        'string_literal': r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
    },
    'C/C++': {
        'extensions': ['.c', '.cpp', '.h', '.hpp', '.cc'],
        'single_comment': r'//.*',
        'multi_comment_start': r'/\*',
        'multi_comment_end': r'\*/',
        'string_literal': r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
    },
    'CMake': {
        'extensions': ['.cmake', 'CMakeLists.txt'],
        'single_comment': r'#.*',
        'multi_comment_start': None,
        'multi_comment_end': None,
        'string_literal': r'"(?:[^"\\]|\\.)*"'
    },
    'YAML': {
        'extensions': ['.yaml', '.yml'],
        'single_comment': r'#.*',
        'multi_comment_start': None,
        'multi_comment_end': None,
        'string_literal': r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
    },
    'Markdown': {
        'extensions': ['.md'],
        'single_comment': r'<!--.*-->',
        'multi_comment_start': None,
        'multi_comment_end': None,
        'string_literal': r''
    },
    'Shell': {
        'extensions': ['.sh', '.bash'],
        'single_comment': r'#.*',
        'multi_comment_start': None,
        'multi_comment_end': None,
        'string_literal': r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
    },
    'JSON': {
        'extensions': ['.json'],
        'single_comment': None,
        'multi_comment_start': None,
        'multi_comment_end': None,
        'string_literal': r'"(?:[^"\\]|\\.)*"'
    }
}

def detect_language(file_path):
    filename = os.path.basename(file_path)
    for lang, config in LANGUAGES.items():
        for ext in config['extensions']:
            if ext.startswith('.'):
                if file_path.endswith(ext):
                    return lang
            else:
                if filename == ext:
                    return lang
    return None

def count_code_lines(file_path, lang):
    config = LANGUAGES.get(lang)
    if not config:
        return 0
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except:
        return 0
    
    # Remove string literals temporarily
    if config['string_literal']:
        content = re.sub(config['string_literal'], '', content)
    
    in_multi_comment = False
    code_lines = 0
    
    lines = content.split('\n')
    
    for line in lines:
        line = line.strip()
        
        if not line:
            continue
        
        # Handle multi-line comments
        if config['multi_comment_start'] and config['multi_comment_end']:
            if in_multi_comment:
                if re.search(config['multi_comment_end'], line):
                    in_multi_comment = False
                continue
            else:
                if re.search(config['multi_comment_start'], line):
                    in_multi_comment = True
                    # Check if comment ends on same line
                    if re.search(config['multi_comment_end'], line):
                        in_multi_comment = False
                    continue
        
        # Handle single-line comments
        if config['single_comment']:
            line = re.sub(config['single_comment'], '', line).strip()
            if not line:
                continue
        
        code_lines += 1
    
    return code_lines

def main():
    repo_path = '/workspace'
    language_stats = defaultdict(int)
    file_stats = defaultdict(list)
    
    for root, dirs, files in os.walk(repo_path):
        # Skip .git directory
        if '.git' in dirs:
            dirs.remove('.git')
        
        for file in files:
            file_path = os.path.join(root, file)
            lang = detect_language(file_path)
            if lang:
                line_count = count_code_lines(file_path, lang)
                if line_count > 0:
                    language_stats[lang] += line_count
                    rel_path = os.path.relpath(file_path, repo_path)
                    file_stats[lang].append((rel_path, line_count))
    
    # Sort file stats by line count descending
    for lang in file_stats:
        file_stats[lang].sort(key=lambda x: x[1], reverse=True)
    
    # Output results
    print('# 代码统计报告 - MCYXG233/BAMCLaunch (alpha 分支)\n')
    print('## 按语言汇总\n')
    
    for lang, count in sorted(language_stats.items(), key=lambda x: x[1], reverse=True):
        print(f'- **{lang}**: {count} 行代码')
    
    print('\n## 各语言前10个最大文件\n')
    
    for lang, files in sorted(file_stats.items(), key=lambda x: language_stats[x[0]], reverse=True):
        print(f'\n### {lang}\n')
        print('| 排名 | 文件路径 | 代码行数 | GitHub 链接 |')
        print('|------|----------|----------|-------------|')
        for i, (file_path, line_count) in enumerate(files[:10], 1):
            github_link = f'https://github.com/MCYXG233/BAMCLaunch/blob/alpha/{file_path}'
            print(f'| {i} | {file_path} | {line_count} | [查看]({github_link}) |')

if __name__ == '__main__':
    main()
