#!/bin/bash

# === 交互式输入配置 ===
read -p "请输入你的 Discord Bot Token: " DISCORD_TOKEN
read -p "请输入你的服务器ID (guildId): " GUILD_ID
read -p "请输入你的频道ID (channelId): " CHANNEL_ID
read -p "请输入频道名字（可自定义）: " CHANNEL_NAME

GIT_REPO="https://github.com/maanex/knabber.git"
INSTALL_DIR="$HOME/knabber"

# === 安装依赖 ===
echo "== 安装 curl 和 git =="
sudo apt update
sudo apt install -y curl git

echo "== 安装 Bun =="
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"

echo "== 克隆项目 =="
git clone "$GIT_REPO" "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "== 安装项目依赖 =="
bun install

echo "== 配置 config.ts =="
cat > config.ts <<EOF
import type { FeedOptions } from "feed"

export type Config = {
  discord: {
    token: string
    guildId: string
  }
  feed: {
    options: FeedOptions
  }
  channels: Array<{
    id: string
    name: string
    frequency: 'daily'
  }>
}

const host = 'http://localhost:8080/'

export const config: Config = {
  discord: {
    token: "$DISCORD_TOKEN",
    guildId: '$GUILD_ID'
  },
  feed: {
    options: {
      title: 'My Discord Feed',
      copyright: \`Copyright (c) \${new Date().getFullYear()} MyBot\`,
      description: 'Feeds from my Discord server',
      id: host,
      link: host,
      language: 'zh',
      generator: 'Knabber',
      feedLinks: {
        rss: \`\${host}rss.xml\`,
        atom: \`\${host}atom.xml\`
      },
      author: {
        name: 'MyBot',
        email: 'your@email.com',
        link: 'https://yourdomain.com'
      },
      image: ''
    }
  },
  channels: [
    {
      id: '$CHANNEL_ID',
      name: '$CHANNEL_NAME',
      frequency: 'daily'
    }
  ]
}
EOF

echo "== 运行 knabber，生成 RSS/Atom =="
bun run index.ts

# === 获取本机IP和公网IP ===
LAN_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s ifconfig.me)

echo "== 启动本地静态服务器（8080端口） =="
echo "------------------------------------------"
echo "局域网访问: http://$LAN_IP:8080/out/rss.xml"
echo "公网访问:   http://$PUBLIC_IP:8080/out/rss.xml"
echo "（如需公网访问，请确保服务器防火墙和云安全组已开放8080端口）"
echo "------------------------------------------"
python3 -m http.server 8080
