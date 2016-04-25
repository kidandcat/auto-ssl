#! /bin/bash
if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    sudo -i
fi
if ! type "npm" > /dev/null; then
  apt-get install --yes npm
fi
npm install -g n
n stable
npm install -g http-master
a2dismod ssl
service apache2 restart
mkdir /etc/master-ssl
cp netelip.pem /etc/master-ssl/
cp netelip.key /etc/master-ssl/

cat <<EOF > /etc/master-ssl/http.conf
{
logging: true,
ports: {
    443: {
      router: {
      	'*' : 127.0.0.1:80
      },
      ssl : {
        key: '/etc/master-ssl/netelip.key',
        cert: '/etc/master-ssl/netelip.pem'
      }
    }
  }
}
EOF
cat <<EOF > /etc/init/master-ssl.conf
description "http-master proxy"
author      "Jairo Caro-Accino Viciana"

start on filesystem or runlevel [2345]
stop on shutdown

script

    http-master --config /etc/master-ssl/http.conf

end script

pre-start script
    echo "['date'] http-master proxy starting" >> /var/log/nodetest.log
end script

pre-stop script
    rm /var/run/nodetest.pid
    echo "['date'] http-master proxy stopping" >> /var/log/nodetest.log
end script
EOF
initctl reload-configuration
initctl list
service master-ssl start
