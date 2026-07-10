#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.dev"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
REPO="https://raw.githubusercontent.com/gliddd4/dev/main"

BOLD='\033[1m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}Installing dev...${NC}"

mkdir -p "$INSTALL_DIR" "$BIN_DIR"

echo "  downloading dev.sh..."
curl -fsSL "$REPO/dev.sh" -o "$INSTALL_DIR/dev.sh"

echo "  downloading dev_menu.py..."
curl -fsSL "$REPO/dev_menu.py" -o "$INSTALL_DIR/dev_menu.py"

echo "  downloading d..."
curl -fsSL "$REPO/d" -o "$INSTALL_DIR/d"
chmod +x "$INSTALL_DIR/d" "$INSTALL_DIR/dev.sh"

cat > "$INSTALL_DIR/dev" << 'EOF'
#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0")")" && ./dev.sh "$@"
EOF

chmod +x "$INSTALL_DIR/dev"

[ -L "$BIN_DIR/dev" ] && rm "$BIN_DIR/dev"
ln -s "$INSTALL_DIR/dev" "$BIN_DIR/dev"

hash -r 2>/dev/null || true
echo -e "${GREEN}Done! Run 'dev' to start.${NC}"
