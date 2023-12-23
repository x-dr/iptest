#!/bin/bash
Font_Black="\033[30m";
Font_Red="\033[31m";
Font_Green="\033[32m";
Font_Yellow="\033[33m";
Font_Blue="\033[34m";
Font_Purple="\033[35m";
Font_SkyBlue="\033[36m";
Font_White="\033[37m";
Font_Suffix="\033[0m";
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'
BLUE="\033[36m"
echo "==========================================================="
echo -e "${Font_SkyBlue}Name: Cloudflare IP Test $"
echo -e "${Font_SkyBlue}Version: 1.0.0"
echo -e "${Font_SkyBlue}Author: @x-dr"
echo -e "Github: https://github.com/x-dr/CloudflareSpeedTest${Font_Suffix}"
echo "==========================================================="
echo -e "${Font_Red}Usage: bash iptest.sh [option] [argument]"
echo -e "Options:"
echo -e "  -f [filename]  Set IP file (default: ip.txt)"
echo -e "  -p [port]      Set port (default: 443)"
echo -e "  -t [tasknum]   Set task number (default: 30)"
echo -e "  -m [mode]      Set mode (default: 1)"
echo -e "                 0: No speed test"
echo -e "                 1: Speed test ${Font_Suffix}"
echo -e "==========================================================="
echo -e "${Font_Blue}Example: bash iptest.sh -f ip.txt -p 443 -t 30 -m 1 ${Font_Suffix}"
echo -e "==========================================================="

# 测试的IP文件(默认ip.txt)
filename="ip.txt"
# 扫描端口(默认443)
port=443
# 设置curl测试进程数(默认30,最大100)
tasknum=30
# 是否需要测速[(默认0.否)1.是
mode=1

while getopts "f:p:t:m:" arg; do
  case $arg in
    f) filename=$OPTARG ;;
    p) port=$OPTARG ;;
    t) tasknum=$OPTARG ;;
    m) mode=$OPTARG ;;
  esac
done



echo -e "${Font_Green}测试的IP文件:${Font_Red}$filename"
echo -e "${Font_Green}扫描端口:${Font_Red}$port"
echo -e "${Font_Green}设置curl测试进程数:${Font_Red}$tasknum"
echo -e "${Font_Green}是否需要测速:${Font_Red}$mode\n"


seconds=10
while [ $seconds -gt 0 ]; do
    echo -ne "${Font_Green}>> ${Font_Red}$seconds s${Font_Suffix} ${Font_Green}后开始测试,按 Ctrl+C 退出测试...\r"
    sleep 1
    ((seconds--))
done

echo -e "${Font_Yellow}倒计时完成！开始测试...${Font_Suffix} "



function colocation(){
curl --ipv4 --retry 3 -s https://speed.cloudflare.com/locations | sed -e 's/},{/\n/g' -e 's/\[{//g' -e 's/}]//g' -e 's/"//g' -e 's/,/:/g' | awk -F: '{print $12","$10"-("$2")"}'>colo.txt
}

function realip(){
# echo $1
sparrow=$(curl -A "trace" --resolve cf-ns.com:$port:$1 https://cf-ns.com:$port/cdn-cgi/trace  -s --connect-timeout 2 --max-time 10 | grep "uag")
# sparrow=$(curl -A "trace" --resolve sparrow.cloudflare.com:$port:$1 https://sparrow.cloudflare.com:$port/ -s --connect-timeout 1 --max-time 2 | grep "uag")
echo $sparrow
if [ "$sparrow" == "uag=trace" ]
then
	echo $1 >> realip.txt
fi
}

function rtt(){
declare -i ms
ip=$i
curl -A "trace" --retry 2 --resolve cf-ns.com:$port:$ip https://cf-ns.com:$port/cdn-cgi/trace -s --connect-timeout 2 --max-time 3 -w "timems="%{time_connect}"\n" >> log/$1
status=$(grep uag=trace log/$1 | wc -l)
if [ $status == 1 ]
then
	clientip=$(grep ip= log/$1 | cut -f 2- -d'=')
	colo=$(grep colo= log/$1 | cut -f 2- -d'=')
	location=$(grep $colo colo.txt | awk -F"-" '{print $1}' | awk -F"," '{print $1}')
	country=$(grep loc= log/$1 | cut -f 2- -d'=')
	ms=$(grep timems= log/$1 | awk -F"=" '{printf ("%d\n",$2*1000)}')
	if [[ "$clientip" == "$publicip" ]]
	then
		clientip=0.0.0.0
		ipstatus=官方
	elif [[ "$clientip" == "$ip" ]]
	then
		ipstatus=中转
	else
		ipstatus=隧道
	fi
	rm -rf log/$1
	echo "$ip,$port,$clientip,$country,$location,$ipstatus,$ms ms" >> rtt.txt
else
	rm -rf log/$1
fi
}

function speedtest(){
rm -rf log.txt speed.txt
curl --resolve speed.cloudflare.com:$2:$1 https://speed.cloudflare.com:$2/__down?bytes=300000000 -o /dev/null --connect-timeout 2 --max-time 5 -w "HTTPCODE"_%{http_code}"\n"> log.txt 2>&1
status=$(cat log.txt | grep HTTPCODE | awk -F_ '{print $2}')
if [ $status == 200 ]
then
	cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep -v 'k\|M\|received' >> speed.txt
	for i in `cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep k | sed 's/k//g'`
	do
		declare -i k
		k=$i
		k=k*1024
		echo $k >> speed.txt
	done
	for i in `cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep M | sed 's/M//g'`
	do
		i=$(echo | awk '{print '$i'*10 }')
		declare -i M
		M=$i
		M=M*1024*1024/10
		echo $M >> speed.txt
	done
	declare -i max
	max=0
	for i in `cat speed.txt`
	do
		if [ $i -ge $max ]
		then
			max=$i
		fi
	done
else
	max=0
fi
rm -rf log.txt speed.txt
echo $max
}

function cloudflarerealip(){
rm -rf realip.txt
declare -i ipnum
declare -i seqnum
declare -i n=1
ipnum=$(cat $filename | wc -l)
seqnum=$tasknum
if [ $ipnum == 0 ]
then
	echo "当前没有任何IP"
fi
if [ $tasknum == 0 ]
then
	tasknum=1
fi
if [ $ipnum -lt $tasknum ]
then
	seqnum=$ipnum
fi
trap "exec 6>&-; exec 6<&-;exit 0" 2
tmp_fifofile="./$$.fifo"
mkfifo $tmp_fifofile &> /dev/null
if [ ! $? -eq 0 ]
then
	mknod $tmp_fifofile p
fi
exec 6<>$tmp_fifofile
rm -f $tmp_fifofile
for i in `seq $seqnum`;
do
	echo >&6
done
for i in `cat $filename | tr -d '\r'`
do
		read -u6;
		{
		realip $i;
		echo >&6
		}&
		echo "RTT IP总数 $ipnum 已完成 $n"
		n=n+1
done
wait
exec 6>&-
exec 6<&-
echo "RTT IP全部测试完成"
}

function cloudflarertt(){
if [ ! -f "realip.txt" ]
then
	echo "当前没有任何REAL IP"
else
	rm -rf rtt.txt log
	mkdir log
	declare -i ipnum
	declare -i seqnum
	declare -i n=1
	ipnum=$(cat realip.txt | wc -l)
	seqnum=$tasknum
	if [ $ipnum == 0 ]
	then
		echo "当前没有任何REAL IP"
	fi
	if [ $tasknum == 0 ]
	then
		tasknum=1
	fi
	if [ $ipnum -lt $tasknum ]
	then
		seqnum=$ipnum
	fi
	trap "exec 6>&-; exec 6<&-;exit 0" 2
	tmp_fifofile="./$$.fifo"
	mkfifo $tmp_fifofile &> /dev/null
	if [ ! $? -eq 0 ]
	then
		mknod $tmp_fifofile p
	fi
	exec 6<>$tmp_fifofile
	rm -f $tmp_fifofile
	for i in `seq $seqnum`;
	do
		echo >&6
	done
	n=1
	for i in `cat realip.txt | tr -d '\r'`
	do
			read -u6;
			{
			rtt $i;
			echo >&6
			}&
			echo "REAL IP总数 $ipnum 已完成 $n"
			n=n+1
	done
	wait
	exec 6>&-
	exec 6<&-
	echo "REAL IP全部测试完成"
fi
}

publicip=$(curl --ipv4 -s https://cf-ns.com/cdn-cgi/trace | grep ip= | cut -f 2- -d'=')
#publicip=$(curl --ipv4 -s https://ipv4.gdt.qq.com/get_client_ip)

if [ ! -f "colo.txt" ]
then
	echo "生成colo.txt"
	colocation
else
	echo "colo.txt 已存在,跳过此步骤!"
fi

start=`date +%s`
echo "开始检测 $filename REAL IP有效性"
cloudflarerealip
echo "开始检测 $filename RTT信息"
cloudflarertt
if [ ! -f "rtt.txt" ]
then
	rm -rf log realip.txt rtt.txt
	echo "当前没有任何有效IP"
elif [ $mode == 1 ]
then
	timestamp=$(date +%s)
	speedfile="$timestamp-$filename.csv"
	cp realip.txt realip-$timestamp.txt
	echo "中转IP,中转端口,回源IP,国家,数据中心,IP类型,网络延迟,等效带宽,峰值速度">"$speedfile"
	for i in `cat rtt.txt | sed -e 's/ /_/g'`
	do
		ip=$(echo $i | awk -F, '{print $1}')
		port=$(echo $i | awk -F, '{print $2}')
		clientip=$(echo $i | awk -F, '{print $3}')
		if [ $clientip != 0.0.0.0 ]
		then
			echo "正在测试 $ip 端口 $port"
			maxspeed=$(speedtest $ip $port)
			maxspeed=$[$maxspeed/1024]
			maxbandwidth=$[$maxspeed/128]
			echo "$ip 等效带宽 $maxbandwidth Mbps 峰值速度 $maxspeed kB/s"
			if [ $maxspeed == 0 ]
			then
				echo "重新测试 $ip 端口 $port"
				maxspeed=$(speedtest $ip $port)
				maxspeed=$[$maxspeed/1024]
				maxbandwidth=$[$maxspeed/128]
				echo "$ip 等效带宽 $maxbandwidth Mbps 峰值速度 $maxspeed kB/s"
			fi
		else
			echo "跳过测试 $ip 端口 $port"
			maxspeed=null
			maxbandwidth=null
		fi
		if [ $maxspeed != 0 ]
		then
			echo "$i,$maxbandwidth Mbps,$maxspeed kB/s" | sed -e 's/_/ /g'>>"$speedfile"
		fi
	done
	rm -rf log realip.txt rtt.txt
	# timestamp=$(date +%s)
    # speedfile=$(echo "$(echo $filename | awk -F. '$timestamp-{print $1}').csv")
	iconv -f UTF-8 -t GBK "$speedfile" > "$speedfile-gbk.csv"
    rm -f ./latest.csv
    cp "$speedfile" latest.csv
    echo -e "${Font_Green}测速文件:${Font_Red}$speedfile"
else
	echo "中转IP,中转端口,回源IP,国家,数据中心,IP类型,网络延迟">$(echo $filename | awk -F. '{print $1}').csv
	cat rtt.txt>>$(echo $filename | awk -F. '{print $1}').csv
	rm -rf log realip.txt rtt.txt
	echo "$(echo $filename | awk -F. '{print $1}').csv 已经生成"
fi
end=`date +%s`
echo -e "${Font_Green}耗时:$[$end-$start]秒${Font_Suffix}"
