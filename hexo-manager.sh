#!/bin/bash

# Hexo 博客一键管理脚本
# 作者：AI助手
# 功能：提供Hexo博客的创建、预览、生成、部署和备份功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 博客根目录（如果脚本不在博客根目录，请修改此处）
BLOG_DIR="$(pwd)"

# Git 分支设置
GIT_BRANCH="main"
BACKUP_BRANCH="hexo-source"  # 用于备份源文件的分支

# 函数：显示菜单
show_menu() {
    clear
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}      Hexo 博客管理脚本${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo -e "1. 创建新文章"
    echo -e "2. 本地预览博客"
    echo -e "3. 生成静态文件"
    echo -e "4. 部署到网站"
    echo -e "5. 备份源文件到GitHub"
    echo -e "6. 一键发布（创建+生成+部署+备份）"
    echo -e "7. 清理缓存并生成"
    echo -e "8. 退出脚本"
    echo -e "${GREEN}=================================${NC}"
    echo -n "请选择操作 [1-8]: "
}

# 函数：创建新文章
create_post() {
    echo -e "${BLUE}创建新文章...${NC}"
    read -p "请输入文章标题: " title
    if [ -z "$title" ]; then
        echo -e "${RED}错误：文章标题不能为空！${NC}"
        return 1
    fi
    hexo new "$title"
    echo -e "${GREEN}文章已创建: source/_posts/${title}.md${NC}"
    
    # 询问是否立即编辑
    read -p "是否立即编辑文章？(y/n): " edit_choice
    if [ "$edit_choice" = "y" ] || [ "$edit_choice" = "Y" ]; then
        if command -v code &> /dev/null; then
            code "source/_posts/${title}.md"
        else
            vim "source/_posts/${title}.md"
        fi
    fi
}

# 函数：本地预览
preview_blog() {
    echo -e "${BLUE}启动本地预览服务器...${NC}"
    echo -e "${YELLOW}按 Ctrl+C 停止预览服务器${NC}"
    hexo server
}

# 函数：生成静态文件
generate_blog() {
    echo -e "${BLUE}生成静态文件中...${NC}"
    hexo generate
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}静态文件生成成功！${NC}"
    else
        echo -e "${RED}生成过程中出现错误！${NC}"
        return 1
    fi
}

# 函数：部署到网站
deploy_blog() {
    echo -e "${BLUE}部署到网站...${NC}"
    hexo deploy
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}部署成功！${NC}"
        echo -e "${YELLOW}注意：Cloudflare Pages 可能需要几分钟才能完成构建${NC}"
    else
        echo -e "${RED}部署过程中出现错误！${NC}"
        return 1
    fi
}

# 函数：备份源文件到GitHub
backup_source() {
    echo -e "${BLUE}备份源文件到GitHub...${NC}"
    
    # 检查是否有未提交的更改
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}没有更改需要提交。${NC}"
        return 0
    fi
    
    # 添加所有更改
    git add .
    
    # 提交更改
    read -p "请输入提交信息: " commit_msg
    if [ -z "$commit_msg" ]; then
        commit_msg="自动备份: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    git commit -m "$commit_msg"
    
    # 推送到远程仓库
    echo -e "${BLUE}推送到远程仓库...${NC}"
    if git push origin $BACKUP_BRANCH; then
        echo -e "${GREEN}备份成功！${NC}"
    else
        echo -e "${YELLOW}尝试创建并推送备份分支...${NC}"
        git checkout -b $BACKUP_BRANCH
        git push -u origin $BACKUP_BRANCH
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}备份分支创建并推送成功！${NC}"
            git checkout $GIT_BRANCH
        else
            echo -e "${RED}备份过程中出现错误！${NC}"
            return 1
        fi
    fi
}

# 函数：清理缓存并生成
clean_and_generate() {
    echo -e "${BLUE}清理缓存并重新生成...${NC}"
    hexo clean && hexo generate
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}清理并生成成功！${NC}"
    else
        echo -e "${RED}清理并生成过程中出现错误！${NC}"
        return 1
    fi
}

# 函数：一键发布
one_click_publish() {
    echo -e "${BLUE}开始一键发布流程...${NC}"
    
    # 1. 创建新文章
    create_post
    if [ $? -ne 0 ]; then
        echo -e "${RED}创建文章失败，中止发布流程${NC}"
        return 1
    fi
    
    # 2. 生成静态文件
    generate_blog
    if [ $? -ne 0 ]; then
        echo -e "${RED}生成静态文件失败，中止发布流程${NC}"
        return 1
    fi
    
    # 3. 部署到网站
    deploy_blog
    if [ $? -ne 0 ]; then
        echo -e "${RED}部署失败，中止发布流程${NC}"
        return 1
    fi
    
    # 4. 备份源文件
    backup_source
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}备份失败，但网站部署已完成${NC}"
        return 0
    fi
    
    echo -e "${GREEN}一键发布完成！${NC}"
}

# 主循环
while true; do
    show_menu
    read choice
    case $choice in
        1)
            create_post
            ;;
        2)
            preview_blog
            ;;
        3)
            generate_blog
            ;;
        4)
            deploy_blog
            ;;
        5)
            backup_source
            ;;
        6)
            one_click_publish
            ;;
        7)
            clean_and_generate
            ;;
        8)
            echo -e "${GREEN}再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新选择！${NC}"
            ;;
    esac
    
    echo
    read -p "按回车键继续..."
done