import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk

MODE_VALUES = {
    "Normal": "1",
    "Protected": "2",
}

OP_VALUES = {
    "Add": "1",
    "Subtract": "2",
    "Multiply": "3",
    "Divide": "4",
}


class OperationWindow(tk.Toplevel):
    def __init__(self, app: "SecurityApp", op_label: str) -> None:
        super().__init__(app)
        self.app = app
        self.op_label = op_label
        self.title(f"{op_label} Function")
        self.geometry("560x320")
        self.resizable(False, False)

        self._build_ui()
        self.protocol("WM_DELETE_WINDOW", self._on_close)

    def _build_ui(self) -> None:
        self.configure(bg="#f7f3e9")

        title = tk.Label(
            self,
            text=f"{self.op_label} Operation",
            bg="#1d2a37",
            fg="#f7f3e9",
            font=("Cambria", 16, "bold"),
            pady=10,
        )
        title.pack(fill="x")

        form = tk.Frame(self, bg="#f7f3e9")
        form.pack(fill="x", padx=16, pady=14)

        tk.Label(form, text="Mode", bg="#f7f3e9", fg="#22313f", font=("Segoe UI", 10, "bold")).grid(
            row=0, column=0, sticky="w", padx=(0, 8), pady=6
        )
        self.mode_combo = ttk.Combobox(form, values=list(MODE_VALUES.keys()), state="readonly", width=16)
        self.mode_combo.grid(row=0, column=1, sticky="w", pady=6)
        self.mode_combo.set("Protected")

        tk.Label(form, text="Input A", bg="#f7f3e9", fg="#22313f", font=("Segoe UI", 10, "bold")).grid(
            row=1, column=0, sticky="w", pady=6
        )
        self.input_a = ttk.Entry(form, width=24)
        self.input_a.grid(row=1, column=1, sticky="w", pady=6)

        tk.Label(form, text="Input B", bg="#f7f3e9", fg="#22313f", font=("Segoe UI", 10, "bold")).grid(
            row=2, column=0, sticky="w", pady=6
        )
        self.input_b = ttk.Entry(form, width=24)
        self.input_b.grid(row=2, column=1, sticky="w", pady=6)

        buttons = tk.Frame(self, bg="#f7f3e9")
        buttons.pack(fill="x", padx=16, pady=4)

        run_btn = tk.Button(
            buttons,
            text="Run Function",
            command=self._run_operation,
            bg="#aa3f2f",
            fg="white",
            activebackground="#8d3123",
            activeforeground="white",
            relief="flat",
            padx=12,
            pady=7,
            font=("Segoe UI", 10, "bold"),
        )
        run_btn.pack(side="left")

        close_btn = tk.Button(
            buttons,
            text="Close",
            command=self._on_close,
            bg="#5c4141",
            fg="white",
            activebackground="#4a3434",
            activeforeground="white",
            relief="flat",
            padx=12,
            pady=7,
            font=("Segoe UI", 10, "bold"),
        )
        close_btn.pack(side="left", padx=10)

        self.info_label = tk.Label(
            self,
            text="Each run opens a dedicated console window for this function.",
            bg="#f7f3e9",
            fg="#3f5160",
            font=("Segoe UI", 10),
            anchor="w",
        )
        self.info_label.pack(fill="x", padx=16, pady=(8, 0))

    def _run_operation(self) -> None:
        mode_label = self.mode_combo.get().strip()
        a = self.input_a.get().strip()
        b = self.input_b.get().strip()

        if mode_label not in MODE_VALUES:
            messagebox.showerror("Invalid Mode", "Select a valid mode.", parent=self)
            return
        if not a or not b:
            messagebox.showerror("Missing Inputs", "Enter both Input A and Input B.", parent=self)
            return

        if not self.app.build_project():
            return

        mode = MODE_VALUES[mode_label]
        op = OP_VALUES[self.op_label]
        title = f"SecureProject - {self.op_label} - {mode_label}"
        cmd_line = (
            f'title {title} & '
            f'SecureProject.exe {mode} {op} {a} {b} & '
            'echo. & echo [Session complete] & pause'
        )

        try:
            proc = subprocess.Popen(
                ["cmd.exe", "/k", cmd_line],
                cwd=str(self.app.project_dir),
                creationflags=subprocess.CREATE_NEW_CONSOLE,
            )
        except Exception as exc:
            messagebox.showerror("Launch Error", str(exc), parent=self)
            return

        self.app.append_log(
            f"Launched PID {proc.pid}: Function={self.op_label}, Mode={mode_label}, A={a}, B={b}"
        )
        self.app.status_label.config(text=f"Status: launched {self.op_label} session")

    def _on_close(self) -> None:
        self.app.operation_windows.pop(self.op_label, None)
        self.destroy()


class SecurityApp(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("Assembly Protected Runtime Controller")
        self.geometry("980x620")
        self.minsize(860, 560)

        self.project_dir = Path(__file__).resolve().parent
        self.executable = self.project_dir / "SecureProject.exe"
        self.ml_path = self.project_dir.parent / "ML.EXE"
        self.link_path = self.project_dir.parent / "LINK32.EXE"
        self.operation_windows: dict[str, OperationWindow] = {}
        self.activity_var = tk.StringVar(value="No sessions launched yet.")

        self._build_ui()

    def _build_ui(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")
        self.configure(bg="#f7f3e9")

        header = tk.Frame(self, bg="#1d2a37")
        header.pack(fill="x")

        title = tk.Label(
            header,
            text="Assembly Protected Runtime Framework",
            fg="#f7f3e9",
            bg="#1d2a37",
            font=("Cambria", 20, "bold"),
            pady=12,
        )
        title.pack(anchor="w", padx=18)

        subtitle = tk.Label(
            header,
            text="Select a function from the menu. Each function opens in its own operation window.",
            fg="#d5dfeb",
            bg="#1d2a37",
            font=("Cambria", 11),
            pady=2,
        )
        subtitle.pack(anchor="w", padx=18, pady=(0, 12))

        menu_frame = tk.LabelFrame(self, text="Function Menu", bg="#f7f3e9", fg="#22313f", padx=12, pady=10)
        menu_frame.pack(fill="x", padx=18, pady=(12, 8))

        for idx, op_label in enumerate(OP_VALUES.keys()):
            btn = tk.Button(
                menu_frame,
                text=f"Open {op_label}",
                command=lambda op=op_label: self.open_operation_window(op),
                bg="#445c73",
                fg="white",
                activebackground="#36495d",
                activeforeground="white",
                relief="flat",
                padx=12,
                pady=8,
                font=("Segoe UI", 10, "bold"),
                width=14,
            )
            btn.grid(row=0, column=idx, padx=8, pady=6)

        controls = tk.Frame(self, bg="#f7f3e9")
        controls.pack(fill="x", padx=18, pady=(6, 8))

        build_btn = tk.Button(
            controls,
            text="Build Project",
            command=self.build_project,
            bg="#2f6f4f",
            fg="white",
            activebackground="#275c42",
            activeforeground="white",
            relief="flat",
            padx=12,
            pady=8,
            font=("Segoe UI", 10, "bold"),
        )
        build_btn.pack(side="left")

        clear_btn = tk.Button(
            controls,
            text="Clear Log",
            command=self.clear_log,
            bg="#5c4141",
            fg="white",
            activebackground="#4a3434",
            activeforeground="white",
            relief="flat",
            padx=12,
            pady=8,
            font=("Segoe UI", 10, "bold"),
        )
        clear_btn.pack(side="left", padx=10)

        exe_label = tk.Label(
            controls,
            text=f"Executable: {self.executable.name}",
            bg="#f7f3e9",
            fg="#3a4b5a",
            font=("Segoe UI", 10),
        )
        exe_label.pack(side="left", padx=10)

        self.status_label = tk.Label(
            self,
            text="Status: idle",
            bg="#f7f3e9",
            fg="#32495f",
            font=("Segoe UI", 10, "bold"),
            anchor="w",
        )
        self.status_label.pack(fill="x", padx=18, pady=(0, 6))

        dashboard = tk.LabelFrame(self, text="System Dashboard", bg="#f7f3e9", fg="#22313f", padx=12, pady=10)
        dashboard.pack(fill="both", expand=True, padx=18, pady=(6, 18))

        cards = tk.Frame(dashboard, bg="#f7f3e9")
        cards.pack(fill="x", pady=(2, 10))

        mode_card = tk.Frame(cards, bg="#e7efe8", relief="solid", borderwidth=1)
        mode_card.pack(side="left", fill="both", expand=True, padx=(0, 8))
        tk.Label(mode_card, text="Modes", bg="#e7efe8", fg="#1e3a28", font=("Segoe UI", 11, "bold")).pack(
            anchor="w", padx=10, pady=(8, 2)
        )
        tk.Label(
            mode_card,
            text="Normal: continue even if overflow-like input appears\nProtected: stop execution when canary changes",
            bg="#e7efe8",
            fg="#2d4d3a",
            justify="left",
            font=("Segoe UI", 10),
        ).pack(anchor="w", padx=10, pady=(0, 8))

        flow_card = tk.Frame(cards, bg="#e8edf4", relief="solid", borderwidth=1)
        flow_card.pack(side="left", fill="both", expand=True, padx=(8, 0))
        tk.Label(flow_card, text="Workflow", bg="#e8edf4", fg="#24364a", font=("Segoe UI", 11, "bold")).pack(
            anchor="w", padx=10, pady=(8, 2)
        )
        tk.Label(
            flow_card,
            text="1) Choose function from menu\n2) Select mode in function window\n3) Enter A and B\n4) Run function session",
            bg="#e8edf4",
            fg="#32495f",
            justify="left",
            font=("Segoe UI", 10),
        ).pack(anchor="w", padx=10, pady=(0, 8))

        activity_frame = tk.Frame(dashboard, bg="#f7f3e9")
        activity_frame.pack(fill="x")
        tk.Label(
            activity_frame,
            text="Latest Activity",
            bg="#f7f3e9",
            fg="#22313f",
            font=("Cambria", 13, "bold"),
            anchor="w",
        ).pack(fill="x")

        self.activity_label = tk.Label(
            activity_frame,
            textvariable=self.activity_var,
            bg="#ffffff",
            fg="#2f4357",
            justify="left",
            anchor="w",
            padx=10,
            pady=10,
            relief="solid",
            borderwidth=1,
            font=("Segoe UI", 10),
        )
        self.activity_label.pack(fill="x", pady=(6, 0))

    def open_operation_window(self, op_label: str) -> None:
        existing = self.operation_windows.get(op_label)
        if existing and existing.winfo_exists():
            existing.focus_force()
            return

        win = OperationWindow(self, op_label)
        self.operation_windows[op_label] = win
        self.status_label.config(text=f"Status: opened {op_label} window")

    def build_project(self) -> bool:
        self.status_label.config(text="Status: building project...")
        self.update_idletasks()

        if not self.ml_path.exists() or not self.link_path.exists():
            messagebox.showerror(
                "Build Tools Missing",
                "ML.EXE or LINK32.EXE was not found in the parent folder.",
            )
            self.status_label.config(text="Status: build failed (tools missing)")
            return False

        asm_result = subprocess.run(
            [
                str(self.ml_path),
                "/c",
                "/coff",
                "/Cp",
                "/Zi",
                "/I",
                "..\\INCLUDE",
                "Main.asm",
                "InputSecurity.asm",
                "ArithmeticOps.asm",
                "SecurityProvider.asm",
            ],
            cwd=str(self.project_dir),
            capture_output=True,
            text=True,
        )

        if asm_result.returncode != 0:
            self._show_build_error("Assembly failed", asm_result.stdout, asm_result.stderr)
            self.status_label.config(text="Status: build failed during assembly")
            return False

        link_result = subprocess.run(
            [
                str(self.link_path),
                "/SUBSYSTEM:CONSOLE",
                "/LIBPATH:..\\LIB",
                "Main.obj",
                "InputSecurity.obj",
                "ArithmeticOps.obj",
                "SecurityProvider.obj",
                "Irvine32.lib",
                "kernel32.lib",
                "user32.lib",
                "/OUT:SecureProject.exe",
            ],
            cwd=str(self.project_dir),
            capture_output=True,
            text=True,
        )

        if link_result.returncode != 0:
            self._show_build_error("Linking failed", link_result.stdout, link_result.stderr)
            self.status_label.config(text="Status: build failed during linking")
            return False

        if not self.executable.exists():
            self._show_build_error("Build failed", link_result.stdout, link_result.stderr)
            self.status_label.config(text="Status: build failed (no executable)")
            return False

        self.append_log("Build successful: SecureProject.exe is ready.")
        self.status_label.config(text="Status: build successful")
        return True

    def append_log(self, line: str) -> None:
        self.activity_var.set(line)

    def clear_log(self) -> None:
        self.activity_var.set("No sessions launched yet.")
        self.status_label.config(text="Status: idle")

    def _show_build_error(self, title: str, stdout: str, stderr: str) -> None:
        combined = (stdout or "") + "\n" + (stderr or "")
        lines = [line for line in combined.splitlines() if line.strip()]
        snippet = "\n".join(lines[-20:]) if lines else "No build output captured."
        messagebox.showerror(title, snippet)


if __name__ == "__main__":
    app = SecurityApp()
    app.mainloop()
