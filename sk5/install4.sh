#!/bin/bash
#获取本机非127.0.0的ip个数


#!/bin/bash

#安装wget

echo 正在处理，请耐心等待
rpm -qa|grep "wget" &> /dev/null
if [ $? == 0 ]; then
    echo 环境监测通过
else
    yum -y install wget
fi


# 设置网络

sed -i '/^IPADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '/^PREFIX/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '/^GATEWAY/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-eth0

a=( `cat ipstr.txt` )
b=( `cat ip.txt` )
c=( `cat l2tpip.txt` )
for ((i=0; i<10; ++i))
do
	echo "${a[$i]}${b[$i]}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
	echo "PREFIX$i=24" >> /etc/sysconfig/network-scripts/ifcfg-eth0
done

#此处修改网关，天翼云一般默认是192.168.0.1，不需要修改
echo "GATEWAY0=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth0

sleep 5
systemctl restart network
echo "sleep 5"
ip addr

# 设置DNS，重启网络之后好像/etc/resolv.conf中的配置就被自动清除了
echo "nameserver 223.5.5.5" >> /etc/resolv.conf

# 配置系统sysctl
cat >/etc/sysctl.d/60-sysctl_ipsec.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.eth0.accept_redirects = 0
net.ipv4.conf.eth0.rp_filter = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.eth1.accept_redirects = 0
net.ipv4.conf.eth1.rp_filter = 0
net.ipv4.conf.eth1.send_redirects = 0
net.ipv4.conf.eth2.accept_redirects = 0
net.ipv4.conf.eth2.rp_filter = 0
net.ipv4.conf.eth2.send_redirects = 0
net.ipv4.conf.ip_vti0.accept_redirects = 0
net.ipv4.conf.ip_vti0.rp_filter = 0
net.ipv4.conf.ip_vti0.send_redirects = 0
net.ipv4.conf.lo.accept_redirects = 0
net.ipv4.conf.lo.rp_filter = 0
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.conf.ppp0.accept_redirects = 0
net.ipv4.conf.ppp0.rp_filter = 0
net.ipv4.conf.ppp0.send_redirects = 0

EOF

sysctl -p /etc/sysctl.d/60-sysctl_ipsec.conf



systemctl stop firewalld
systemctl mask firewalld

# 设置filter规则
iptables  -F

iptables -I FORWARD -s 172.16.100.0/24 -j ACCEPT
iptables -I FORWARD -d 172.16.100.0/24 -j ACCEPT
iptables -A INPUT -p udp -m policy --dir in --pol ipsec -m udp --dport 1701 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 1701 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 4500 -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT
iptables -A INPUT -m policy --dir in --pol ipsec -j ACCEPT
iptables -A FORWARD -i ppp+ -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT


# 设置nat规则
iptables -t nat -F

for ((i=0; i<10; ++i))
do
	iptables -t nat  -A POSTROUTING -o eth0 -d 0.0.0.0/0 -s ${c[$i]} -j SNAT --to-source ${b[$i]}
done

service iptables save
systemctl restart iptables
systemctl enable iptables
systemctl status iptables

systemctl start xl2tpd
systemctl enable  xl2tpd
systemctl status xl2tpd

systemctl start ipsec
systemctl enable ipsec
ipsec verify



systemctl restart network
ip addr
iptables -L -n --line-number -t nat




v=`ip addr|grep -o -e 'inet [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'|grep -v "127.0.0"|awk '{print $2}'| wc -l`
num=`cat /proc/sys/net/ipv6/conf/all/disable_ipv6`

if [[ "$num" -eq "0" ]];then
cat >>/etc/sysctl.conf <<END
#disable ipv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
END
fi
#if [ "$v" -gt "300" ];then  
    #echo -e "\033[41m"该服务器IP已经超过300个，你要继续吗！！！按任意键继续...或按 Ctrl+c 取消"  \033[0m"&&read -s -n1
#fi
#echo -e "\033[33m是否安装过bbr,第一次建议选择 1 否则选择0，默认也不执行(BBR安装时间较久) \033[0m"&&read value
#if [ $value -eq 1 ]; then
   # yum update
    #bash <(curl -s -L http://121.37.156.102/zyysk5/bbr.sh)

#fi

echo "脚本由 狗子qq1083773908 提供。需要站群联系作者8c段价格低致1000一台"
#echo -e "\033[33m 请输入我们的暗号~ \033[0m"&&read id
#if [ "$id" = "89481141" ];then
   echo 正在处理，请耐心等待
   #echo -e "\033[33m-------若为多IP服务器请确认是否已配置好IP地址...按任意键继续 或按 Ctrl+c 取消-------\033[0m"&&read -s -n1
   echo;rm -fr /tmp/cut&&touch /tmp/cut
   read -p "请在30秒内输入端口否则使用随机端口："  -t 30  port
   if [ $port -gt 1999 -a $port -lt 60000 ] 2>/dev/null ;then
   echo -e "\033[33m您输入的端口为：$port\033[0m";echo "port=$port">>/tmp/cut
   else
   echo -e "\033[33m您输入的端口错误，将使用随机端口！\033[0m" 
   fi
   read -p "请在30秒内输入密码否则使用随机密码："  -t 30  pass
   if [ ! -n "$pass" ]; then
   echo -e "\033[33m您输入的密码为空，将使用随机密码！\033[0m" 
   else
   echo -e "\033[33m您输入的密码为：$pass\033[0m";echo "pass=$pass">>/tmp/cut
   fi
   echo
   echo -e "\033[35m".........请耐心等待正在安装中........."\033[0m"
   echo 
   bash <(curl -s -L https://github.com/fengzi334/VPS/blob/main/sk5/newsocks5.sh)  t.txt >/dev/null 2>&1
   PIDS=`ps -ef|grep gost|grep -v grep`
   if [ "$PIDS" != "" ]; then
      s=`ps -ef|grep gost|grep -v grep|awk '{print $2}'| wc -l`
      echo -e "\033[35m检测到本机共有$v个IP地址，并成功搭建$s条;多ip服务器游戏推荐使用：方式二\033[0m"
      cat /tmp/s5
      
      echo -e "\033[33m 是否需要导出所有的配置数据到电脑上？需要请输入 1 ,文件名是 s5 t.txt \033[0m"&&read value
      if [ $value -eq 1 ]; then
            yum -y install lrzsz
            echo -e "\033[41m" 开始导出，请注意文件名是s5 t.txt "\033[0m"
            sz /tmp/s5
            echo -e "\033[41m" 请注意，文件名是 s5 t.txt "\033[0m"
      fi
      
      
      echo -e "\033[33m  安装已到位。需要站群的联系作者，8c段的低致1100¥一台 \033[0m"&&read -s -n1
      history -c&&echo > ./.bash_history
   else
      echo -e "\033[41m安装失败!!! 未知错误请联系作者 \033[0m"
   fi
else
   echo 
   echo -e "\033[41m" 模式错误。该工具仅限内部使用 "\033[0m"
   echo 

#fi
