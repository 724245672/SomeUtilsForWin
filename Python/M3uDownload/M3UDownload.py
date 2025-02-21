import os
import queue
import re
import threading
import tkinter as tk
from tkinter import messagebox, filedialog
import subprocess


class M3U8Downloader:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("N_m3u8DL-RE 下载工具")
        self.root.geometry("800x600")

        # 设置默认临时目录和保存目录
        self.tmp_dir = "D:/"
        self.save_dir = "E:/"
        self.exe_path = "N_m3u8DL-RE.exe"

        # 检查 N_m3u8DL-RE.exe 文件是否存在
        self.check_exe()

        self.url_entry = None
        self.save_name_entry = None

        self.process = None

        self.stop_flag = False

        # 创建UI元素
        self.create_widgets()

        # 绑定窗口大小调整事件
        self.root.bind("<Configure>", self.on_resize)

        # 存储上次窗口大小
        self.last_width = self.root.winfo_width()
        self.last_height = self.root.winfo_height()

    def check_exe(self):
        """检查 N_m3u8DL-RE.exe 是否存在，如果不存在则让用户选择"""
        if not os.path.exists(self.exe_path):
            messagebox.showwarning("警告", "未找到 N_m3u8DL-RE.exe，请选择文件位置。")
            self.exe_path = filedialog.askopenfilename(
                title="选择 N_m3u8DL-RE.exe",
                filetypes=[("可执行文件", "*.exe")]
            )
            if not self.exe_path:
                messagebox.showerror("错误", "未选择 N_m3u8DL-RE.exe，程序将退出。")
                self.root.quit()

    def display_m3u_content(self):
        """刷新显示 m3u.txt 内容"""
        self.m3u_text.delete(1.0, tk.END)
        if os.path.exists("m3u.txt"):
            with open("m3u.txt", "r") as m3u_file:
                content = m3u_file.read()
                self.m3u_text.insert(tk.END, content)

    def create_widgets(self):
        self.root.grid_columnconfigure(0, minsize=12)
        self.root.grid_columnconfigure(1, weight=1)  # 确保 column 1 有权重
        self.root.grid_columnconfigure(2, minsize=100)  # 给 column 2 设置最小宽度以容纳按钮

        # 创建各个标签和输入框
        tk.Label(self.root, text="临时文件目录:", anchor="w", width=12).grid(row=0, column=0, padx=10, pady=5,
                                                                             sticky="w")
        self.tmp_entry = tk.Entry(self.root)
        self.tmp_entry.insert(0, self.tmp_dir)
        self.tmp_entry.grid(row=0, column=1, padx=10, pady=5, sticky="ew")

        self.tmp_button = tk.Button(self.root, text="选择临时目录", command=self.choose_tmp_dir)
        self.tmp_button.grid(row=0, column=2, padx=10, pady=5, sticky="e")

        tk.Label(self.root, text="保存文件目录:", anchor="w", width=12).grid(row=1, column=0, padx=10, pady=5,
                                                                             sticky="w")
        self.save_entry = tk.Entry(self.root)
        self.save_entry.insert(0, self.save_dir)
        self.save_entry.grid(row=1, column=1, padx=10, pady=5, sticky="ew")

        self.save_button = tk.Button(self.root, text="选择保存目录", command=self.choose_save_dir)
        self.save_button.grid(row=1, column=2, padx=10, pady=5, sticky="e")

        tk.Label(self.root, text="m3u8链接:", anchor="w", width=12).grid(row=2, column=0, padx=10, pady=5, sticky="w")
        self.url_entry = tk.Entry(self.root)
        self.url_entry.grid(row=2, column=1, padx=10, pady=5, sticky="ew")

        tk.Label(self.root, text="保存文件名:", anchor="w", width=12).grid(row=3, column=0, padx=10, pady=5, sticky="w")
        self.save_name_entry = tk.Entry(self.root)
        self.save_name_entry.grid(row=3, column=1, padx=10, pady=5, sticky="ew")

        # 按钮区
        self.button_frame = tk.Frame(self.root)
        self.button_frame.grid(row=4, column=1, padx=10, pady=10, sticky="ew")  # 只占 column 1，与输入框对齐

        # 配置 button_frame 的列权重
        self.button_frame.grid_columnconfigure(0, weight=1)
        self.button_frame.grid_columnconfigure(1, weight=1)
        self.button_frame.grid_columnconfigure(2, weight=1)
        self.button_frame.grid_columnconfigure(3, weight=1)

        button_width = 12
        # 左对齐的 "下载" 按钮
        self.download_button = tk.Button(self.button_frame, text="下载", command=self.download_single,
                                         width=button_width)
        self.download_button.grid(row=0, column=0, sticky="w", padx=5)

        # 居中的 "全部下载" 按钮
        self.download_all_button = tk.Button(self.button_frame, text="全部下载", command=self.download_all,
                                             width=button_width)
        self.download_all_button.grid(row=0, column=1, sticky="")

        # 右对齐的 "保存" 按钮
        self.save_button_main = tk.Button(self.button_frame, text="保存", command=self.save_command, width=button_width)
        self.save_button_main.grid(row=0, column=2, sticky="", padx=5)

        # 添加 "停止" 按钮
        self.stop_button = tk.Button(self.button_frame, text="停止下载", command=self.stop_command, width=button_width)
        self.stop_button.grid(row=0, column=3, sticky="e", padx=5)

        # 创建带有滚动条的 Frame 来显示 m3u.txt 内容
        m3u_frame = tk.Frame(self.root)
        m3u_frame.grid(row=5, column=0, columnspan=3, sticky="nsew", padx=10, pady=5)

        scrollbar = tk.Scrollbar(m3u_frame, orient=tk.VERTICAL)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.m3u_text = tk.Text(m3u_frame, height=10, wrap=tk.WORD, yscrollcommand=scrollbar.set)
        self.m3u_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        scrollbar.config(command=self.m3u_text.yview)

        # 下载信息显示区域
        self.download_log = tk.Text(self.root, height=10, width=80)
        self.download_log.grid(row=6, column=0, columnspan=3, padx=10, pady=5, sticky=tk.NSEW)

        self.root.grid_rowconfigure(6, weight=1)
        self.root.grid_rowconfigure(5, weight=1)

        self.display_m3u_content()

    def stop_command(self):
        self.stop_flag = True
        """停止正在执行的命令"""
        if self.process:
            self.process.terminate()
            self.process = None
            self.download_log.insert(tk.END, "\n命令已被停止\n")
            self.download_log.yview(tk.END)
            self.run_command(f"taskkill /F /IM \"N_m3u8DL-RE.exe\"")

    def on_resize(self, event):
        """窗口调整大小时刷新内容"""
        new_width = event.width
        new_height = event.height

        if new_width != self.last_width or new_height != self.last_height:
            self.last_width = new_width
            self.last_height = new_height
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

    def get_command(self):

        url = self.url_entry.get().strip()
        save_name = self.save_name_entry.get().strip()

        if not url or not save_name:
            messagebox.showerror("错误", "请输入 URL 和保存文件名。")
            return

        if not bool(re.match(r'^(https?|ftp)://[^\s/$.?#].[^\s]*\.m3u8$', url, re.IGNORECASE)):
            messagebox.showerror("错误", "请输入正确的 URL 。")
            return

        if os.path.exists("m3u.txt"):
            with open("m3u.txt", "r", encoding='gbk') as m3u_txt:
                if url in m3u_txt.read():
                    messagebox.showerror("错误", "输入的URL已存在 。")
                    return

        return f"\"{self.exe_path}\" \"{url}\" --save-name \"{save_name}\" --check-segments-count false --no-log --tmp-dir \"{self.tmp_dir}\" --save-dir \"{self.save_dir}\""

    def download_single(self):

        self.stop_flag = False

        command = self.get_command()

        if not command:
            return

        self.run_command(command)  # 执行命令并获取线程

        self.url_entry.delete(0, tk.END)
        self.save_name_entry.delete(0, tk.END)

    def run_command(self, command, callback=None):
        """运行命令并显示输出"""
        self.download_log.delete(1.0, tk.END)  # 清空之前的日志

        # 用于接收线程的输出结果
        result_queue = queue.Queue()

        def execute():
            try:
                # 使用 Popen 运行命令
                self.process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

                # 读取并显示标准输出
                for line in self.process.stdout:
                    result_queue.put(line.decode("gbk"))

                # 读取并显示标准错误
                for line in self.process.stderr:
                    result_queue.put(line.decode("gbk"))

                # 等待命令执行完成
                self.process.communicate()

                # 返回执行状态
                return_code = self.process.returncode
                if return_code != 0:
                    result_queue.put(f"命令执行失败，返回码: {return_code}")
                else:
                    result_queue.put("命令执行成功")
            except OSError as e:
                result_queue.put(f"命令执行失败: {str(e)}")
            except Exception as e:
                result_queue.put(f"发生错误: {str(e)}")
            finally:
                # 在线程结束时调用回调
                if callback:
                    self.root.after(0, callback)

        thread = threading.Thread(target=execute, daemon=True)
        thread.start()

        # 定期检查队列并更新 UI
        self.download_log.after(100, self.update_log, result_queue)

    def update_log(self, result_queue):
        """定期检查线程结果并更新UI"""
        try:
            while True:
                output = result_queue.get_nowait()  # 非阻塞式获取
                self.download_log.insert(tk.END, output)
                self.download_log.yview(tk.END)  # 滚动到最新行
        except queue.Empty:
            pass  # 如果队列空，直接返回

        # 继续定时检查队列
        self.download_log.after(100, self.update_log, result_queue)

    def download_all(self):

        self.stop_flag = False

        """下载 m3u.txt 中列出的所有链接"""
        if not os.path.exists("m3u.txt"):
            messagebox.showerror("错误", "m3u.txt 文件不存在。")
            return

        with open("m3u.txt", "r") as m3u_file:
            command = m3u_file.readline()
            self.run_command(command,self.after_command_finished)

    def after_command_finished(self):

        if self.stop_flag:
            return

        """命令完成后更新 UI 并运行下一个任务"""
        with open("m3u.txt", "r") as m3u_file:
            commands = m3u_file.readlines()
            if len(commands) >= 2:
                self.display_m3u_content()
                self.run_command(commands[1], self.after_command_finished)
        with open("m3u.txt", "w") as m3u_file:
            if len(commands[1:]) != 0:
                m3u_file.writelines(commands[1:])

    def save_command(self):

        command = self.get_command()

        if not command:
            return

        with open("m3u.txt", "a+", encoding='gbk') as m3u_txt:
            m3u_txt.write(command+"\r")

        self.url_entry.delete(0, tk.END)
        self.save_name_entry.delete(0, tk.END)
        self.display_m3u_content()

def main():
    app = M3U8Downloader()
    app.root.mainloop()

if __name__ == "__main__":
    main()