#!/bin/bash
#Dnspod DDNS with BashShell
#Github:https://github.com/lijian0103/dnspod-ddns.git
#CONF START
API_ID=12345
API_Token=abcdefjhijklmn1234
domain=example.com
subdomain[0]="\*"
subdomain[1]="@"
subdomain[2]="www"
Email=example@qq.com
CHECKURL="http://ip.qq.com"
#OUT="pppoe"
#CONF END

date
if (echo $CHECKURL |grep -q "://");then
IPREX='([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
URLIP=$(curl $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s $CHECKURL|grep -Eo "$IPREX"|tail -n1)
echo "[URL IP]:$URLIP"
dnscmd="nslookup";type nslookup >/dev/null || dnscmd="ping -c1"
DNSTEST=$($dnscmd $domain)
if [ "$?" == 0 ];then
DNSIP=$(echo $DNSTEST|grep -Eo "$IPREX"|tail -n1)
else DNSIP="Get $domain DNS Failed."
fi
echo "[DNS IP]:$DNSIP"
if [ "$DNSIP" == "$URLIP" ];then
echo "IP SAME IN DNS,SKIP UPDATE."
exit
fi
fi
for sub in ${subdomain[@]}
do
  
  sub="$(echo ${sub} | sed 's/\\//')"
  
token="login_token=${API_ID},${API_Token}&format=json&lang=en&error_on_empty=yes&domain=${domain}&sub_domain=${sub}"
UA="User-Agent: 03K DDNS Client/1.0.0 ($Email)"
Record="$(curl $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s -X POST https://dnsapi.cn/Record.List -d "${token}" -H "${UA}")"
iferr="$(echo ${Record#*code}|cut -d'"' -f3)"
if [ "$iferr" == "1" ];then
record_ip=$(echo ${Record#*value}|cut -d'"' -f3)
echo "[${sub}][API IP]:$record_ip"
if [ "$record_ip" == "$URLIP" ];then
echo "IP SAME IN API,SKIP UPDATE."
else
record_id=$(echo ${Record#*records}|cut -d'"' -f5)
record_line_id=$(echo ${Record#*line_id}|cut -d'"' -f3)
echo Start DDNS update...
ddns="$(curl $(if [ -n "$OUT" ]; then echo "--interface $OUT"; fi) -s -X POST https://dnsapi.cn/Record.Ddns -d "${token}&record_id=${record_id}&record_line_id=${record_line_id}" -H "${UA}")"
ddns_result="$(echo ${ddns#*message\"}|cut -d'"' -f2)"
echo -n "DDNS upadte result:$ddns_result "
echo $ddns|grep -Eo "$IPREX"|tail -n1
fi
else echo -n Get ${sub}.$domain error :
echo $(echo ${Record#*message\"})|cut -d'"' -f2
fi
done
