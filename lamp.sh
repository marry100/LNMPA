#!/bin/bash
#安装 LAMP
#作者 Maria
#时间 2016-1-23
#版本 1.9

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

checkOK()
{
    if [ $? -ne 0 ]
	then
	    exit 1;
	fi
}

#选择Mysql、Apache、PHP的版本
versel(){
    echo "选择数据库版本……";
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

    echo "选择Apache版本……";
    Asel=0;
    while [ $Asel -eq 0 ]
    do
        echo "1) Apache-2.2";
        echo "2) Apache-2.4";
        read -p "请选择你要安装的Apache版本：" Asel
        case $Asel in
        1)
            Asel=Apache-2.2;
            httpver=httpd-2.2.31;
            break;;
        2)
            Asel=Apache-2.4;
            httpver=httpd-2.4.18;
            break;;
        *)
            echo "选择错误，请重新选择！";
            Asel=0;;
        esac
    done
    echo "你选择的Apache版本是："$Asel;

    read -p "是否开启Apache开机启动？（yes|no，默认为开启）" Astart
    if [[ $Astart = "yes" || $Astart = "y" || $Astart = "" ]]
    then
        echo "开启Apachel开机启动！";
    else
        echo "不开启Apache开机启动";
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


    read -p "请确认使用以上选择安装LAMP环境（yes|默认yes，其他输入为重新选择）" yes
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
    checkOK;
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
}

#安装 MySQL5.7
mysql57in()
{
    ./bin/mysqld  --initialize --user=mysql --datadir=$Mdir;
    ./bin/mysql_ssl_rsa_setup --datadir=$Mdir;
    checkOK;
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
}

#安装MariaDB
mariadbin()
{
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DMYSQL_DATADIR=/data/mysql  -DSYSCONFDIR=/etc;
	checkOK;
	make && make install;
	checkOK;
	    cd /usr/local/mysql;
        cp ./support-files/my-huge.cnf  /etc/my.cnf;
		./scripts/mysql_install_db --user=mysql  --datadir=$Mdir;
		checkOK;
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



#下载Apache
apachedl()
{
    echo "开始安装 "$Asel" ……";
    cd $cdir/src;
    wget -c http://mirrors.cnnic.cn/apache/httpd/$httpver.tar.gz;
    tar zxvf $httpver.tar.gz;
    cd $httpver;
    if [ $Asel = "Apache-2.2" ]
    then
        apache22in;
    elif [ $Asel = "Apache-2.4" ]
    then
        apache24in;
    fi
}

#配置Apache启动项
apachecon()
{
    echo "配置"$Asel"系统启动项";
    cp /usr/local/apache/bin/apachectl /etc/init.d/httpd；
    sed -i -e 's#\/bin\/sh$#\/bin\/sh\n\#chkconfig: 2345 85 15#g' /etc/init.d/httpd;
    chmod 755 /etc/init.d/httpd;
    chkconfig --add httpd;
    chkconfig httpd on;
    service httpd restart;
}
#安装Apache2.2
apache22in()
{
    ./configure \
        --prefix=/usr/local/apache \
        --with-included-apr \
        --enable-so \
        --enable-deflate=shared \
        --enable-expires=shared \
        --enable-rewrite=shared \
        --with-pcre
    make && make install;
    checkOK;
    sed -i -e 's#AddType application/x-gzip .gz .tgz#&\n    AddType application/x-httpd-php .php#g' /usr/local/apache/conf/httpd.conf;
    sed -i 's#DirectoryIndex index.html#& index.htm index.php#g' /usr/local/apache/conf/httpd.conf
    sed -i 's#\#ServerName www.example.com:80#ServerName localhost:80#g' /usr/local/apache/conf/httpd.conf
    if [[ $Astart = "yes" || $Astart = "y" || $Astart = "" ]]
    then
        apachecon;
    fi
}

#安装Apr和Apr-util
aprin()
{

    cd $cdir/src;
    aprver=apr-1.5.2;
    apr_utilver=apr-util-1.5.4;
    echo "开始安装 "$aprver" ……";
    wget -c http://mirrors.ustc.edu.cn/apache/apr/$aprver.tar.gz;
    tar -zxvf $aprver.tar.gz
    cd $aprver;
    ./configure --prefix=/usr/local/$aprver;
    make && make install;
    checkOK;
    cd $cdir/src;
    echo "开始安装 "$apr_utilver" ……";
    wget -c http://mirrors.ustc.edu.cn/apache/apr/$apr_utilver.tar.gz;
    tar -zxvf $apr_utilver.tar.gz;
    cd $apr_utilver;
    ./configure --prefix=/usr/local/$aprver --with-apr=/usr/local/$aprver
    make && make install
    checkOK;
}

#安装Apache2.4
apache24in()
{
    ./configure\
        --prefix=/usr/local/apache\
        --sysconfdir=/etc/httpd\
        --enable-so\
        --enable-ssl\
        --enable-rewrite\
        --enable-cgi\
        --with-zlib\
        --with-pcre\
        --with-apr=/usr/local/$aprver/\
        --with-apr-util=/usr/local/$aprver/\
        --enable-modules=most\
        --enable-mpms-shared=all;
    make && make install;
    checkOK;
    sed -i -e 's#AddType application/x-gzip .gz .tgz#&\n    AddType application/x-httpd-php .php#g' /etc/httpd/httpd.conf;
    sed -i 's#DirectoryIndex index.html#& index.htm index.php#g' /etc/httpd/httpd.conf;
    sed -i 's#\#ServerName www.example.com:80#ServerName localhost:80#g' /etc/httpd/httpd.conf;
    if [[ $Astart = "yes" || $Astart = "y" || $Astart = "" ]]
    then
        apachecon;
    fi
}

#安装php
phpin()
{
    echo "安装 "$Psel;
    cd $cdir/src;
    wget -c http://cn2.php.net/distributions/$phpver.tar.gz;
    tar zxvf $phpver.tar.gz;
    cd $phpver;
    ./configure   --prefix=/usr/local/php\
                  --with-apxs2=/usr/local/apache/bin/apxs\
                  --with-config-file-path=/usr/local/php/etc\
                  --with-mysql=/usr/local/mysql   \
                  --with-libxml-dir\
                  --with-gd\
                  --with-jpeg-dir\
                  --with-png-dir\
                  --with-freetype-dir\
                  --with-iconv-dir\
                  --with-zlib-dir\
                  --with-bz2\
                  --with-openssl\
                  --with-mcrypt\
                  --enable-soap\
                  --enable-gd-native-ttf\
                  --enable-mbstring\
                  --enable-sockets\
                  --enable-exif\
                  --disable-ipv6 ;
    make && make install ;
    checkOK;
}

#完成安装
finishin()
{
    echo "进行安装完配置过程……";
    echo -e 'PATH=$PATH:/usr/local/mysql/bin:/usr/local/apache/bin\nexport PATH' >/etc/profile.d/path.sh;
    source /etc/profile.d/path.sh;
    echo -e '<?php\n    echo "php解析正常"; \n?>' > /usr/local/apache/htdocs/1.php;
    apachectl start;
    source /etc/profile.d/path.sh;
    netstat -lntp;
    source /etc/profile.d/path.sh;
    curl localhost/1.php;
    echo "";
    echo "安装LAMP成功！";
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
    yum install -y wget epel-release
    # 更换阿里云源
#    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup;
 #   wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo;
  #  yum clean all;
   # yum makecache;
    yum install -y kernel kernel-devel;
    yum install -y gcc make compat-libstdc++-33 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libpng libpng-devel freetype freetype-devel libcurl libcurl-devel libjpeg-turbo libjpeg-turbo-devel libmcrypt libmcrypt-devel;
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

debian_init()
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
    apt-get install -y build-essential gcc g++ make
    for packages in build-essential gcc g++ make cmake autoconf automake re2c wget cron bzip2 libzip-dev libc6-dev file rcconf flex vim bison m4 gawk less cpp binutils diffutils unzip tar bzip2 libbz2-dev libncurses5 libncurses5-dev libtool libevent-dev openssl libssl-dev zlibc libsasl2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev curl libcurl3 libcurl3-gnutls libcurl4-gnutls-dev libcurl4-openssl-dev libpq-dev libpq5 gettext libjpeg-dev libpng12-dev libxml2-dev libcap-dev ca-certificates debian-keyring debian-archive-keyring libc-client2007e-dev psmisc patch git libc-ares-dev
	do 
	    apt-get install -y $packages --force-yes; 
	done
	if [ $Asel = "Apache-2.4" ]
    then
        yum install -y pcre-devel;
        aprin;
    fi
}

#安装过程
LAMPinstall()
{
    versel;
    debian_init;
    mysqldl;
    apachedl;
    phpin;
    finishin;
}
LAMPinstall 2>&1 | tee $cdir/install.log;
