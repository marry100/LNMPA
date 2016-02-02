#!/bin/bash
#安装 LAMP
#作者 Maria
#时间 2016-1-20
#版本 0.2

#定义 PATH
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export PATH;

#检查当前用户是否root
if [ $(id -u) != "0" ]
then
    echo "请使用root用户安装LAMP！";
    exit 1;
else
    echo "当前用户是root，安装继续……";
fi

cdir=`pwd`;
arc=`arch`;

#选择Mysql、Apache、PHP的版本
versel(){
    echo "选择Mysql版本……";
    Msel=0;
    while [ $Msel -eq 0 ]
    do
        echo "1) MySQL-5.1";
        echo "2) MySQL-5.6";
        echo "3) MySQL-5.7";
		echo "4) MariaDB-5.5";
        echo "5) MariaDB-10.0";
		echo "6) MariaDB-10.1";
        read -p "请选择你要安装的Mysql版本：" Msel
        case $Msel in
        1)
            Msel=MySQL-5.1;
            mysqlver=mysql-5.1.73-linux-$arc-glibc23;
            break;;
        2)
            Msel=MySQL-5.6;
            mysqlver=mysql-5.6.28-linux-glibc2.5-$arc;
            break;;
        3)
            Msel=MySQL-5.7;
            mysqlver=mysql-5.7.10-linux-glibc2.5-$arc;
            break;;
		4)
            Msel=MariaDB-5.5;
            mysqlver=mariadb-5.5.47;
            break;;
        5)
            Msel=MariaDB-10.0;
            mysqlver=mariadb-10.0.23;
            break;;
		6)
            Msel=MariaDB-10.1;
            mysqlver=mariadb-10.1.10;
            break;;
        *)
            echo "选择错误，请重新选择！";
            Msel=0;;
        esac
    done
    echo "你选择的Mysql版本是："$Msel;

    read -p "请设置Mysql的root用户密码（默认为无密码）：" Mpasswd
    if [[ $Mpasswd != "" ]]
    then
        echo "你设置的Mysql的root用户密码为"$Mpasswd;
    else
        echo "没有设置Mysql的root用户密码";
    fi

    read -p "设置MySQL的datadir目录（默认为/data/mysql）" Mdir
    if [[ $Mdir != "" ]]
    then
        if [ -d $Mdir ]
        then
            echo "你的MySQL的datadir为"$Mdir;
        else
            mkdir -p $Mdir;
            cd $Mdir;
            Mdir=`pwd`;
            echo "你的MySQL的datadir为"$Mdir;
        fi
    else
        Mdir="/data/mysql";
        mkdir -p $Mdir;
        echo "你的MySQL的datadir为/data/mysql";
    fi

    echo "选择PHP版本……";
    Psel=0;
    while [ $Psel -eq 0 ]
    do
        echo "1) PHP-5.4";
        echo "2) PHP-5.6";
        read -p "请选择你要安装的PHP版本：" Psel
        case $Psel in
        1)
            Psel=PHP-5.4;
            phpver=php-5.4.45;
            break;;
        2)
            Psel=PHP-5.6;
            phpver=php-5.6.17;
            break;;
        *)
            echo "选择错误，请重新选择！";
            Psel=0;;
        esac
    done


    read -p "请确认使用以上选择安装LNMP环境（yes|默认yes，其他输入为重新选择）" yes
    if [[ $yes = "yes" || $yes = "y" || $yes = "" ]]
    then
        echo "开始安装……";
    else
        versel;
    fi
}

#安装 Mysql
mysql51in()
{
    ./scripts/mysql_install_db --user=mysql --datadir=$Mdir;
    if [ $? -eq 0 ]
    then
        if [ $Msel = "MySQL-5.1" ]
        then
            cp support-files/my-large.cnf /etc/my.cnf;
        elif [ $Msel = "MySQL-5.6" ]
        then
            cp support-files/my-default.cnf /etc/my.cnf;
        fi
        cp support-files/mysql.server /etc/init.d/mysqld;
        chmod 755 /etc/init.d/mysqld;
        sed -i 's#datadir=$#datadir='$Mdir'#g' /etc/init.d/mysqld;
        chkconfig --add mysqld;
        chkconfig mysqld on;
        service mysqld start;
        if [[ $Mpasswd != "" ]]
        then
            /usr/local/mysql/bin/mysqladmin -u root password ${Mpasswd}
            cat > /tmp/Mpasswd<<EOF
                use mysql;
                update user set password=password('${Mpasswd}') where user='root';
                delete from user where not (user='root') ;
                delete from user where user='root' and password='';
                flush privileges;
EOF
            /usr/local/mysql/bin/mysql -uroot -p${Mpasswd} -h localhost < /tmp/Mpasswd;
            rm -rf /tmp/Mpasswd;
            service mysqld restart;
        fi
    else
       exit 1;
    fi
}

#安装 MySQL5.7
mysql57in()
{
    ./bin/mysqld  --initialize --user=mysql --datadir=$Mdir;
    ./bin/mysql_ssl_rsa_setup --datadir=$Mdir;
    if [ $? -eq 0 ]
    then
        cp support-files/my-default.cnf  /etc/my.cnf;
        cp support-files/mysql.server /etc/init.d/mysqld;
        sed -i -e 's?# basedir = .....?basedir = /usr/local/mysql?g;s?# datadir = .....?datadir = '$Mdir'?g;s?# port = .....?port = 3306?g;s?# socket = .....?socket = /tmp/mysql.sock?g;s?^\[mysqld\]$?\[mysqld\]\nskip-grant-tables?g' /etc/my.cnf;
        chmod 755 /etc/init.d/mysqld;
        chkconfig --add mysqld;
        chkconfig mysqld on;
        service mysqld start;
        if [[ $Mpasswd != "" ]]
        then
            cat > /tmp/Mpasswd<<EOF
                use mysql;
                update user set authentication_string=password('${Mpasswd}') where user='root';
                delete from user where not (user='root') ;
                delete from user where user='root' and password='';
                flush privileges;
EOF
        else
            cat > /tmp/Mpasswd<<EOF
                use mysql;
                update user set authentication_string=password('') where user='root';
                delete from user where not (user='root') ;
                delete from user where user='root' and password='';
                flush privileges;
EOF
        fi
        /usr/local/mysql/bin/mysql -uroot < /tmp/Mpasswd;
        rm -rf /tmp/Mpasswd;
        sed -i 's?skip-grant-tables??g' /etc/my.cnf;
        cd /usr/local/mysql/lib/;
        ln -s libmysqlclient.so.20.1.0 libmysqlclient_r.so;
        service mysqld restart;
    else
       exit 1;
    fi
}

#安装MariaDB
mariadbin()
{
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DMYSQL_DATADIR=/data/mysql  -DSYSCONFDIR=/etc;
	if [ $? -ne 0 ]
	then
	    exit 1;
	else
	    make && make install;
		if [ $? -ne 0 ]
	    then
	        exit 1;
	    else
		    cd /usr/local/mysql;
            cp ./support-files/my-huge.cnf  /etc/my.cnf;
			./scripts/mysql_install_db --user=mysql  --datadir=$Mdir;
			cp support-files/mysql.server /etc/init.d/mysqld;
            chmod 755 /etc/init.d/mysqld;
            sed -i 's#datadir=$#datadir='$Mdir'#g;s#basedir=$#basedir=/usr/local/mysql#' /etc/init.d/mysqld;
			sed -i -e 's?^\[mysqld\]$?\[mysqld\]\ndatadir = '$Mdir'?g' /etc/my.cnf;
			chkconfig --add mysqld;
            chkconfig mysqld on;
            service mysqld start;
            if [[ $Mpasswd != "" ]]
            then
                /usr/local/mysql/bin/mysqladmin -u root password ${Mpasswd}
                cat > /tmp/Mpasswd<<EOF
                    use mysql;
                    update user set password=password('${Mpasswd}') where user='root';
                    delete from user where not (user='root') ;
                    delete from user where user='root' and password='';
                    flush privileges;
EOF
                /usr/local/mysql/bin/mysql -uroot -p${Mpasswd} -h localhost < /tmp/Mpasswd;
                rm -rf /tmp/Mpasswd;
                service mysqld restart;
            fi
		fi
	fi
}

#下载 MySQL
mysqldl()
{
    echo "开始安装 "$mysqlver" ……";
	rm -f /etc/my.cnf;
	useradd -s /sbin/nologin mysql -M;	
	chown -R mysql:mysql $Mdir;
    cd $cdir/src;
	if [[ $Msel = "MySQL-5.1" || $Msel = "MySQL-5.6" || $Msel = "MySQL-5.7" ]]
	then
        wget -c http://mirrors.sohu.com/mysql/$Msel/$mysqlver.tar.gz;
        tar -zxvf $mysqlver.tar.gz;
        mv $mysqlver /usr/local/mysql;
        cd /usr/local/mysql;
        if [ $Msel = "MySQL-5.1" || $Msel = "MySQL-5.6" ]
        then
            mysql51in;
        elif [ $Msel = "MySQL-5.7" ]
        then
            mysql57in;
        fi
	elif [[ $Msel = "MariaDB-5.5" || $Msel = "MariaDB-10.0" || $Msel = "MariaDB-10.1" ]]
	then
	    wget -c http://mirrors.ustc.edu.cn/mariadb//$mysqlver/source/$mysqlver.tar.gz;
		tar -zxvf $mysqlver.tar.gz;
		cd $mysqlver;
		mariadbin;
	fi
}

#安装nginx
nginxin()
{
    echo "安装 Nginx";
    cd $cdir/src;
    wget -c http://nginx.org/download/nginx-1.8.0.tar.gz;
    tar zxvf nginx-1.8.0.tar.gz ;
    cd nginx-1.8.0;
    ./configure \
        --prefix=/usr/local/nginx \
        --with-pcre ;
    make && make install;
    if [ $? -ne 0 ]
    then
        exit 1;
    else
        cp $cdir/nginx /etc/init.d/nginx;

        sed -i '65s?#??g;66s?\#??g;67s?#??g;68s?#??g;69s?#??g;70s?#??g;71s?#??g;69s?/scripts$fastcgi_script_name;?/usr/local/nginx/html\$fastcgi_script_name;?g' /usr/local/nginx/conf/nginx.conf;
        chmod 755 /etc/init.d/nginx;
        chkconfig --add nginx;
        chkconfig nginx on;
        service nginx start;
        chkconfig nginx on;
    fi
}

#安装php
phpin()
{
    echo "安装 "$Psel;
    cd $cdir/src;
    wget -c http://cn2.php.net/distributions/$phpver.tar.gz;
    tar zxvf $phpver.tar.gz;
    useradd -s /sbin/nologin php-fpm -M
    cd $phpver;
    ./configure \
        --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --enable-fpm \
        --with-fpm-user=php-fpm \
        --with-fpm-group=php-fpm \
        --with-mysql=/usr/local/mysql \
        --with-mysql-sock=/tmp/mysql.sock \
        --with-libxml-dir \
        --with-gd \
        --with-jpeg-dir \
        --with-png-dir \
        --with-freetype-dir \
        --with-iconv-dir \
        --with-zlib-dir \
        --with-mcrypt \
        --enable-soap \
        --enable-gd-native-ttf \
        --enable-ftp \
        --enable-mbstring \
        --enable-exif \
        --disable-ipv6 \
        --with-curl ;
    make && make install ;
    if [ $? -ne 0 ]
    then
        exit 1;
    else
        cp $cdir/src/$phpver/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm;
        mv /usr/local/php/etc/php-fpm.conf.default  /usr/local/php/etc/php-fpm.conf;
        chmod 755 /etc/init.d/php-fpm;
        chkconfig --add php-fpm;
        chkconfig php-fpm on;
        service php-fpm start;
        chkconfig php-fpm on;
    fi
}

#完成安装
finishin()
{


    echo "进行安装完配置过程……";
    echo -e 'PATH=$PATH:/usr/local/mysql/bin:/usr/local/nginx/bin\nexport PATH' >/etc/profile.d/path.sh;
    source /etc/profile.d/path.sh;
    echo -e '<?php\n    echo "php解析正常"; \n?>' > /usr/local/nginx/html/1.php;
    netstat -lnp;
    curl localhost/1.php;
    echo "";
    echo "安装LNMP成功！";
}

#安装初始化
ininit()
{
    #关闭SELINUX
    echo "关闭SELINUX";
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config;
    setenforce 0;
    #清空iptables
    echo "清空iptables";
    iptables -F && service iptables save;
    if [ ! -d $cdir/src ]
    then
         mkdir $cdir/src;
    fi
    while :
    do
        yum install -y wget epel-release;
        if [ $? -eq 0 ]
        then
             break;
        fi
    done
    # 更换阿里云源
#    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup;
 #   wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo;
  #  yum clean all;
   # yum makecache;
    yum install -y kernel kernel-devel;
    yum install -y gcc make compat-libstdc++-33 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libpng libpng-devel freetype freetype-devel libcurl libcurl-devel libjpeg-turbo libjpeg-turbo-devel libmcrypt libmcrypt-devel pcre pcre-devel;
    if [[ $Msel = "MySQL-5.6" || $Msel = "MySQL-5.7" ]]
    then
        yum install -y libaio;
    fi
	if [[ $Msel = "MariaDB-5.5" || $Msel = "MariaDB-10.0" || $Msel = "MariaDB-10.1" ]]
	then 
	    yum  install -y apr* autoconf automake curl curl-devel gcc-c++ gtk+-devel zlib-devel pcre-devel gd kernel keyutils patch perl kernel-headers compat*  cpp glibc libgomp libstdc++-devel keyutils-libs-devel libsepol-devel libselinux-devel krb5-devel  libXpm* fontconfig fontconfig-devel  gettext gettext-devel ncurses* libtool* libxml2 patch policycoreutils bison cmake;
    fi
    if [ $Asel = "Apache-2.4" ]
    then
        yum install -y pcre-devel;
        aprin;
    fi
}

#安装过程
LNMPinstall()
{
    versel;
    ininit;
    mysqldl;
    phpin;
    nginxin;
    finishin;
}
LNMPinstall 2>&1 | tee $cdir/install.log;

