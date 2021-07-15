#!/bin/sh

# Set variables
ipaddress=$(ifconfig epair0b | awk '/inet/ { print $2 }'| sed -e 's/[]$.*[\^]/\\&/g')
password_secret=$(pwgen -N 1 -s 96)
root_password_sha2=$(echo -n graylog | shasum -a 256)

# Enable services
sysrc graylog_enable="YES"
sysrc elasticsearch_enable="YES"
sysrc mongod_enable="YES"

# Update elasticsearch.yaml, start elasticsearch and mongod
sed -i elasticsearch.yml 's/\#cluster\.name\:\ my\-application/cluster\.name\:\ graylog/g' /usr/local/etc/elasticsearch/elasticsearch.yml
service elasticsearch start
service mongod start

# Configure directories
mkdir /usr/local/etc/graylog/server
mkdir /usr/local/share/graylog/journal
touch /usr/local/etc/graylog/server/node-id
chown -R graylog:graylog /usr/local/etc/graylog
chown -R graylog:graylog /usr/local/share/graylog/

# Update graylog.conf
sed -i graylog.conf 's/node\_id\_file\ \=\ \/etc\/graylog\/server\/node-id/node\_id\_file\ \=\ \/usr\/\local\/etc\/graylog\/server\/node-id/g' /usr/local/etc/graylog/graylog.conf
sed -i graylog.conf 's/bin\_dir\ \=\ bin/\bin\_dir\ \=\ \/usr\/local\/share\/graylog/g' /usr/local/etc/graylog/graylog.conf
sed -i graylog.conf 's/plugin\_dir\ \=\ plugin/\plugin\_dir\ \=\ \/usr\/local\/share\/graylog\/plugin/g' /usr/local/etc/graylog/graylog.conf
sed -i graylog.conf 's/data\_dir\ \=\ data/\data\_dir\ \=\ \/usr\/local\/share\/graylog/g' /usr/local/etc/graylog/graylog.conf
sed -i -e "s/\#http\_bind\_address\ \=\ 127\.0\.0\.1\:9000/http\_bind\_address\ \= $ipaddress\:9000/g" /usr/local/etc/graylog/graylog.conf
sed -i graylog.conf 's/message\_journal\_dir\ \=\ data\/journal/message\_journal\_dir\ \=\ \/usr\/local\/share\/graylog\/journal/g' /usr/local/etc/graylog/graylog.conf
sed -i -e "s/password\_secret\ \=/password\_secret\ \=\ $password_secret/g" /usr/local/etc/graylog/graylog.conf
sed -i -e "s/root\_password\_sha2\ \=/root\_password\_sha2\ \=\ $root_password_sha2/g" /usr/local/etc/graylog/graylog.conf

# Start graylog
service graylog start

# Output info
echo "Username: admin" > /root/PLUGIN_INFO
echo "Password: graylog" >> /root/PLUGIN_INFO
echo "Password Secret: $password_secret" >> /root/PLUGIN_INFO