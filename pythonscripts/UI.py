#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
@File  : UI.py
@Author: LeonWu
@Date  : 2023/3/30 17:33
@Desc  : Sample UI
'''
import tkinter as tk
import isgrabled_files
import mvgrabled_files
import tips
import threading

class Application(tk.Frame):
    def __init__(self, master=None):
        super().__init__(master)
        self.master = master
        self.master.title("Garbled Killer")
        self.master.geometry("400x300")
        self.pack(fill=tk.BOTH, expand=True)
        self.create_widgets()

    def isgrabled(self):
        isgrabled_files.start()

    def mvgrabled(self):
        mvgrabled_files.backup()

    def tip(self):
        tips.wel()

    def t_isgrabled(self):
        td2 = threading.Thread(target=self.isgrabled, daemon=True)
        td2.start()

    def t_mvgrabled(self):
        td2 = threading.Thread(target=self.mvgrabled, daemon=True)
        td2.start()

    def t_tip(self):
        td3 = threading.Thread(target=self.tip, daemon=True)
        td3.start()

    def create_widgets(self):
        # Create a label
        self.hello_label = tk.Label(self, text="Garbled Killer", font=("Arial", 24), bg="#ffffff", fg="#000000")
        self.hello_label.pack(side="top", padx=10, pady=20)

        # Create a button
        self.quit_button = tk.Button(self, text="Quit", relief="raised", command=self.master.destroy, bg="orange", fg="#ffffff", font=("Arial", 16), padx=20, pady=10, bd=0)
        self.quit_button.pack(side="bottom", pady=20)

        self.button0 = tk.Button(self, text="Help", relief="raised", command=self.t_tip, font=("Arial", 16), bg="white")
        self.button0.pack(side="top")

        # Create additional buttons
        self.button1 = tk.Button(self, text="Find", relief="raised", command=self.t_isgrabled, font=("Arial", 16), padx=20, pady=10, bd=0, bg="#4CAF50")
        self.button1.pack(side="left", padx=50)

        self.button2 = tk.Button(self, text="Move", relief="raised", command=self.t_mvgrabled, font=("Arial", 16), padx=20, pady=10, bd=0, bg="#F08080")
        self.button2.pack(side="right", padx=50)

        # self.button3 = tk.Button(self, text="Button 3", font=("Arial", 16), padx=20, pady=10, bd=0)
        # self.button3.pack(side="left", padx=10)


root = tk.Tk()

app = Application(master=root)

app.mainloop()
