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
from tkinter import filedialog

def filter_filenames(dir_path):
    """Function to filter out filenames with garbled characters"""
    with open("files.txt", "a", encoding="utf-8") as e:
        with open("grabled_files.txt", "a", encoding="utf-8") as f:
            for entry in os.scandir(dir_path):
                if entry.is_file():
                    e.write(entry.path + "\n")
                    if not entry.name.isprintable():
                        f.write(entry.path + "\n")
                elif entry.is_dir():
                    filter_filenames(entry.path)

def filter_filename():
    root = tk.Tk()
    root.withdraw()
    dir_path = filedialog.askdirectory()
    filter_filenames(dir_path)


if __name__ == "__main__":
    #过滤乱码名文件
    filter_filename()






