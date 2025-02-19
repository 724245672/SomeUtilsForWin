import os
import tkinter as tk
from tkinter import messagebox, filedialog
import subprocess


class M3U8Downloader:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("N_m3u8DL-RE 下载脚本")
        self.root.geometry("800x600")  # 设置窗口初始大小为 800x600

        # 设置默认临时目录和保存目录
        self.tmp_dir = "D:/"
        self.save_dir = "E:/"
        self.exe_path = "N_m3u8DL-RE.exe"  # N_m3u8DL-RE 的路径

        # 检查 N_m3u8DL-RE.exe 文件是否存在
        self.check_exe()

        self.url_entry = None
        self.savename_entry = None

        self.current_page = 0  # 当前页面
        self.page_size = 10  # 每页显示的行数

        # 创建UI元素
        self.create_widgets()

        # 绑定窗口大小调整事件
        self.root.bind("<Configure>", self.on_resize)

        # 存储上次窗口大小，以检测是否真正发生了变化
        self.last_width = self.root.winfo_width()
        self.last_height = self.root.winfo_height()

        # 控制更新 m3u_label 的标志
        self.resize_in_progress = False

    def check_exe(self):
        """检查 N_m3u8DL-RE.exe 是否存在，如果不存在则让用户选择"""
        if not os.path.exists(self.exe_path):
            # 如果找不到 N_m3u8DL-RE.exe，则让用户选择
            messagebox.showwarning("警告", "未找到 N_m3u8DL-RE.exe，请选择文件位置。")
            self.exe_path = filedialog.askopenfilename(
                title="选择 N_m3u8DL-RE.exe",
                filetypes=[("可执行文件", "*.exe")]
            )
            if not self.exe_path:
                messagebox.showerror("错误", "未选择 N_m3u8DL-RE.exe，程序将退出。")
                self.root.quit()
        else:
            messagebox.showinfo("信息", f"已找到 N_m3u8DL-RE.exe: {self.exe_path}")

    def create_widgets(self):
        self.root.grid_columnconfigure(0, minsize=12)
        # 创建各个标签和输入框
        tk.Label(self.root, text="临时文件目录:", anchor="w", width=12).grid(row=0, column=0, padx=10, pady=5,
                                                                             sticky="w")
        self.tmp_entry = tk.Entry(self.root)
        self.tmp_entry.insert(0, self.tmp_dir)
        self.tmp_entry.grid(row=0, column=1, padx=10, pady=5, sticky="ew")

        # 临时文件目录选择按钮
        self.tmp_button = tk.Button(self.root, text="选择临时目录", command=self.choose_tmp_dir)
        self.tmp_button.grid(row=0, column=2, padx=10, pady=5, sticky="e")  # 按钮右对齐

        tk.Label(self.root, text="保存文件目录:", anchor="w", width=12).grid(row=1, column=0, padx=10, pady=5,
                                                                             sticky="w")
        self.save_entry = tk.Entry(self.root)
        self.save_entry.insert(0, self.save_dir)
        self.save_entry.grid(row=1, column=1, padx=10, pady=5, sticky="ew")

        # 保存文件目录选择按钮
        self.save_button = tk.Button(self.root, text="选择保存目录", command=self.choose_save_dir)
        self.save_button.grid(row=1, column=2, padx=10, pady=5, sticky="e")

        tk.Label(self.root, text="m3u8链接:", anchor="w", width=12).grid(row=2, column=0, padx=10, pady=5, sticky="w")
        self.url_entry = tk.Entry(self.root)
        self.url_entry.grid(row=2, column=1, padx=10, pady=5, sticky="ew")

        tk.Label(self.root, text="保存文件名:", anchor="w", width=12).grid(row=3, column=0, padx=10, pady=5, sticky="w")
        self.savename_entry = tk.Entry(self.root)
        self.savename_entry.grid(row=3, column=1, padx=10, pady=5, sticky="ew")

        # 按钮区
        button_frame = tk.Frame(self.root)
        button_frame.grid(row=4, column=1, columnspan=3, pady=10, sticky="nsew")

        # 设置按钮的宽度一致
        button_width = 12

        # 按钮大小一致并居中对齐
        tk.Button(button_frame, text="下载", command=self.download_single, width=button_width).pack(side=tk.LEFT,
                                                                                                    padx=50)
        tk.Button(button_frame, text="全部下载", command=self.download_all, width=button_width).pack(side=tk.LEFT,
                                                                                                     padx=50)
        tk.Button(button_frame, text="保存", command=self.save_command, width=button_width).pack(side=tk.LEFT, padx=50)

        # 显示 m3u.txt 内容的 Text 小部件，替代原来的 m3u_label
        self.m3u_text = tk.Text(self.root, height=10, wrap=tk.WORD)
        self.m3u_text.grid(row=5, column=0, columnspan=3, sticky="ew", padx=10, pady=5)

        # 创建翻页按钮
        self.prev_button = tk.Button(self.root, text="上一页", command=self.prev_page)
        self.prev_button.grid(row=6, column=0, padx=10, pady=5)

        self.next_button = tk.Button(self.root, text="下一页", command=self.next_page)
        self.next_button.grid(row=6, column=2, padx=10, pady=5)

        # 下载信息显示区域
        self.download_log = tk.Text(self.root, height=10, width=80)
        self.download_log.grid(row=7, column=0, columnspan=3, padx=10, pady=5, sticky=tk.NSEW)

        # 让下载区域根据窗口大小自动调整
        self.root.grid_rowconfigure(7, weight=1)
        self.root.grid_rowconfigure(5, weight=1)
        # 显示 m3u.txt 内容
        self.display_m3u_content()

        # 让输入框自动调整宽度
        self.root.grid_columnconfigure(1, weight=1)  # 自动调整第二列的宽度（包含输入框）

    def display_m3u_content(self):
        """刷新显示 m3u.txt 内容"""
        if os.path.exists("m3u.txt"):
            with open("m3u.txt", "r") as m3u_file:
                self.m3u_lines = m3u_file.readlines()
        else:
            self.m3u_lines = []

        # 显示当前页面的内容
        self.show_page()

    def show_page(self):
        """根据当前页面显示 m3u.txt 内容"""
        self.m3u_text.delete(1.0, tk.END)  # 清空文本框

        start_line = self.current_page * self.page_size
        end_line = start_line + self.page_size

        # 获取当前页的行
        page_lines = self.m3u_lines[start_line:end_line]

        # 显示当前页内容
        self.m3u_text.insert(tk.END, "".join(page_lines))

        # 更新按钮的状态
        if self.current_page == 0:
            self.prev_button.config(state=tk.DISABLED)
        else:
            self.prev_button.config(state=tk.NORMAL)

        if end_line >= len(self.m3u_lines):
            self.next_button.config(state=tk.DISABLED)
        else:
            self.next_button.config(state=tk.NORMAL)

    def prev_page(self):
        """跳转到上一页"""
        if self.current_page > 0:
            self.current_page -= 1
            self.show_page()

    def next_page(self):
        """跳转到下一页"""
        if (self.current_page + 1) * self.page_size < len(self.m3u_lines):
            self.current_page += 1
            self.show_page()

    def on_resize(self, event):
        """窗口调整大小时刷新 m3u.txt 内容标签"""
        new_width = event.width - 20  # 20px 边距
        new_height = event.height

        if new_width != self.last_width or new_height != self.last_height:
            # 如果宽度或高度发生了变化，才更新 m3u_label
            self.last_width = new_width
            self.last_height = new_height

            # 刷新显示 m3u.txt 内容
            self.display_m3u_content()

    def choose_tmp_dir(self):
        """选择临时文件目录"""
        self.tmp_dir = filedialog.askdirectory()
        if self.tmp_dir:
            self.tmp_entry.delete(0, tk.END)
            self.tmp_entry.insert(0, self.tmp_dir)

    def choose_save_dir(self):
        """选择保存文件目录"""
        self.save_dir = filedialog.askdirectory()
        if self.save_dir:
            self.save_entry.delete(0, tk.END)
            self.save_entry.insert(0, self.save_dir)

    def download_single(self):
        """单独下载当前输入的 URL 和文件名"""
        url = self.url_entry.get().strip()
        savename = self.savename_entry.get().strip()

        if not url or not savename:
            messagebox.showerror("错误", "请输入 URL 和保存文件名。")
            return

        command = f"N_m3u8DL-RE.exe \"{url}\" --save-name \"{savename}\" --check-segments-count false --no-log --tmp-dir \"{self.tmp_dir}\" --save-dir \"{self.save_dir}\""
        self.run_command(command)

        # 下载完成后清空输入框
        self.url_entry.delete(0, tk.END)
        self.savename_entry.delete(0, tk.END)

        # 刷新 m3u.txt 内容
        self.display_m3u_content()

    def run_command(self, command):
        """运行命令并显示输出"""
        self.download_log.delete(1.0, tk.END)  # 清空之前的日志
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        for line in process.stdout:
            self.download_log.insert(tk.END, line.decode("utf-8"))
        for line in process.stderr:
            self.download_log.insert(tk.END, line.decode("utf-8"))
        process.communicate()

    def download_all(self):
        """下载 m3u.txt 中列出的所有链接"""
        if not os.path.exists("m3u.txt"):
            messagebox.showerror("错误", "m3u.txt 文件不存在。")
            return

        with open("m3u.txt", "r") as m3u_file:
            urls = m3u_file.readlines()

        for url in urls:
            url = url.strip()
            if url:
                savename = url.split("/")[-1]  # 使用 URL 的最后一部分作为文件名
                self.url_entry.delete(0, tk.END)
                self.url_entry.insert(0, url)
                self.savename_entry.delete(0, tk.END)
                self.savename_entry.insert(0, savename)
                self.download_single()

    def save_command(self):
        """保存当前设置"""
        with open("config.txt", "w") as config_file:
            config_file.write(f"tmp_dir={self.tmp_dir}\n")
            config_file.write(f"save_dir={self.save_dir}\n")
            config_file.write(f"exe_path={self.exe_path}\n")
        messagebox.showinfo("信息", "设置已保存！")


if __name__ == "__main__":
    app = M3U8Downloader()
    app.root.mainloop()
