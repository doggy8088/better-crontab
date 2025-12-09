#!/bin/bash
#
# uninstall.sh - Uninstallation script for better-crontab
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  better-crontab 移除程式"
echo "=========================================="
echo ""

# Find where better-crontab is installed
INSTALL_LOCATIONS=(
    "/usr/local/bin/better-crontab"
    "$HOME/.local/bin/better-crontab"
    "/usr/bin/better-crontab"
)

FOUND_LOCATIONS=()
for location in "${INSTALL_LOCATIONS[@]}"; do
    if [ -f "$location" ]; then
        FOUND_LOCATIONS+=("$location")
    fi
done

if [ ${#FOUND_LOCATIONS[@]} -eq 0 ]; then
    echo -e "${YELLOW}!${NC} 未找到已安裝的 better-crontab"
    exit 0
fi

echo "找到以下安裝位置："
for i in "${!FOUND_LOCATIONS[@]}"; do
    echo "  $((i+1))) ${FOUND_LOCATIONS[$i]}"
done
echo ""

# Remove the script files
echo "正在移除 better-crontab..."
for location in "${FOUND_LOCATIONS[@]}"; do
    if [[ "$location" == /usr/* ]] && [ "$EUID" -ne 0 ]; then
        echo "移除 $location (需要 sudo)..."
        sudo rm -f "$location"
    else
        echo "移除 $location..."
        rm -f "$location"
    fi
    echo -e "${GREEN}✓${NC} 已移除 $location"
done

# Remove alias from shell configuration files
echo ""
echo "正在檢查 shell 設定檔中的 alias..."

SHELL_CONFIGS=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.zshrc"
    "$HOME/.profile"
)

for config in "${SHELL_CONFIGS[@]}"; do
    if [ -f "$config" ] && grep -q "alias crontab=.*better-crontab" "$config"; then
        echo "在 $config 中找到 alias"
        read -p "是否移除？ (y/n): " remove_alias
        if [[ "$remove_alias" =~ ^[Yy]$ ]]; then
            # Backup the config file
            cp "$config" "$config.bak"
            # Remove the alias and the comment line before it (portable approach)
            grep -v "# better-crontab alias" "$config.bak" | grep -v "alias crontab=.*better-crontab" > "$config"
            echo -e "${GREEN}✓${NC} 已從 $config 移除 alias (備份: $config.bak)"
        else
            echo "保留 $config 中的 alias"
        fi
    fi
done

echo ""
echo "=========================================="
echo -e "${GREEN}✓${NC} 移除完成！"
echo "=========================================="
echo ""
echo "如果您之前有設定 alias，請重新載入 shell 設定："
echo -e "  ${YELLOW}source ~/.bashrc${NC}  # 或您使用的其他設定檔"
echo ""
echo "現在 'crontab' 命令會回到使用系統原生版本。"
echo ""
