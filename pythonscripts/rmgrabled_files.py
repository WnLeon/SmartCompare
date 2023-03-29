#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
@File  : rmgrabled_files.py
@Author: LeonWu
@Date  : 2023/3/29 15:41
@Desc  : delete files that's filename is grabled
'''
import os
import logging
import tkinter as tk
from tkinter import filedialog


def delete_files(file_path):
    """Function to delete files listed in a text file and return success or failure message"""
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    file_handler = logging.FileHandler("delete_files.log",encoding="utf-8")
    file_handler.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    success_count = 0
    failure_count = 0
    with open(file_path, "r",encoding="utf-8") as f:
        for line in f:
            file_path = line.strip()
            print(file_path)
            try:
                os.remove(file_path)
                success_count += 1
                logger.info(f"Successfully deleted {file_path}")
                print(f"Successfully deleted {file_path}")
            except Exception as e:
                failure_count += 1
                logger.error(f"Failed to delete {file_path}: {e}")
                print(f"Failed to delete {file_path}: {e}")
    logger.info(f"Deleted {success_count} files, failed to delete {failure_count} files")
    return f"Deleted {success_count} files, failed to delete {failure_count} files"

if __name__ == "__main__":
    #删除乱码名文件
    root = tk.Tk()
    root.withdraw()
    dir_path = filedialog.askopenfilename()
    result=delete_files(dir_path)
    print(result)
