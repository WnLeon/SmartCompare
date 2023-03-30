#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
@File  : UI.py
@Author: LeonWu
@Date  : 2023/3/30 17:33
@Desc  : 
'''
import tkinter as tk
import isgrabled_files
import mvgrabled_files


def isgrabled():
    isgrabled_files.filter_filename()
    isgrabled_files.filter_garbled_lines('files.txt')
    isgrabled_files.messagebox.showinfo('isgrabled_files程序执行成功', '异常文件名请查看“filter_grabled_lines.txt”')


def mvgrabled():
    mvgrabled_files.backup()
    mvgrabled_files.messagebox.showinfo('mvgrabled_files程序执行成功','执行结果请查看“move_files.log”')


class Application(tk.Frame):
    def __init__(self, master=None):
        super().__init__(master)
        self.master = master
        self.master.title("My Application")
        self.master.geometry("400x300")
        self.pack(fill=tk.BOTH, expand=True)
        self.create_widgets()


    def create_widgets(self):
        # Create a label
        self.hello_label = tk.Label(self, text="Hello!", font=("Arial", 24), bg="#ffffff", fg="#000000")
        self.hello_label.pack(side="top", pady=20)

        # Create a button
        self.quit_button = tk.Button(self, text="Quit", command=self.master.destroy, bg="#ff0000", fg="#ffffff", font=("Arial", 16), padx=20, pady=10, bd=0)
        self.quit_button.pack(side="bottom", pady=20)

        # Create additional buttons
        self.button1 = tk.Button(self, text="Find", command=isgrabled, font=("Arial", 16), padx=20, pady=10, bd=0, bg="green")
        self.button1.pack(side="left", padx=50)

        self.button2 = tk.Button(self, text="Move", command=mvgrabled, font=("Arial", 16), padx=20, pady=10, bd=0, bg="red")
        self.button2.pack(side="right", padx=50)

        # self.button3 = tk.Button(self, text="Button 3", font=("Arial", 16), padx=20, pady=10, bd=0)
        # self.button3.pack(side="left", padx=10)

root = tk.Tk()
app = Application(master=root)
app.mainloop()
