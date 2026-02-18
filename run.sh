#!/usr/bin/env bash
set -e

# 取得脚本所在目录（项目根）
DIR="$(cd "$(dirname "$0")" && pwd)"
ARGS=("$@")

# 新增：检测是否请求安装 C++ 工具
INSTALL_CPP=false
INIT_DEV_ENV=false
ASSUME_YES=false
for arg in "${ARGS[@]}"; do
	if [ "$arg" = "--install-cpp-tools" ]; then
		INSTALL_CPP=true
	elif [ "$arg" = "--init-dev-env" ]; then
		INIT_DEV_ENV=true
	elif [ "$arg" = "--yes" ] || [ "$arg" = "-y" ]; then
		ASSUME_YES=true
	fi
done

install_cpp_tools() {
	echo "准备安装常用 C++ 开发/调试工具..."
	# 检测包管理器
	if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
		PKG_MANAGER="apt"
		UPDATE_CMD="sudo apt-get update"
		INSTALL_CMD="sudo apt-get install -y"
		PACKAGES=(build-essential g++ clang cmake gdb lldb valgrind strace ltrace clang-tidy clang-format ccache lcov gcovr ninja-build make)
	elif command -v dnf >/dev/null 2>&1; then
		PKG_MANAGER="dnf"
		UPDATE_CMD="sudo dnf makecache"
		INSTALL_CMD="sudo dnf install -y"
		PACKAGES=(gcc-c++ clang cmake gdb lldb valgrind strace ltrace clang-tools-extra clang-format ccache lcov gcovr ninja-build make)
	elif command -v yum >/dev/null 2>&1; then
		PKG_MANAGER="yum"
		UPDATE_CMD="sudo yum makecache"
		INSTALL_CMD="sudo yum install -y"
		PACKAGES=(gcc-c++ clang cmake gdb lldb valgrind strace ltrace clang-tools-extra clang-format ccache lcov gcovr ninja-build make)
	elif command -v pacman >/dev/null 2>&1; then
		PKG_MANAGER="pacman"
		UPDATE_CMD="sudo pacman -Sy"
		INSTALL_CMD="sudo pacman -S --noconfirm"
		PACKAGES=(base-devel gcc clang cmake gdb lldb valgrind strace clang-format ccache lcov gcovr ninja)
	elif command -v apk >/dev/null 2>&1; then
		PKG_MANAGER="apk"
		UPDATE_CMD="sudo apk update"
		INSTALL_CMD="sudo apk add --no-cache"
		PACKAGES=(build-base gcc g++ clang cmake gdb lldb valgrind strace clang-format ccache lcov gcovr ninja)
	elif command -v brew >/dev/null 2>&1; then
		PKG_MANAGER="brew"
		UPDATE_CMD="brew update"
		INSTALL_CMD="brew install"
		PACKAGES=(gcc clang cmake gdb lldb valgrind clang-format ccache lcov gcovr ninja)
	else
		echo "未检测到受支持的包管理器（apt/dnf/yum/pacman/apk/brew）。请手动安装所需工具。" >&2
		return 1
	fi

	echo "检测到包管理器：$PKG_MANAGER"
	echo "将要安装的包： ${PACKAGES[*]}"

	if [ "$ASSUME_YES" = false ]; then
		read -p "继续安装吗？[y/N] " CONFIRM
		case "$CONFIRM" in
			[yY]|[yY][eE][sS]) ;;
			*) echo "已取消安装。" ; return 0 ;;
		esac
	fi

	echo "更新包索引..."
	eval "$UPDATE_CMD"

	echo "开始安装..."
	# 分批安装以避免命令过长问题
	for pkg in "${PACKAGES[@]}"; do
		echo "安装：$pkg"
		eval "$INSTALL_CMD $pkg" || {
			echo "安装包 $pkg 失败，继续尝试安装剩余包。" >&2
		}
	done

	echo "C++ 开发/调试工具安装完成（或尝试安装）。"
	echo "注意：某些工具（例如 gdb）在 macOS 或受限容器环境中可能需要额外配置。"
	return 0
}

install_python_tools() {
	echo "准备安装 Python3 及 pip..."
	if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y python3 python3-pip python3-venv
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf makecache
		sudo dnf install -y python3 python3-pip python3-virtualenv
	elif command -v yum >/dev/null 2>&1; then
		sudo yum makecache
		sudo yum install -y python3 python3-pip python3-virtualenv
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy
		sudo pacman -S --noconfirm python python-pip
	elif command -v apk >/dev/null 2>&1; then
		sudo apk update
		sudo apk add --no-cache python3 py3-pip
	elif command -v brew >/dev/null 2>&1; then
		brew update
		brew install python
	else
		echo "未检测到受支持的包管理器，无法自动安装 Python3。" >&2
		return 1
	fi
	echo "Python3 及 pip 安装完成。"
}

install_node_tools() {
	echo "准备安装 Node.js 及 npm/yarn..."
	if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y nodejs npm
		sudo npm install -g yarn
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf makecache
		sudo dnf install -y nodejs npm
		sudo npm install -g yarn
	elif command -v yum >/dev/null 2>&1; then
		sudo yum makecache
		sudo yum install -y nodejs npm
		sudo npm install -g yarn
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy
		sudo pacman -S --noconfirm nodejs npm yarn
	elif command -v apk >/dev/null 2>&1; then
		sudo apk update
		sudo apk add --no-cache nodejs npm yarn
	elif command -v brew >/dev/null 2>&1; then
		brew update
		brew install node yarn
	else
		echo "未检测到受支持的包管理器，无法自动安装 Node.js。" >&2
		return 1
	fi
	echo "Node.js 及 npm/yarn 安装完成。"
}

install_git_tools() {
	echo "准备安装 Git..."
	if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y git
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf makecache
		sudo dnf install -y git
	elif command -v yum >/dev/null 2>&1; then
		sudo yum makecache
		sudo yum install -y git
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy
		sudo pacman -S --noconfirm git
	elif command -v apk >/dev/null 2>&1; then
		sudo apk update
		sudo apk add --no-cache git
	elif command -v brew >/dev/null 2>&1; then
		brew update
		brew install git
	else
		echo "未检测到受支持的包管理器，无法自动安装 Git。" >&2
		return 1
	fi
	echo "Git 安装完成。"
}

install_build_tools() {
	echo "准备安装常用构建工具（cmake、make、zip、unzip 等）..."
	if command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y cmake make ninja-build zip unzip
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf makecache
		sudo dnf install -y cmake make ninja-build zip unzip
	elif command -v yum >/dev/null 2>&1; then
		sudo yum makecache
		sudo yum install -y cmake make ninja-build zip unzip
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy
		sudo pacman -S --noconfirm cmake make ninja zip unzip
	elif command -v apk >/dev/null 2>&1; then
		sudo apk update
		sudo apk add --no-cache cmake make ninja zip unzip
	elif command -v brew >/dev/null 2>&1; then
		brew update
		brew install cmake make ninja zip unzip
	else
		echo "未检测到受支持的包管理器，无法自动安装构建工具。" >&2
		return 1
	fi
	echo "构建工具安装完成。"
}

init_dev_env() {
	echo "将为你初始化常用编译开发环境（C++/Python/Node.js/Git/构建工具等）"
	if [ "$ASSUME_YES" = false ]; then
		read -p "继续吗？[y/N] " CONFIRM
		case "$CONFIRM" in
			[yY]|[yY][eE][sS]) ;;
			*) echo "已取消初始化。" ; return 0 ;;
		esac
	fi

	install_git_tools
	install_cpp_tools
	install_python_tools
	install_node_tools
	install_build_tools

	echo "开发环境初始化完成！"
}

# 如果请求安装工具，则执行后退出
if [ "$INIT_DEV_ENV" = true ]; then
	init_dev_env
	exit $?
fi

if [ "$INSTALL_CPP" = true ]; then
	install_cpp_tools
	exit $?
fi

# 尝试常见入口
if [ -f "$DIR/main.py" ]; then
	# Python 项目
	exec python3 "$DIR/main.py" "${ARGS[@]}"
elif [ -f "$DIR/package.json" ]; then
	# Node 项目（优先 npm，然后 yarn）
	cd "$DIR"
	if command -v npm >/dev/null 2>&1; then
		exec npm start -- "${ARGS[@]}"
	elif command -v yarn >/dev/null 2>&1; then
		exec yarn start -- "${ARGS[@]}"
	else
		echo "Error: npm 或 yarn 未安装。" >&2
		exit 1
	fi
elif [ -f "$DIR/index.js" ]; then
	# 直接运行 Node 脚本
	exec node "$DIR/index.js" "${ARGS[@]}"
elif [ -f "$DIR/start.sh" ]; then
	# 使用已有的 start 脚本
	exec "$DIR/start.sh" "${ARGS[@]}"
else
	echo "未检测到可识别的入口文件（main.py, package.json, index.js, start.sh）。" >&2
	echo "请在 $DIR 添加入口文件或手动运行所需命令。" >&2
	exit 1
fi
