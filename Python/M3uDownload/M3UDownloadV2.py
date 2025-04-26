import configparser
import os
import queue
import re
import threading
import tkinter as tk
from tkinter import messagebox, filedialog
import subprocess

from flask_cors import CORS


class M3U8Downloader:
    def __init__(self):

        # 读取配置文件
        self.config = configparser.ConfigParser()
        self.config.read('config.ini')

        # 加载配置项
        self.auth_key = self.config.get('Settings', 'auth_key', fallback="")
        self.port = self.config.getint('Settings', 'port', fallback=8088)
        self.tmp_dir = self.config.get('Settings', 'tmp_dir', fallback="D:/")
        self.save_dir = self.config.get('Settings', 'save_dir', fallback="E:/")
        self.exe_path = self.config.get('Settings', 'exe_path', fallback="N_m3u8DL-RE.exe")

        self.root = tk.Tk()
        self.root.title("N_m3u8DL-RE 下载工具")
        self.root.geometry("800x600")

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

        # 认证口令
        tk.Label(self.root, text="认证口令:", anchor="w", width=12).grid(row=4, column=0, padx=10, pady=5, sticky="w")
        self.auth_entry = tk.Entry(self.root)
        self.auth_entry.insert(0, self.auth_key)
        self.auth_entry.grid(row=4, column=1, padx=10, pady=5, sticky="ew")
        self.auth_entry.bind("<KeyRelease>", self.update_auth_key)

        # 端口
        tk.Label(self.root, text="服务端口:", anchor="w", width=12).grid(row=5, column=0, padx=10, pady=5, sticky="w")
        self.port_entry = tk.Entry(self.root)
        self.port_entry.insert(0, str(self.port))
        self.port_entry.grid(row=5, column=1, padx=10, pady=5, sticky="ew")
        self.port_entry.bind("<KeyRelease>", self.update_port)

        # 按钮区
        self.button_frame = tk.Frame(self.root)
        self.button_frame.grid(row=6, column=1, padx=10, pady=10, sticky="ew")  #

        # 配置 button_frame 的列权重
        self.button_frame.grid_columnconfigure(0, weight=1)
        self.button_frame.grid_columnconfigure(1, weight=1)
        self.button_frame.grid_columnconfigure(2, weight=1)
        self.button_frame.grid_columnconfigure(3, weight=1)
        self.button_frame.grid_columnconfigure(4, weight=1)

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
        self.stop_button.grid(row=0, column=3, sticky="", padx=5)

        self.save_config_button = tk.Button(self.button_frame, text="保存配置", command=self.save_config, width=12)
        self.save_config_button.grid(row=0, column=4, sticky="e", padx=5)

        # 创建带有滚动条的 Frame 来显示 m3u.txt 内容
        m3u_frame = tk.Frame(self.root)
        m3u_frame.grid(row=7, column=0, columnspan=3, sticky="nsew", padx=10, pady=5)

        scrollbar = tk.Scrollbar(m3u_frame, orient=tk.VERTICAL)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.m3u_text = tk.Text(m3u_frame, height=10, wrap=tk.WORD, yscrollcommand=scrollbar.set)
        self.m3u_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        scrollbar.config(command=self.m3u_text.yview)

        # 下载信息显示区域
        self.download_log = tk.Text(self.root, height=10, width=80)
        self.download_log.grid(row=8, column=0, columnspan=3, padx=10, pady=5, sticky=tk.NSEW)

        self.root.grid_rowconfigure(7, weight=1)
        self.root.grid_rowconfigure(8, weight=1)

        self.display_m3u_content()

    def save_config(self):
        config = configparser.ConfigParser()

        config['Settings'] = {
            'auth_key': self.auth_key,
            'port': self.port,
            'tmp_dir': self.tmp_dir,
            'save_dir': self.save_dir,
            'exe_path':self.exe_path
        }

        # 尝试创建配置文件
        try:
            with open('config.ini', 'w') as configfile:
                config.write(configfile)
            messagebox.showinfo("保存成功", "配置已保存！")
        except Exception as e:
            messagebox.showerror("保存失败", f"保存配置时出错：{e}")

    def update_auth_key(self, event=None):
        """监听口令输入框更新"""
        self.auth_key = self.auth_entry.get().strip()

    def update_port(self, event=None):
        """监听端口输入框更新"""
        self.port = self.port_entry.get().strip()
        self.port = int(self.port) if self.port.isdigit() else 8088

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

def start_flask_server(auth_key, exe_path, tmp_dir, save_dir, m3u_file, port=8088):
    from flask import Flask, request, jsonify

    app = Flask(__name__)

    CORS(app, resources={r"/*": {"origins": "http://localhost"}})

    @app.route('/', methods=['POST'])
    def json_post():
        data = request.get_json()
        auth = request.headers.get('Authorization')
        if auth and auth != auth_key:
            return jsonify({"status": "error", "message": "无效授权"}), 401

        # 接收并处理 m3u8 请求体
        url = data.get("url")
        save_name = data.get("name")
        if not url or not save_name:
            return jsonify({"status": "error", "message": "缺少url或文件名"}), 400

        with open(m3u_file, 'a') as m3u_txt:
            m3u_txt.write(f"\"{exe_path}\" \"{url}\" --save-name \"{save_name}\" --tmp-dir \"{tmp_dir}\" --save-dir \"{save_dir}\"\n")

        return jsonify({"status": "success", "message": "请求成功"}), 200

    app.run(host='127.0.0.1', port=port)  # 使用动态端口

def main():
    app = M3U8Downloader()

    def run_flask_with_dynamic_key():
        while not hasattr(app, 'auth_key'):
            pass  # 等待 GUI 初始化完成
        start_flask_server(
            auth_key=app.auth_key,
            exe_path=app.exe_path,
            tmp_dir=app.tmp_dir,
            save_dir=app.save_dir,
            m3u_file="m3u.txt",
            port=app.port  # 使用动态端口
        )

    threading.Thread(target=run_flask_with_dynamic_key, daemon=True).start()

    app.root.mainloop()

if __name__ == "__main__":
    main()