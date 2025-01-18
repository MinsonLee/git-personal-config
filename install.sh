#!/bin/bash

#*********************************************
# Description: The Test Script
# Author: limingshuang
# Date: 2025/01/16 星期四 16:3702
# HomePage: https://minsonlee.github.io/
# Copyright © 2025 All rights reserved
#*********************************************

# 获取当前脚步所在路径
DIR=$(dirname $(readlink -f "$0"))

# 检查是否设置了 user/email 等信息
function checkConf() {
    if [ -n "$GIT_USER" ] && [ -n "$GIT_EMAIL" ];then
        return 0;
    fi
    return 1;
}

# 先判断当先是否存在 gitconfig/conf 模板文件
if !([ -f "$DIR/gitconfig" ] && [ -f "$DIR/conf.example" ])
then
    echo "模板文件丢失，请更新仓库！"
    exit 1
fi

# 配置用户自定义配置信息
if [ ! -f "$DIR/conf" ]
then
    cp "$DIR/conf.example" "$DIR/conf"
fi

# 加载用户自定义配置
source "$DIR/conf"
# 检查配置信息
checkConf
if [ $? != 0 ]
then
    echo "请先设置 $DIR/conf 配置信息"
    exit 1
fi

# 如果 ~/.gitconfig 文件已经存在，则先将原文件 copy 一份进行备份
# 基于 gitconfig 文件创建新的文件
if test -e "$HOME/.gitconfig"
then
    cp "$HOME/.gitconfig" "$HOME/.gitconfig.$(date -u +%Y-%m-%d-%H%M%S).bak"
fi
echo -e "基于 $DIR/gitconfig 创建 $HOME/.gitconfig\n设置权限为 0644\n"
install -p -D -m 0644 "$DIR/gitconfig" "$HOME/.gitconfig"
# 替换配置文件中的路径信息
sed -i -e "s,PERSONAL_CONFIG_GIT_DIR,$DIR,g" "$HOME/.gitconfig"

# 根据 conf 文件配置 用户/邮箱 信息
echo -e "设置全局 Git 用户为:$GIT_USER\n设置全局 Git 邮箱为:$GIT_EMAIL\n"
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

echo -e "设置全局 Git Hooks:$DIR/githooks\n设置全局 Git Ignore:$DIR/gitignore\n"
git config --global core.hookspath "$DIR/githooks"
git config --global core.excludesfile "$DIR/gitignore"

# 设置 gitalias.txt 文件路径
if [ -z "$GIT_ALIAS" ];then
    GIT_ALIAS="$DIR/gitalias.txt"
fi
# 判断创建 gitalias 目录
GIT_ALIAS_DIR=$(dirname $(readlink -f "$GIT_ALIAS"))
if [ -d "$GIT_ALIAS_DIR" ];then
    mkdir -p "$GIT_ALIAS_DIR"
fi

# 下载 gitalias.txt
curl -s "https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt" -o "$GIT_ALIAS"
# 配置
if test -f "$GIT_ALIAS";then
    echo -e "下载 $GIT_ALIAS 成功\n"
    git config --global --add include.path "$GIT_ALIAS"
else
    echo -e "下载 $GIT_ALIAS 失败...\n"
fi

# 下载 git-paging-alias.txt
GIT_PAGING_ALIAS="$GIT_ALIAS_DIR/git-paging-alias.txt"
curl -s "https://raw.githubusercontent.com/MinsonLee/git-paging/refs/heads/master/git-paging-alias.txt" \
    -o "$GIT_PAGING_ALIAS";
# 配置
if test -f "$GIT_PAGING_ALIAS";then
    echo -e "下载 $GIT_PAGING_ALIAS 成功\n"
    git config --global --add include.path "$GIT_PAGING_ALIAS";
else
    echo -e "下载 $GIT_PAGING_ALIAS 失败...\n"
fi

# 格式化一下 $HOME/.gitconfig
sed -i -e 's/^[ \t]\{1,\}/    /g' "$HOME/.gitconfig"
