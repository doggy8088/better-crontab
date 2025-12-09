#!/bin/bash
#
# install.sh - Installation script for better-crontab
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  better-crontab 安裝程式"
echo "=========================================="
echo ""

# Check if running as root for system-wide installation
INSTALL_DIR="/usr/local/bin"
if [ "$EUID" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} 以 root 權限執行，將進行系統全域安裝"
else
    echo -e "${YELLOW}!${NC} 未使用 root 權限，請選擇安裝方式："
    echo "  1) 繼續安裝到 /usr/local/bin (需要 sudo)"
    echo "  2) 安裝到 ~/.local/bin (個人使用)"
    echo "  3) 取消安裝"
    echo ""
    read -p "請選擇 [1-3]: " choice
    
    case $choice in
        1)
            echo "將使用 sudo 安裝..."
            ;;
        2)
            INSTALL_DIR="$HOME/.local/bin"
            mkdir -p "$INSTALL_DIR"
            echo -e "${GREEN}✓${NC} 將安裝到 $INSTALL_DIR"
            ;;
        *)
            echo "安裝已取消"
            exit 0
            ;;
    esac
fi

# Copy the script
echo ""
echo "正在複製 better-crontab 到 $INSTALL_DIR ..."

if [ "$INSTALL_DIR" = "/usr/local/bin" ] && [ "$EUID" -ne 0 ]; then
    sudo cp better-crontab "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/better-crontab"
else
    cp better-crontab "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/better-crontab"
fi

echo -e "${GREEN}✓${NC} 檔案複製完成"

# Detect shell configuration file
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    fi
fi

# Add alias to shell configuration
echo ""
echo "是否要自動加入 alias 到您的 shell 設定檔？"
if [ -n "$SHELL_CONFIG" ]; then
    echo "偵測到的設定檔：$SHELL_CONFIG"
else
    echo "無法自動偵測 shell 設定檔"
fi

read -p "是否繼續？ (y/n): " add_alias

if [[ "$add_alias" =~ ^[Yy]$ ]]; then
    if [ -z "$SHELL_CONFIG" ]; then
        read -p "請輸入您的 shell 設定檔路徑 (例如 ~/.bashrc): " SHELL_CONFIG
    fi
    
    # Check if alias already exists
    if grep -q "alias crontab=" "$SHELL_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}!${NC} 警告：alias 已存在於 $SHELL_CONFIG"
        read -p "是否覆蓋？ (y/n): " overwrite
        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
            # Remove old alias (portable sed syntax)
            cp "$SHELL_CONFIG" "$SHELL_CONFIG.bak"
            grep -v "alias crontab=" "$SHELL_CONFIG.bak" > "$SHELL_CONFIG"
        else
            echo "跳過 alias 設定"
            add_alias="n"
        fi
    fi
    
    if [[ "$add_alias" =~ ^[Yy]$ ]]; then
        echo "" >> "$SHELL_CONFIG"
        echo "# better-crontab alias" >> "$SHELL_CONFIG"
        echo "alias crontab=\"$INSTALL_DIR/better-crontab\"" >> "$SHELL_CONFIG"
        echo -e "${GREEN}✓${NC} Alias 已加入到 $SHELL_CONFIG"
        echo ""
        echo "請執行以下命令來套用設定："
        echo -e "  ${YELLOW}source $SHELL_CONFIG${NC}"
    fi
else
    echo ""
    echo "您可以稍後手動加入以下內容到您的 shell 設定檔："
    echo -e "  ${YELLOW}alias crontab=\"$INSTALL_DIR/better-crontab\"${NC}"
fi

# Check if PATH includes the installation directory
echo ""
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}!${NC} 警告：$INSTALL_DIR 不在您的 PATH 中"
    echo "您可能需要將以下內容加入到您的 shell 設定檔："
    echo -e "  ${YELLOW}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓${NC} 安裝完成！"
echo "=========================================="
echo ""
echo "使用方式："
echo "  crontab -e    # 編輯 crontab"
echo "  crontab -l    # 列出 crontab"
echo "  crontab -r    # 刪除 crontab (會要求確認)"
echo ""
echo "如需更多資訊，請參閱 README.md"
echo ""
