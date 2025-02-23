import tkinter as tk
from tkinter import ttk
import requests
from bs4 import BeautifulSoup
import re


class SubCatDownloader:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("SubCat 字幕下载工具")
        self.root.geometry("800x600")
        self.language_dic = {"中文": "zh-CN", "日语": "ja"}
        self.web_url = "https://www.subtitlecat.com/"
        self.headers = {
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
        }
        self.create_widgets()

    def sanitize_filename(self, name):
        return re.sub(r'[<>:"/\\|?*]', '', name)[:50] + ".srt"

    def search_by_key(self, key):
        search_url = self.web_url + "index.php?search=" + key
        results = []
        try:
            with requests.get(search_url, headers=self.headers, timeout=10) as response:
                response.raise_for_status()
                soup = BeautifulSoup(response.content, 'html.parser')
                t_body = soup.find("tbody")
                if t_body:
                    tr_list = t_body.find_all("tr")
                    for tr in tr_list:
                        td_list = tr.find_all("td")
                        for td in td_list:
                            a = td.find("a", recursive=False)
                            if a:
                                results.append((a.text.strip() + td.text.strip(), self.web_url + str(a["href"])))
        except requests.RequestException:
            pass
        return results

    def download_file(self, url, filename, button):
        sanitized_name = self.sanitize_filename(filename)
        button.config(text="下载中...", state="disabled")
        self.root.update()
        try:
            with requests.get(url, headers=self.headers, timeout=10) as response:
                response.raise_for_status()
                soup = BeautifulSoup(response.content, 'html.parser')
                lang_code = self.language_dic[self.language_var.get()]
                down_url = soup.find("a", id=f"download_{lang_code}")
                if not down_url:
                    button.config(text="无该字幕", state="normal")
                    return
                with requests.get(self.web_url + down_url.get('href'), headers=self.headers) as dl_response:
                    dl_response.raise_for_status()
                    with open(sanitized_name, "wb") as f:
                        f.write(dl_response.content)
                    button.config(text="下载完成", state="normal")
        except requests.RequestException:
            button.config(text="下载失败", state="normal")
        except Exception:
            button.config(text="下载失败", state="normal")

    def create_widgets(self):
        self.root.grid_columnconfigure(0, weight=1)
        self.root.grid_rowconfigure(1, weight=1)

        top_frame = tk.Frame(self.root)
        top_frame.grid(row=0, column=0, columnspan=3, padx=10, pady=10, sticky="ew")
        top_frame.grid_columnconfigure(0, weight=1)

        self.search_input = tk.Entry(top_frame, font=("Arial", 12), relief="flat", borderwidth=2)
        self.search_input.grid(row=0, column=0, padx=(0, 10), pady=5, sticky="ew")
        self.search_input.bind("<Return>", self.sure_search_event)

        self.sure_button = tk.Button(top_frame, text="确认搜索", font=("Arial", 12), bg="#4CAF50", fg="white",
                                     relief="flat", command=self.sure_search)
        self.sure_button.grid(row=0, column=1, padx=10, pady=5)

        self.language_var = tk.StringVar(value="中文")
        style = ttk.Style()
        style.configure("Custom.TCombobox", font=("Arial", 12), padding=5)
        self.language_menu = ttk.Combobox(top_frame, textvariable=self.language_var,
                                          values=list(self.language_dic.keys()),
                                          style="Custom.TCombobox", state="readonly", width=10)
        self.language_menu.grid(row=0, column=2, padx=10, pady=5)

        self.results_frame = tk.Frame(self.root)
        self.results_frame.grid(row=1, column=0, columnspan=3, pady=10, sticky="nsew")

        self.canvas = tk.Canvas(self.results_frame)
        self.scrollbar = tk.Scrollbar(self.results_frame, orient="vertical", command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=self.scrollbar.set)

        self.scrollable_frame = tk.Frame(self.canvas)
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all"))
        )
        self.scrollable_frame.grid_columnconfigure(0, weight=1)
        self.scrollable_frame.grid_columnconfigure(1, weight=0)
        self.scrollable_frame.grid_columnconfigure(2, weight=0)

        self.canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        self.scrollbar.pack(side="right", fill="y")
        self.canvas.pack(side="left", fill="both", expand=True)

    def sure_search(self):
        key = self.search_input.get()
        if not key:
            tk.Label(self.scrollable_frame, text="请输入搜索关键词", font=("Arial", 12)).grid(row=0, column=0, padx=10, pady=5)
            return

        results = self.search_by_key(key)
        for widget in self.scrollable_frame.winfo_children():
            widget.destroy()

        total_width = self.canvas.winfo_width() if self.canvas.winfo_width() > 50 else 800
        button_width = 80
        spacer_width = 30
        padding = 20
        wraplength = total_width - button_width - spacer_width - padding

        if not results:
            tk.Label(self.scrollable_frame, text="未找到匹配的字幕", font=("Arial", 12)).grid(row=0, column=0, padx=10, pady=5)
        else:
            for i, (name, url) in enumerate(results):
                label = tk.Label(self.scrollable_frame, text=name, font=("Arial", 12), wraplength=wraplength, justify="left")
                label.grid(row=i, column=0, sticky="w", padx=(10, 0), pady=5)

                spacer = tk.Label(self.scrollable_frame, text="", width=3)
                spacer.grid(row=i, column=1, pady=5)

                button = tk.Button(self.scrollable_frame, text="下载", font=("Arial", 12),width= 8)
                button.grid(row=i, column=2, sticky="e", padx=(0, 10), pady=5)
                button.config(command=lambda u=url, n=name, b=button: self.download_file(u, n, b))

    def sure_search_event(self, event):
        self.sure_search()


def main():
    app = SubCatDownloader()
    app.root.mainloop()


if __name__ == "__main__":
    main()