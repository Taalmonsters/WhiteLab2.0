# Installation with the BlackLab backend
========================================

This guide explains step by step how to install WhiteLab 2.0 with the BlackLab backend. For information regarding corpus indexing with BlackLab we refer [here](http://inl.github.io/BlackLab/indexing-with-blacklab.html).

NB: Basic knowledge of Linux application and server management is assumed.

NB: Since the index may take up quite some resources, it is advised to run the WhiteLab 2.0 backend on its own dedicated server. 
The installation and configuration instructions provided assume that this is the case. The web application may be hosted on another
server, since it uses REST calls to communicate with the index.

Requirements
============

- BlackLab
- Tomcat 7
- Ruby
- Apache and Phusion Passenger
- MySQL
- WhiteLab 2.0 web application

BlackLab
========

Download the latest version of BlackLab from [here](http://inl.github.io/BlackLab/downloads.html).
After downloading, issue the following commands:

```
$ cd /path/to/BlackLab
$ mvn clean package install
```

This will create a directory labeled 'server' in your BlackLab folder, with a subdirectory 'target'. In it, there will be a file 'blacklab-server-[VERSION].war'. Copy this file to your Tomcat 7 webapps folder:

```
$ cp server/target/blacklab-server-[VERSION].war /path/to/tomcat/webapps/blacklab-server.war
```

Tomcat 7
========

If you have not yet installed Tomcat 7, you can download it from [here](http://tomcat.apache.org/download-70.cgi). Installation instructions can be found [here](https://tomcat.apache.org/tomcat-7.0-doc/setup.html).

Ruby
====

Before starting the Ruby installation, make sure your system software is up to date with the following commands:

```
$ sudo apt-get update
$ sudo apt-get upgrade
```

Next, install the following essentials:

```
$ sudo apt-get install build-essential libssl-dev libyaml-dev libreadline-dev openssl curl git-core zlib1g-dev bison libxml2-dev libxslt1-dev libcurl4-openssl-dev libgmp3-dev nodejs
```

Download the latest stable Ruby source code from [here](https://www.ruby-lang.org/en/downloads/) and unpack the archive. Go into the newly created directory and use the following commands to configure, make and install Ruby:

```
$ ./configure
$ make
$ sudo make install
```

After installation is complete, you may delete the Ruby archive and the directory where you unpacked it.

Apache and Phusion Passenger
============================

The Apache web server can be installed through standard package management on any Linux distribution. For instance, on Ubuntu it can be installed using the command:

```
$ sudo apt-get install apache2
```

In order to enable Apache to deploy Ruby on Rails applications, a recent version of Phusion Passenger needs to be installed as well. The following instructions explain how this is done on Ubuntu 14.04. Issue this command to add the Passenger repository key:

```
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
```

Next, create the file /etc/apt/sources.list.d/passenger.list and add the following line:

```
deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main
```

Change the permissions on the file:

```
$ sudo chown root: /etc/apt/sources.list.d/passenger.list
$ sudo chmod 600 /etc/apt/sources.list.d/passenger.list
```

Finally, use the following commands to install Passenger, enable the module and restart Apache:

```
$ sudo apt-get update
$ sudo apt-get install libapache2-mod-passenger
$ sudo a2enmod passenger
$ sudo service apache2 restart
```

NB: The Passenger installation may overwrite our custom Ruby installation. To solve this issue, remove the incorrect version and create a symlink to the correct one:

```
$ sudo rm /usr/bin/ruby
$ sudo ln -s /usr/local/bin/ruby /usr/bin/ruby
```

MySQL
=====

Install MySQL using the instructions on [this page](https://www.linode.com/docs/databases/mysql/how-to-install-mysql-on-ubuntu-14-04). It is used within the WhiteLab 2.0 web application to keep track of users and their queries.

WhiteLab 2.0 web application
============================

We are now ready to install the WhiteLab 2.0 web application. Download it from [here](https://github.com/Taalmonsters/WhiteLab2.0) and place it in /var/www/html. For convenience, you may rename the unpacked directory to, for instance, 'whitelab'.
Descend into the newly created whitelab directory and issue the following command:

```
$ bundle install
```

This will install rails and all Ruby gems that are required to run WhiteLab 2.0. The configuration for the application is located in config/application.rb. By default it is configured to use Neo4j as the backend:

```
config.x.database_type = 'neo4j'
config.x.database_url = 'http://localhost:7474/'
```

Change it to the following to use BlackLab instead:

```
config.x.database_type = 'blacklab'
config.x.database_url = 'http://localhost:8080/blacklab-server/corpusname/'
```

If one or more of your corpora include audio, create an environment variable titled WHITELAB_AUDIO_DIR which defines the absolute path to the directory where your audio files are located. This folder should include a subdirectory for each available audio format, with the document audio files located directly into the format subdirectory.

NB: Do NOT adjust the "config.x.total_token_count" property. This will be set by the application upon initialization.

Next issue the following command:

```
$ rake assets:precompile dp:drop db:create db:migrate RAILS_ENV=production
```

This will precompile all css, images and javascript files, and also create the MySQL database to store the user profiles and query results.

```
NB: Any "rake" commands will initialize the application in the background to check for errors. During first initialization the application will
retrieve lists of available metadata en documents from the index and stores them for use in the interface (i.e. to dynamically calculate filter coverage). If your index is of considerable size, this may take some time. Please do not interrupt the process.
```

If you are running WhiteLab 2.0 in production mode, you should generate a secret key base for the application using the following command:

```
$ rake secret
```

Store the resulting string in an environment variable named 'SECRET_KEY_BASE'.

Next, go into the directory /etc/apache2/sites-available and copy the default site configuration to a new file:

```
$ cp 000-default.conf whitelab.conf
```

Modify the whitelab.conf file to look like this (replace "yourdomain.com" with the domain of the server hosting WhiteLab):

```
<VirtualHost *:80>
	ServerName yourdomain.com
	ServerAdmin admin@yourdomain.com
	DocumentRoot /var/www/html/whitelab/public
	RailsEnv production
	LogLevel warn
	ErrorLog /var/log/apache2/error.log
	CustomLog /var/log/apache2/access.log combined
</VirtualHost>
```

Finally, enable the virtual host and restart Apache by issuing the following commands:

```
$ sudo a2ensite whitelab
$ sudo service apache2 restart
```

WhiteLab 2.0 is now available at http://yourdomain.com.

WhiteLab 2.0 includes an administration interface for the management of the interface and metadata. It requires a login.
Add the username and password you wish to use for this interface as environment variables respectively named 'WL2_ADMIN' and 'WL2_ADMIN_KEY'.
You may need to restart the application for the changes to take effect.
