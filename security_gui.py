import subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk

BG_APP = "#0a1220"
BG_PANEL = "#111b2d"
BG_CARD = "#16243a"
BG_MUTED = "#1d2f49"
FG_PRIMARY = "#e5edf8"
FG_MUTED = "#9fb0c7"
ACCENT = "#1fbf75"
ACCENT_HOVER = "#17a767"
WARN = "#d46f2f"
WARN_HOVER = "#b55c25"
DANGER = "#b83c4f"
DANGER_HOVER = "#a23345"
BTN_NEUTRAL = "#324968"
BTN_NEUTRAL_HOVER = "#273b56"

MODE_VALUES = {
    "Normal": "1",
    "Protected": "2",
}

CATEGORY_MAP = {
    "Arithmetic Functions": [
        "Add",
        "Subtract",
        "Multiply",
        "Divide",
        "Factorial",
        "Fibonacci",
        "Number Reversal",
    ],
    "Encryption/Decryption": ["XOR Encrypt", "XOR Decrypt", "Caesar Encrypt", "Caesar Decrypt"],
    "Hashing": ["Hash Mix", "Checksum"],
    "Attack Simulation": ["Return Address Hijack Demo"],
}

UNARY_OPERATIONS = {"Factorial", "Fibonacci", "Number Reversal"}
TEXT_INPUT_OPERATIONS = {"Return Address Hijack Demo"}

OP_DEFINITIONS = {
    "Add": {
        "id": "1",
        "description": "Adds two signed integers.",
        "input_a": "Input A",
        "input_b": "Input B",
    },
    "Subtract": {
        "id": "2",
        "description": "Subtracts Input B from Input A.",
        "input_a": "Input A",
        "input_b": "Input B",
    },
    "Multiply": {
        "id": "3",
        "description": "Multiplies two signed integers.",
        "input_a": "Input A",
        "input_b": "Input B",
    },
    "Divide": {
        "id": "4",
        "description": "Divides Input A by Input B.",
        "input_a": "Dividend",
        "input_b": "Divisor",
    },
    "Factorial": {
        "id": "11",
        "description": "Computes n! using Input A (Input B is optional).",
        "input_a": "N",
        "input_b": "Input B (optional, default 0)",
    },
    "Fibonacci": {
        "id": "12",
        "description": "Computes Fibonacci(n) using Input A (Input B is optional).",
        "input_a": "N",
        "input_b": "Input B (optional, default 0)",
    },
    "Number Reversal": {
        "id": "13",
        "description": "Reverses digits of Input A (Input B is optional).",
        "input_a": "Input Number",
        "input_b": "Input B (optional, default 0)",
    },
    "XOR Encrypt": {
        "id": "5",
        "description": "Symmetric XOR transform over integer payload.",
        "input_a": "Plain Value",
        "input_b": "Key",
    },
    "XOR Decrypt": {
        "id": "6",
        "description": "XOR decrypt (same key reverses transform).",
        "input_a": "Cipher Value",
        "input_b": "Key",
    },
    "Caesar Encrypt": {
        "id": "7",
        "description": "Byte-wise Caesar shift on low 8 bits.",
        "input_a": "Plain Byte(0-255)",
        "input_b": "Shift Key",
    },
    "Caesar Decrypt": {
        "id": "8",
        "description": "Reverse Caesar shift on low 8 bits.",
        "input_a": "Cipher Byte(0-255)",
        "input_b": "Shift Key",
    },
    "Hash Mix": {
        "id": "9",
        "description": "Non-cryptographic integer mixing hash.",
        "input_a": "Value A",
        "input_b": "Value B",
    },
    "Checksum": {
        "id": "10",
        "description": "Fast checksum-style combined digest.",
        "input_a": "Value A",
        "input_b": "Value B",
    },
    "Return Address Hijack Demo": {
        "id": "14",
        "description": "Supply a long payload in Input A to simulate return-address hijack in normal mode.",
        "input_a": "Payload String",
        "input_b": "Input B (unused, default 0)",
    },
}


class SecurityApp(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("StackGuard Security Controller")
        self.geometry("1100x700")
        self.minsize(900, 600)

        self.project_dir = Path(__file__).resolve().parent
        self.executable = self.project_dir / "SecureProject.exe"
        self.pattern_stats_path = self.project_dir / "attack_pattern_stats.bin"
        self.ml_path = self.project_dir.parent / "ML.EXE"
        self.link_path = self.project_dir.parent / "LINK32.EXE"
        self.activity_var = tk.StringVar(value="No sessions launched yet.")
        self.pattern_var = tk.StringVar(value="Pattern engine: no attack snapshots yet.")
        self.breadcrumb_var = tk.StringVar(value="Home")

        self.current_category = ""
        self.current_operation = ""
        self.mode_combo: ttk.Combobox | None = None
        self.input_a_entry: ttk.Entry | None = None
        self.input_b_entry: ttk.Entry | None = None

        self._build_shell()
        self.show_domain_view()
        self.refresh_attack_pattern_view()
        self.after(1500, self._poll_attack_pattern_view)

    def _build_shell(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure("StackGuard.TCombobox", fieldbackground=BG_MUTED, background=BG_MUTED, foreground=FG_PRIMARY)
        style.map(
            "StackGuard.TCombobox",
            fieldbackground=[("readonly", BG_MUTED)],
            foreground=[("readonly", FG_PRIMARY)],
            selectforeground=[("readonly", FG_PRIMARY)],
            selectbackground=[("readonly", BG_MUTED)],
        )
        self.configure(bg=BG_APP)

        header = tk.Frame(self, bg=BG_PANEL, highlightthickness=1, highlightbackground="#203553")
        header.pack(fill="x")

        title = tk.Label(
            header,
            text="STACKGUARD",
            fg=ACCENT,
            bg=BG_PANEL,
            font=("Bahnschrift SemiBold", 26, "bold"),
            pady=10,
        )
        title.pack(anchor="w", padx=18)

        subtitle = tk.Label(
            header,
            text="Security Operation Console | Domain -> Operation -> Execute",
            fg=FG_MUTED,
            bg=BG_PANEL,
            font=("Bahnschrift", 11),
            pady=3,
        )
        subtitle.pack(anchor="w", padx=18, pady=(0, 12))

        controls = tk.Frame(self, bg=BG_APP)
        controls.pack(fill="x", padx=18, pady=(12, 8))

        build_btn = tk.Button(
            controls,
            text="Build Core",
            command=self.build_project,
            bg=ACCENT,
            fg=BG_PANEL,
            activebackground=ACCENT_HOVER,
            activeforeground=BG_PANEL,
            relief="flat",
            padx=12,
            pady=8,
            font=("Bahnschrift", 10, "bold"),
            cursor="hand2",
        )
        build_btn.pack(side="left")

        clear_btn = tk.Button(
            controls,
            text="Clear Activity",
            command=self.clear_log,
            bg=DANGER,
            fg=FG_PRIMARY,
            activebackground=DANGER_HOVER,
            activeforeground=FG_PRIMARY,
            relief="flat",
            padx=12,
            pady=8,
            font=("Bahnschrift", 10, "bold"),
            cursor="hand2",
        )
        clear_btn.pack(side="left", padx=10)

        home_btn = tk.Button(
            controls,
            text="Home",
            command=self.show_domain_view,
            bg=BTN_NEUTRAL,
            fg=FG_PRIMARY,
            activebackground=BTN_NEUTRAL_HOVER,
            activeforeground=FG_PRIMARY,
            relief="flat",
            padx=12,
            pady=8,
            font=("Bahnschrift", 10, "bold"),
            cursor="hand2",
        )
        home_btn.pack(side="left")

        pattern_btn = tk.Button(
            controls,
            text="Refresh Patterns",
            command=self.refresh_attack_pattern_view,
            bg=BTN_NEUTRAL,
            fg=FG_PRIMARY,
            activebackground=BTN_NEUTRAL_HOVER,
            activeforeground=FG_PRIMARY,
            relief="flat",
            padx=12,
            pady=8,
            font=("Bahnschrift", 10, "bold"),
            cursor="hand2",
        )
        pattern_btn.pack(side="left", padx=10)

        exe_label = tk.Label(
            controls,
            text=f"Engine Binary: {self.executable.name}",
            bg=BG_APP,
            fg=FG_MUTED,
            font=("Cascadia Mono", 10),
        )
        exe_label.pack(side="left", padx=10)

        self.status_label = tk.Label(
            self,
            text="Status: idle",
            bg=BG_CARD,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 10, "bold"),
            anchor="w",
            padx=10,
            pady=8,
            relief="solid",
            borderwidth=1,
        )
        self.status_label.pack(fill="x", padx=18, pady=(0, 6))

        self.breadcrumb_label = tk.Label(
            self,
            textvariable=self.breadcrumb_var,
            bg=BG_MUTED,
            fg=FG_MUTED,
            font=("Cascadia Mono", 10, "bold"),
            anchor="w",
            padx=10,
            pady=8,
            relief="solid",
            borderwidth=1,
        )
        self.breadcrumb_label.pack(fill="x", padx=18, pady=(0, 6))

        self.content_frame = tk.LabelFrame(
            self,
            text=" Operations Workspace ",
            bg=BG_CARD,
            fg=FG_PRIMARY,
            padx=12,
            pady=10,
            font=("Bahnschrift", 11, "bold"),
            relief="solid",
            borderwidth=1,
        )
        self.content_frame.pack(fill="both", expand=True, padx=18, pady=(6, 12))

        activity_frame = tk.Frame(self, bg=BG_APP)
        activity_frame.pack(fill="x", padx=18, pady=(0, 18))
        tk.Label(
            activity_frame,
            text="Latest Activity",
            bg=BG_APP,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 13, "bold"),
            anchor="w",
        ).pack(fill="x")

        self.activity_label = tk.Label(
            activity_frame,
            textvariable=self.activity_var,
            bg=BG_MUTED,
            fg=FG_PRIMARY,
            justify="left",
            anchor="w",
            padx=10,
            pady=10,
            relief="solid",
            borderwidth=1,
            font=("Cascadia Mono", 10),
        )
        self.activity_label.pack(fill="x", pady=(6, 0))

        tk.Label(
            activity_frame,
            text="Attack Pattern Engine",
            bg=BG_APP,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 13, "bold"),
            anchor="w",
        ).pack(fill="x", pady=(12, 0))

        self.pattern_label = tk.Label(
            activity_frame,
            textvariable=self.pattern_var,
            bg=BG_MUTED,
            fg=FG_PRIMARY,
            justify="left",
            anchor="w",
            padx=10,
            pady=10,
            relief="solid",
            borderwidth=1,
            font=("Cascadia Mono", 10),
        )
        self.pattern_label.pack(fill="x", pady=(6, 0))

    def _clear_content(self) -> None:
        for child in self.content_frame.winfo_children():
            child.destroy()

    def _set_breadcrumb(self) -> None:
        if not self.current_category:
            self.breadcrumb_var.set("Home")
            return
        if not self.current_operation:
            self.breadcrumb_var.set(f"Home > {self.current_category}")
            return
        self.breadcrumb_var.set(f"Home > {self.current_category} > {self.current_operation}")

    def show_domain_view(self) -> None:
        self.current_category = ""
        self.current_operation = ""
        self._set_breadcrumb()
        self._clear_content()
        self.content_frame.config(text=" Operations Workspace | Domain Menu ")

        intro = tk.Label(
            self.content_frame,
            text="Select a security domain to continue:",
            bg=BG_CARD,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 13, "bold"),
            anchor="w",
        )
        intro.pack(fill="x", pady=(2, 10))

        menu = tk.Frame(self.content_frame, bg=BG_CARD)
        menu.pack(fill="x")

        for idx, category_label in enumerate(CATEGORY_MAP.keys()):
            btn = tk.Button(
                menu,
                text=category_label,
                command=lambda cat=category_label: self.show_category_view(cat),
                bg=BTN_NEUTRAL,
                fg=FG_PRIMARY,
                activebackground=BTN_NEUTRAL_HOVER,
                activeforeground=FG_PRIMARY,
                relief="flat",
                padx=12,
                pady=12,
                font=("Bahnschrift", 11, "bold"),
                width=28,
                cursor="hand2",
            )
            btn.grid(row=idx, column=0, padx=8, pady=6, sticky="w")

        self.status_label.config(text="Status: choose a domain")

    def show_category_view(self, category_label: str) -> None:
        self.current_category = category_label
        self.current_operation = ""
        self._set_breadcrumb()
        self._clear_content()
        self.content_frame.config(text=f" Operations Workspace | {category_label} ")

        tk.Label(
            self.content_frame,
            text=f"{category_label}: choose an operation",
            bg=BG_CARD,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 13, "bold"),
            anchor="w",
        ).pack(fill="x", pady=(2, 8))

        # Create wrapper frame for scrollable area
        scroll_wrapper = tk.Frame(self.content_frame, bg=BG_CARD)
        scroll_wrapper.pack(fill="both", expand=True, pady=4)

        # Create scrollable canvas for operations
        canvas = tk.Canvas(scroll_wrapper, bg=BG_CARD, highlightthickness=0, height=250)
        scrollbar = ttk.Scrollbar(scroll_wrapper, orient="vertical", command=canvas.yview)
        op_wrap = tk.Frame(canvas, bg=BG_CARD)

        op_wrap.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=op_wrap, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        # Bind mousewheel to canvas
        def _on_mousewheel(event):
            canvas.yview_scroll(int(-1*(event.delta/120)), "units")
        canvas.bind_all("<MouseWheel>", _on_mousewheel)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        for op_label in CATEGORY_MAP[category_label]:
            btn = tk.Button(
                op_wrap,
                text=f"Open {op_label}",
                command=lambda op=op_label: self.show_operation_view(category_label, op),
                bg=BTN_NEUTRAL,
                fg=FG_PRIMARY,
                activebackground=BTN_NEUTRAL_HOVER,
                activeforeground=FG_PRIMARY,
                relief="flat",
                padx=12,
                pady=8,
                font=("Bahnschrift", 11, "bold"),
                width=34,
                cursor="hand2",
            )
            btn.pack(anchor="w", pady=4)

        nav = tk.Frame(self.content_frame, bg=BG_CARD)
        nav.pack(fill="x", pady=(12, 0))
        tk.Button(
            nav,
            text="Back",
            command=self.show_domain_view,
            bg=WARN,
            fg=FG_PRIMARY,
            activebackground=WARN_HOVER,
            activeforeground=FG_PRIMARY,
            relief="flat",
            padx=12,
            pady=8,
            font=("Bahnschrift", 10, "bold"),
            cursor="hand2",
        ).pack(anchor="w")

        self.status_label.config(text=f"Status: viewing {category_label}")

    def show_operation_view(self, category_label: str, op_label: str) -> None:
        self.current_category = category_label
        self.current_operation = op_label
        self._set_breadcrumb()
        self._clear_content()

        op_info = OP_DEFINITIONS[op_label]
        self.content_frame.config(text=f" Operations Workspace | {category_label} | {op_label} ")

        tk.Label(
            self.content_frame,
            text=f"{category_label} | {op_label}",
            bg=BG_CARD,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 13, "bold"),
            anchor="w",
        ).pack(fill="x", pady=(2, 8))

        # Create wrapper frame for scrollable area
        scroll_wrapper = tk.Frame(self.content_frame, bg=BG_CARD)
        scroll_wrapper.pack(fill="both", expand=True, pady=4)

        # Create scrollable canvas for form
        canvas = tk.Canvas(scroll_wrapper, bg=BG_CARD, highlightthickness=0, height=200)
        scrollbar = ttk.Scrollbar(scroll_wrapper, orient="vertical", command=canvas.yview)
        form_wrap = tk.Frame(canvas, bg=BG_CARD)

        form_wrap.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=form_wrap, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        # Bind mousewheel to canvas
        def _on_mousewheel(event):
            canvas.yview_scroll(int(-1*(event.delta/120)), "units")
        canvas.bind_all("<MouseWheel>", _on_mousewheel)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        # Create form inside scrollable frame
        form = tk.Frame(form_wrap, bg=BG_CARD)
        form.pack(fill="x", padx=4)

        tk.Label(form, text="Mode", bg=BG_CARD, fg=FG_PRIMARY, font=("Bahnschrift", 11, "bold")).grid(
            row=0, column=0, sticky="w", padx=(0, 8), pady=6
        )
        self.mode_combo = ttk.Combobox(form, values=list(MODE_VALUES.keys()), state="readonly", width=20, style="StackGuard.TCombobox")
        self.mode_combo.grid(row=0, column=1, sticky="w", pady=6)
        self.mode_combo.set("Protected")

        tk.Label(
            form,
            text=op_info["input_a"],
            bg=BG_CARD,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 11, "bold"),
        ).grid(row=1, column=0, sticky="w", pady=6)
        self.input_a_entry = ttk.Entry(form, width=32)
        self.input_a_entry.grid(row=1, column=1, sticky="w", pady=6)

        tk.Label(
            form,
            text=op_info["input_b"],
            bg=BG_CARD,
            fg=FG_PRIMARY,
            font=("Bahnschrift", 11, "bold"),
        ).grid(row=2, column=0, sticky="w", pady=6)
        self.input_b_entry = ttk.Entry(form, width=32)
        self.input_b_entry.grid(row=2, column=1, sticky="w", pady=6)

        tk.Label(
            form_wrap,
            text=op_info["description"],
            bg=BG_CARD,
            fg=FG_MUTED,
            font=("Bahnschrift", 10),
            anchor="w",
        ).pack(fill="x", pady=(8, 0), padx=4)

        actions = tk.Frame(self.content_frame, bg=BG_CARD)
        actions.pack(fill="x", pady=4)

        tk.Button(
            actions,
            text="Run Function",
            command=self.run_current_operation,
            bg=ACCENT,
            fg=BG_PANEL,
            activebackground=ACCENT_HOVER,
            activeforeground=BG_PANEL,
            relief="flat",
            padx=12,
            pady=7,
            font=("Bahnschrift", 10, "bold"),
            cursor="hand2",
        ).pack(side="left")

        tk.Button(
            actions,
            text="Back",
            command=lambda: self.show_category_view(category_label),
            bg=WARN,
            fg=FG_PRIMARY,
            activebackground=WARN_HOVER,
            activeforeground=FG_PRIMARY,
            relief="flat",
            padx=12,
            pady=7,
            font=("Bahnschrift", 10, "bold"),
            cursor="hand2",
        ).pack(side="left", padx=10)

        tk.Label(
            self.content_frame,
            text="Each run opens a dedicated console window under protected framework execution.",
            bg=BG_CARD,
            fg=FG_MUTED,
            font=("Bahnschrift", 10),
            anchor="w",
        ).pack(fill="x", pady=(8, 0))

        self.status_label.config(text=f"Status: ready to run {op_label}")

    def run_current_operation(self) -> None:
        if not self.current_operation or not self.mode_combo or not self.input_a_entry or not self.input_b_entry:
            messagebox.showerror("State Error", "Operation screen is not ready.")
            return

        mode_label = self.mode_combo.get().strip()
        a = self.input_a_entry.get().strip()
        b = self.input_b_entry.get().strip()

        if mode_label not in MODE_VALUES:
            messagebox.showerror("Invalid Mode", "Select a valid mode.")
            return

        if self.current_operation in UNARY_OPERATIONS:
            if not a:
                messagebox.showerror("Missing Input", "Enter Input A.")
                return
            if not b:
                b = "0"
                if self.input_b_entry:
                    self.input_b_entry.delete(0, tk.END)
                    self.input_b_entry.insert(0, b)
        elif self.current_operation in TEXT_INPUT_OPERATIONS:
            if not a:
                messagebox.showerror("Missing Input", "Enter payload in Input A.")
                return
            if not b:
                b = "0"
                if self.input_b_entry:
                    self.input_b_entry.delete(0, tk.END)
                    self.input_b_entry.insert(0, b)
        elif not a or not b:
            messagebox.showerror("Missing Inputs", "Enter both inputs.")
            return

        if self.current_operation not in TEXT_INPUT_OPERATIONS:
            if not self._is_signed_int(a) or not self._is_signed_int(b):
                messagebox.showerror("Invalid Inputs", "Inputs must be signed integers.")
                return

        if not self.build_project():
            return

        mode = MODE_VALUES[mode_label]
        op_id = OP_DEFINITIONS[self.current_operation]["id"]
        title = f"StackGuard - {self.current_operation} - {mode_label}"
        cmd_line = (
            f"title {title} & "
            f"SecureProject.exe {mode} {op_id} {a} {b} & "
            "echo. & echo [Session complete] & pause"
        )

        try:
            proc = subprocess.Popen(
                ["cmd.exe", "/k", cmd_line],
                cwd=str(self.project_dir),
                creationflags=subprocess.CREATE_NEW_CONSOLE,
            )
        except Exception as exc:
            messagebox.showerror("Launch Error", str(exc))
            return

        self.append_log(
            (
                f"PID {proc.pid} | Category={self.current_category} | Op={self.current_operation} "
                f"| Mode={mode_label} | A={a} | B={b}"
            )
        )
        self.refresh_attack_pattern_view()
        self.status_label.config(text=f"Status: launched {self.current_operation} session")

    @staticmethod
    def _is_signed_int(value: str) -> bool:
        if value.startswith("-"):
            return value[1:].isdigit() and len(value) > 1
        return value.isdigit()

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
                "BuisnessLogic.asm",
                "AttackISR.asm",
                "AttackPatternEngine.asm",
                "AttackerSimulation.asm",
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
                "BuisnessLogic.obj",
                "AttackISR.obj",
                "AttackPatternEngine.obj",
                "AttackerSimulation.obj",
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
        self.refresh_attack_pattern_view()
        self.status_label.config(text="Status: build successful")
        return True

    def append_log(self, line: str) -> None:
        self.activity_var.set(line)

    def clear_log(self) -> None:
        self.activity_var.set("No sessions launched yet.")
        self.status_label.config(text="Status: idle")

    def refresh_attack_pattern_view(self) -> None:
        if not self.pattern_stats_path.exists():
            self.pattern_var.set("Pattern engine: no attack snapshots yet.")
            return

        try:
            raw = self.pattern_stats_path.read_bytes()
        except OSError:
            self.pattern_var.set("Pattern engine: unable to read attack_pattern_stats.bin")
            return

        if len(raw) < 16:
            self.pattern_var.set("Pattern engine: stats file is incomplete.")
            return

        code = int.from_bytes(raw[0:4], "little", signed=False)
        frequency = int.from_bytes(raw[4:8], "little", signed=False)
        consecutive = int.from_bytes(raw[8:12], "little", signed=False)
        cycle = int.from_bytes(raw[12:16], "little", signed=False)

        cycle_text = "YES" if cycle == 1 else "NO"
        self.pattern_var.set(
            "last_attack_code="
            f"{code} | frequency={frequency} | consecutive={consecutive} | cycle_detected={cycle_text}"
        )

    def _poll_attack_pattern_view(self) -> None:
        try:
            self.refresh_attack_pattern_view()
            self.after(1500, self._poll_attack_pattern_view)
        except tk.TclError:
            return

    def _show_build_error(self, title: str, stdout: str, stderr: str) -> None:
        combined = (stdout or "") + "\n" + (stderr or "")
        lines = [line for line in combined.splitlines() if line.strip()]
        snippet = "\n".join(lines[-20:]) if lines else "No build output captured."
        messagebox.showerror(title, snippet)


if __name__ == "__main__":
    app = SecurityApp()
    app.mainloop()
