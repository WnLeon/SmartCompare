#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
@File  : mvgrabled_files.py
@Author: LeonWu
@Date  : 2023/3/29 15:41
@Desc  : delete files that's filename is grabled
'''
import os
import logging
import tkinter as tk
from tkinter import filedialog,messagebox
import shutil

def backup_files(dest_dir,source_dir,file_path):
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    file_handler = logging.FileHandler("move_files.log",encoding="utf-8")
    file_handler.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    success_count = 0
    failure_count = 0
    # Read the file list
    with open(file_path, 'r',encoding='utf-8') as f:
        file_list = f.read().splitlines()

    # Move each file
    for file_path in file_list:
        # Extract the directory structure
        rel_path = os.path.relpath(file_path, source_dir)
        dest_path = os.path.join(dest_dir, rel_path)
        dest_dirname = os.path.dirname(dest_path)
        try:
            # Create the corresponding directories in the new directory
            os.makedirs(dest_dirname, exist_ok=True)
            # Move the file to the new directory
            shutil.move(file_path, dest_path)
            success_count += 1
            logger.info(f"Successfully backup {file_path}")
            print(f"Successfully backup {file_path}")
        except Exception as e:
            failure_count += 1
            logger.error(f"Failed to backup {file_path}: {e}")
            print(f"Failed to backup {file_path}: {e}")
    logger.info(f"Backuped {success_count} files, failed to backup {failure_count} files")
    return f"Backuped {success_count} files, failed to backup {failure_count} files"

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

def backup():
    root = tk.Tk()
    root.withdraw()
    messagebox.showinfo('Info',"Please choose new_backup_dir")
    backup_path = filedialog.askdirectory()
    messagebox.showinfo('Info',"Please choose old_backup_dir")
    source_path = filedialog.askdirectory()
    messagebox.showwarning('Warning',"Please choose filter_grabled_lines.txt that you have confirmed")
    dir_path = filedialog.askopenfilename()
    result = backup_files(backup_path,source_path,dir_path)
    print(result)

def deletfiles(backup_path):
    os.remove(backup_path)

if __name__ == "__main__":
    #删除乱码名文件
    backup()
   # deletfiles()
    messagebox.showinfo('mvgrabled_files程序执行成功','执行结果请查看“move_files.log”')
