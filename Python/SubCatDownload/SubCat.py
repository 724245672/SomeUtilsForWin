# 这是一个用来下载subcat网址的字幕的小工具

import tkinter as tk
from tkinter import messagebox

from bs4 import BeautifulSoup
import requests

class SubCatDownloader:

    def __init__(self):
        self.root = tk.Tk()
        self.root.title("SubCat 字幕下载工具")
        self.root.geometry("800x600")  # 设置窗口初始大小为 800x600
        self.language_dic = {"中文": "zh-CN", "日语": ""}
        self.web_url = "https://www.subtitlecat.com/"
        self.headers = {
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"}
        self.create_widgets()

    def search_by_key(self,key):

       search_url = self.web_url + "index.php?search=" + key
       results = []
       with requests.get(search_url,headers=self.headers) as response:
           soup = BeautifulSoup(response.content, 'html.parser')
           t_body = soup.find("tbody")
           if t_body:
               tr_list = t_body.find_all("tr")
               for tr in tr_list[:20]:
                   td_list = tr.find_all("td")
                   for td in td_list:
                       a = td.find("a", recursive=False)
                       if a:
                           results.append((a.text.strip() + td.text.strip(),self.web_url + str(a["href"])))
       return results

    def download_file(self, url, filename):

        with requests.get(url, headers=self.headers) as response:
            soup = BeautifulSoup(response.content, 'html.parser')
            down_url = soup.find("a", id="download_zh-CN")
            if not down_url:
                messagebox.showerror("下载失败",f"不存在中文字幕")
                return
        try:
            response = requests.get(self.web_url + down_url.get('href'))
            if response.status_code == 200:
                with open(filename, "wb") as f:
                    f.write(response.content)
                messagebox.showinfo("下载成功", f"{filename} 下载完成!")
            else:
                messagebox.showerror("下载失败", f"无法下载 {filename}. 状态码: {response.status_code}")
        except Exception as e:
            messagebox.showerror("下载失败", f"发生错误: {e}")

    def create_widgets(self):

        self.root.grid_columnconfigure(0, weight=1)
        self.root.grid_rowconfigure(1, weight=1)
        #这里先弄个输入框,输入内容
        self.search_input = tk.Entry(self.root)
        self.search_input.grid(row=0, column=0, padx=10, pady=5, sticky="ew")

        self.search_input.bind("<Return>", self.sure_search_event)
        #弄个选择字幕语言类型
        # option_var = tk.StringVar(value=list(self.language_dic.keys()))
        #
        # self.lan_button = tk.Listbox(self.root, listvariable=option_var,height=2)
        # self.lan_button.grid(row=0, column=2, padx=10, pady=5, sticky="e")  # 按钮右对齐

        # 再弄个按钮,确认搜索
        self.sure_button = tk.Button(self.root, text="确认搜索", command=self.sure_search)
        self.sure_button.grid(row=0, column=1, padx=10, pady=5, sticky="e")  # 按钮右对齐

        # down_frame = tk.Frame(self.root)
        # down_frame.grid(row=1, column=0, columnspan=2, pady=10, sticky="nsew")

        # tk.Label(down_frame, text="字幕文件名", anchor="e", width=12).pack(side=tk.LEFT,padx=10)
        # tk.Label(down_frame, text="字幕下载", anchor="w", width=12).pack(side=tk.RIGHT, padx=50)

        # 创建一个滚动框架来显示搜索结果
        self.results_frame = tk.Frame(self.root)
        self.results_frame.grid(row=1, column=0, columnspan=2, pady=10, sticky="nsew")

        # 添加滚动条
        self.canvas = tk.Canvas(self.results_frame)
        self.scrollbar = tk.Scrollbar(self.results_frame, orient="vertical", command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=self.scrollbar.set)

        # 将滚动条添加到画布上
        self.scrollable_frame = tk.Frame(self.canvas)
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all"))
        )

        # 创建一个窗口显示滚动区域
        self.canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        self.scrollbar.pack(side="right", fill="y")
        self.canvas.pack(side="left", fill="both", expand=True)

    def sure_search(self):
        key = self.search_input.get()
        results = self.search_by_key(key)

        # 清除之前的搜索结果
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()

        i = 0
        for name, url in results:
            # 显示字幕名称
            label = tk.Label(self.scrollable_frame, text=name)
            label.grid(row=i, column=0, sticky="ew", padx=10, pady=5)

            # 创建一个 Button，点击时触发下载
            button = tk.Button(self.scrollable_frame, text="下载",
                               command=lambda url1=url, name1=name: self.download_file(url, name + ".srt"))
            button.grid(row=i, column=1, sticky="e", padx=10, pady=5)

            i += 1

    def sure_search_event(self, event):
        self.sure_search()


def main():
    app = SubCatDownloader()
    app.root.mainloop()

if __name__ == "__main__":
    main()
