Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_docker(){
    check_root
    curl -fsSL https://get.docker.com | bash -s docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sudo apt-get install -y docker-compose
    echo "docker 安装完成"
}

install_muon(){
    echo "正在下载安装,请确保服务器网络正常同时有20GB以上的硬盘空间"
    git clone https://github.com/muon-protocol/muon-node-js.git --recurse-submodules --branch testnet
    cd muon-node-js
    docker-compose build
    docker-compose up -d
    sleep 5
    echo "启动成功！"
    echo "请访问网址 http://此处替换为你的服务器IP:8000/status"
}

run_muon(){
    docker-compose up -d $(docker-compose ps -a | grep muon-node | awk '{ print $3}')
    echo "启动成功！已在后台运行"
    echo "请使用检查状态功能确保正常运行"
    echo "假如没启动成功可运行命令 'docker-compose up -d muon_api' "
}

stop_muon(){
    docker-compose down $(docker-compose ps -a | grep muon-node | awk '{ print $3}')
    sleep 10
    echo "停止成功！"
}

log_muon(){
    echo "正在查询，如需退出 LOG 查询请使用 CTRL+C"
    docker-compose logs -f muon_api
}

backup_muon(){
    echo "该功能会创建一个节点容器的 .env 备份文件并保存在服务器根目录 /root 下"
    echo "此文件包含私钥，请保存在安全的位置"
    docker cp muon-node:/usr/src/muon-node-js/.env ./
    echo "备份导出成功，请查看 /root 目录下是否有 .env 文件"
}

restore_muon(){
    echo "如果你需要导入之前的节点备份，请在安装并运行Muon后的情况下使用该功能"
    echo "执行此操作前请把 .env 文件放在根目录下"
    docker cp .env muon-node:/usr/src/muon-node-js/
    docker-compose restart
    sleep 5
    echo "导入成功后请访问网址 http://此处替换为你的服务器IP:8000/status"
    echo "会返回原先备份时的 address 和 peerId 则证明导入成功"
}

clean_muon(){
    echo "由于官方Bug，错误日志会增加服务器硬盘占用导致空间不够，需要定时清除"
    echo "建议1天进行一次日志清除,正在执行中...."
    cat /dev/null > $(docker inspect --format='{{.LogPath}}' $(docker ps -a | grep muon-node | awk '{ print $1}'))
    echo "清除结束,假如你更改了容器的命名或者服务器磁盘空间没有减少"
    echo "请前往目录 /var/lib/docker/containers/ 下的节点容器,清除.log结尾的文件即可"
}

echo && echo -e " ${Red_font_prefix}Moun 一键脚本${Font_color_suffix} by \033[1;35mLattice\033[0m
此脚本完全免费开源，由推特用户 ${Green_font_prefix}@L4ttIc3${Font_color_suffix} 开发
推特链接：${Green_font_prefix}https://twitter.com/L4ttIc3${Font_color_suffix}
欢迎关注，如有收费请勿上当受骗
 ———————————————————————
 ${Green_font_prefix} 1.安装 docker ${Font_color_suffix}
 ${Green_font_prefix} 2.安装并运行 Muon ${Font_color_suffix}
  -----节点功能------
 ${Green_font_prefix} 3.运行 Muon 节点 ${Font_color_suffix}
 ${Green_font_prefix} 4.停止 Muon 节点 ${Font_color_suffix}
  -----其他功能------
 ${Green_font_prefix} 5.查询 Muon 日志 ${Font_color_suffix}
 ${Green_font_prefix} 6.备份 Muon 节点 ${Font_color_suffix}
 ${Green_font_prefix} 7.恢复 Muon 节点 ${Font_color_suffix}
 ${Green_font_prefix} 8.清除 Muon 日志 ${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请输入数字 [1-7]:" num
case "$num" in
1)
    install_docker
    ;;
2)
    install_muon
    ;;
3)
    run_muon
    ;;
4)
    stop_muon
    ;;
5)
    log_muon
    ;;
6)
    backup_muon
    ;;
7)
    restore_muon
    ;;
8)
    clean_muon
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac
