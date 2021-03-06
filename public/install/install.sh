#!/bin/bash
function removeOpenVPN() {
	systemctl stop openvpn@server.service >/dev/null 2>&1
	yum -y remove openvpn >/dev/null 2>&1
	rm -rf /etc/openvpn
	sleep 1
	return 1
}

function removeSquid() {
	systemctl stop squid.service >/dev/null 2>&1
	yum -y remove squid >/dev/null 2>&1
	rm -rf /etc/squid
	sleep 1
	return 1
}

function removeMproxy() {
	killall mproxy >/dev/null 2>&1
	sleep 1
	return 1
}

function removeIptables() {
	systemctl stop iptables >/dev/null 2>&1
	rm -rf /etc/sysconfig/iptables >/dev/null 2>&1
	sleep 1
	return 1
}

function removeNginx() {
	systemctl stop nginx.service >/dev/null 2>&1
	yum remove -y nginx >/dev/null 2>&1
	rm -rf /etc/nginx >/dev/null 2>&1
	rm -rf /var/log/nginx >/dev/null 2>&1
	rm -rf /home/www >/dev/null 2>&1
	rm -rf /usr/share/nginx >/dev/null 2>&1
	sleep 1
	return 1
}

function removePHP() {
	systemctl stop php-fpm >/dev/null 2>&1
	yum -y remove php-fpm >/dev/null 2>&1
	rm -rf /etc/php-fpm.d >/dev/null 2>&1
	rm -rf /etc/php.d >/dev/null 2>&1
	sleep 1
	return 1
}

function removeMySQL() {
	systemctl stop mariadb.service >/dev/null 2>&1
	systemctl stop mysqld.service >/dev/null 2>&1
	/etc/init.d/mysqld stop >/dev/null 2>&1
	yum remove -y mariadb mariadb-server >/dev/null 2>&1
	yum remove -y mysql mysql-server>/dev/null 2>&1
	rm -rf /var/lib/mysql
	rm -rf /var/lib/mysql
	rm -rf /usr/lib64/mysql
	rm -rf /etc/my.cnf
	rm -rf /var/log/mysql
	sleep 1
	return 1
}

function removeLNMP() {
	removeNginx
	removeMySQL
	removePHP
	sleep 1
	return 1
}

function getStart() {
	echo -e "开始获取环境变量..."
	sleep 1
	echo -e "获取当前主机IP地址..."
	ip=`curl -s http://members.3322.org/dyndns/getip`
	echo "当前外网IP:$ip"
	sleep 1
	# 安装文件
	mproxy='http://xtype-10012532.cos.myqcloud.com/mproxy'
	openvpn='http://xtype-10012532.cos.myqcloud.com/openvpn.tar'
	squid='http://xtype-10012532.cos.myqcloud.com/squid.tar'
	# 端口信息
	serverPort=3344
	vpnPort=440
	mproxyPort=8080
	squidPort=80

	# 数据库信息
	DBHOST=''
	DB=''
	DBADMIN=''
	DBPASSWD=''

	echo
	echo -e "请输入VPN端口[默认$vpnPort]:\c"
	read vpnPort
	if [[ -z $vpnPort ]] 
 	then
	 	vpnPort=440
	fi
	echo -e "已设置VPN端口:\033[32m $vpnPort \033[0m"

	echo
	echo -e "请输入HTTP转接端口[默认$mproxyPort]:\c"
	read mproxyPort
	if [[ -z $mproxyPort ]] 
 	then
	 	mproxyPort=8080
	fi
	echo -e "已设置HTTP转接端口:\033[32m $mproxyPort \033[0m"

	echo
	echo -e "请输入常规转接端口[默认$squidPort]:\c"
	read squidPort
	if [[ -z $squidPort ]] 
 	then
	 	squidPort=80
	fi
	echo -e "已设置常规转接端口:\033[32m $squidPort \033[0m"

	echo
	echo -e "请输入网站服务器端口[默认$serverPort]:\c"
	read serverPort
	if [[ -z $serverPort ]] 
 	then
	 	serverPort=3344
	fi
	echo -e "已设置网站服务器端口:\033[32m $serverPort \033[0m"

	rm -rf /root/xtype_install >/dev/null 2>&1
	mkdir /root/xtype_install && cd /root/xtype_install

	echo
	echo -e "获取环境变量完成"
	sleep 1
	return 1
}

function setNetWork() {
	echo
	echo -e "正在配置网络环境..."
	sleep 1
	systemctl stop firewalld.service >/dev/null 2>&1
	systemctl disable firewalld.service >/dev/null 2>&1
	yum -y install iptables-services
	yum -y install vim vim-runtime ctags
	setenforce 0
	echo "/usr/sbin/setenforce 0" >> /etc/rc.local
	sleep 1
	mkdir /dev/net; mknod /dev/net/tun c 10 200 >/dev/null 2>&1
	echo "加入网速优化..."
	echo "net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296" >/etc/sysctl.conf
	sysctl -p >/dev/null 2>&1
	echo
	echo -e "优化完成"
	sleep 1
	echo
	echo "配置防火墙..."
	systemctl start iptables >/dev/null 2>&1
	iptables -F >/dev/null 2>&1
	systemctl stop iptables >/dev/null 2>&1
	sleep 1
	echo "# Generated by iptables-save v1.4.21 on Sat Sep 17 09:24:35 2016
*nat
:PREROUTING ACCEPT [1:40]
:INPUT ACCEPT [1:40]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $ip
-A POSTROUTING -j MASQUERADE
COMMIT
# Completed on Sat Sep 17 09:24:35 2016
# Generated by iptables-save v1.4.21 on Sat Sep 17 09:24:35 2016
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp -m tcp --dport 1234 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 137 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 138 -j ACCEPT
-A INPUT -p tcp -m tcp --dport $mproxyPort -j ACCEPT
-A INPUT -p tcp -m tcp --dport $vpnPort -j ACCEPT
-A INPUT -p tcp -m tcp --dport $squidPort -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 25 -j DROP
-I INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 -j DROP
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
COMMIT
# Completed on Sat Sep 17 09:24:35 2016" >/etc/sysconfig/iptables
	systemctl start iptables >/dev/null 2>&1
	echo
	echo "配置防火墙完成"
	sleep 1
	return 1
}

function installMySQL() {
	echo
	echo "安装MySQL..."
	sleep 1
	yum -y install mysql
	service mysqld start
	systemctl enable mysqld
	echo
	echo "安装MySQL完成"
	sleep 1
	return 1
}

function installOpenVPN() {
	echo 
	echo "安装OpenVPN..."
	sleep 1
	killall openvpn >/dev/null 2>&1
	yum -y install openvpn
	rm -rf /etc/openvpn
	wget $openvpn && tar xvf ./openvpn.tar -C /etc/ >/dev/null 2>&1
	sed -i 's/port 440/port '$vpnPort'/g' /etc/openvpn/server.conf >/dev/null 2>&1
	chmod -R 777 /etc/openvpn
	systemctl enable openvpn@server.service
	echo
	echo "安装OpenVPN完成"
	sleep 1
	return 1
}

function installSquid() {
	echo 
	echo "安装Squid..."
	sleep 1
	killall squid >/dev/null 2>&1
	yum -y install squid
	rm -rf /etc/squid
	wget $squid && tar xvf ./squid.tar -C /etc >/dev/null 2>&1
	sed -i 's/http_port 80/http_port '$squidPort'/g' /etc/squid/squid.conf >/dev/null 2>&1
	chmod -R 777 /etc/squid
	systemctl enable squid
	echo
	echo "安装Squid完成"
	sleep 1
	return 1
}

function installNginx() {
	echo 
	echo "安装Nginx..."
	sleep 1
	killall nginx >/dev/null 2>&1
	yum -y install nginx
	systemctl enable nginx
	return 1
}

function installPHP() {
	echo 
	echo "安装PHP..."
	sleep 1
	yum -y install php php-mysql php-fpm
	systemctl enable php-fpm
	systemctl enable php-mysql
	systemctl enable php
	return 1
}

function installGit() {
	echo 
	echo "安装Git..."
	sleep 1
	yum -y install git
	echo
	echo "安装Git完成"
	sleep 1
	return 1
}

function updateRepo() {
	echo 
	echo "更新源..."
	sleep 1
	rm -rf /etc/yum.repos.d/*.backup >/dev/null 2>&1
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
	yum clean all
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	wget http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
	rpm -ivh  epel-release-latest-7.noarch.rpm
	yum makecache
	# yum -y update
	echo "更新源完毕"
	sleep 1
	return 1
}

function clearInstall() {
	echo
	echo "清除安装痕迹..."
	sleep 1
	rm -rf /root/xtype_install >/dev/null 2>&1
	rm -rf /etc/yum.repos.d/CentOS-Base.repo
	mv /etc/yum.repos.d/CentOS-Base.repo.backup /etc/yum.repos.d/CentOS-Base.repo
	yum clean all
	yum makecache
	echo "清除安装痕迹完成"
	sleep 1
	return 1
}

function clearAll() {
	echo 
	echo -e "整理残留环境..."
	sleep 1
	removeOpenVPN
	removeSquid
	removeMproxy
	removeIptables
	# removeLNMP
	echo -e "整理完毕"
	echo
	sleep 1
	return 1
}

function installLNMP() {
	echo 
	echo -e "急速安装LNMP..."
	sleep 1
	# installMySQL
	# installNginx
	# installPHP

	# do something...
	echo -e "安装LNMP完成"
	sleep 1
	return 1
}

function finish() {
	echo 
	echo '正在生成命令'
	rm -rf /bin/vpn >/dev/null 2>&1
	mv /etc/openvpn/vpn /bin/ >/dev/null 2>&1
	chmod 777 /bin/vpn >/dev/null 2>&1
	echo "DBHOST='$DBHOST'
DB='$DB'
DBADMIN='$DBADMIN'
DBPASSWD='$DBPASSWD'
IP='$ip'
source /etc/openvpn/deal" >/etc/openvpn/database
	chmod -R 777 /etc/openvpn/

	echo "*/1 * * * * /bin/bash /etc/openvpn/flow" > "/var/spool/cron/${USER}"
	systemctl restart crond

	yum -y install telnet

	vpn restart
	clear
	echo "环境已经安装完成"
	echo "当前外网IP: $ip"
	echo "VPN端口: $vpnPort"
	echo "Squid端口: $squidPort"
	echo "HTTP转接端口1: $mproxyPort"
	echo "HTTP转接端口2: 137"
	echo "HTTP转接端口3: 138"
	echo "用 vpn [stop|start|restart] 来管理VPN"
	echo "用 lnmp [stop|start|restart] 来管理网站服务器"
	return 1
}

echo 
echo -e "安装程序准备开始..."
yum -y install curl
sleep 1

# 获取变量
getStart
echo -e "\033[33m即将开始安装环境\033[0m"
echo -e "\033[31m一旦开始安装将开始清除当前服务器环境，继续请输入 yes:\033[0m \c"
read KEY
action=$KEY
if [[ ${action%%\ *} == yes ]]; then
	# 更新源
	updateRepo
	# 清理环境
	clearAll
	# 设置网络
	setNetWork
	# 安装OpenVPN
	installOpenVPN
	# 安装Squid
	installSquid
	# 安装LNMP
	installLNMP
	# 清理安装痕迹
	clearInstall
	# 完成
	finish
else
	echo "安装程序结束，未做任何修改"
fi
exit 0;