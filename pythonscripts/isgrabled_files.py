#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
@File  : isgrabled_files.py
@Author: LeonWu
@Date  : 2023/3/29 10:08
@Desc  : find files that's filename is grabled
'''

import os
import tkinter as tk
from tkinter import filedialog,messagebox

def filter_filenames(dir_path):
    """Function to filter out filenames with garbled characters"""
    with open("files.txt", "a", encoding="utf-8") as e:
            for entry in os.scandir(dir_path):
                if entry.is_file():
                    e.write(entry.path + "\n")
                elif entry.is_dir():
                    filter_filenames(entry.path)
def filter_garbled_lines(file_list):
    with open('filter_garbled_lines.txt','ab')as e:
        with open(file_list, 'rb') as f:
            for file_name in f:
                try:
                    file_name.decode("utf-8").encode("gbk")
                    # print (file_name, "...")
                except UnicodeEncodeError:
                    print (file_name, "中奖")
                    e.write(file_name)

def filter_filename():
    root = tk.Tk()
    root.withdraw()
    dir_path = filedialog.askdirectory()
    filter_filenames(dir_path)

if __name__ == "__main__":
    #过滤乱码名文件
    filter_filename()
    filter_garbled_lines('files.txt')
    messagebox.showinfo('isgrabled_files程序执行成功', '异常文件名请查看“filter_grabled_lines.txt”')







