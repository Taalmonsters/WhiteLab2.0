# Installation with the BlackLab backend
========================================

This guide explains step by step how to install WhiteLab 2.0 with the BlackLab backend. For information regarding corpus indexing with BlackLab we refer [here](http://inl.github.io/BlackLab/indexing-with-blacklab.html).

NB: Basic knowledge of Linux application and server management is assumed.

NB: Since the index may take up quite some resources, it is advised to run the WhiteLab 2.0 backend on its own dedicated server. 
The installation and configuration instructions provided assume that this is the case. The web application may be hosted on another
server, since it uses REST calls to communicate with the index.

Requirements
============

- Tomcat 7
- BlackLab
- Ruby
- Apache and Phusion Passenger
- MySQL
- WhiteLab 2.0 web application

Tomcat 7
========

If you have not yet installed Tomcat 7, you can download it from [here](http://tomcat.apache.org/download-70.cgi). Installation instructions can be found [here](https://tomcat.apache.org/tomcat-7.0-doc/setup.html).

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

The application currently may not work correctly with Ruby 2.3 or above. Download the Ruby source code for version 2.2.7 [here](https://www.ruby-lang.org/en/downloads/) and unpack the archive. Go into the newly created directory and use the following commands to configure, make and install Ruby:

```
$ ./configure
$ make
$ sudo make install
```

After installation is complete, you may delete the Ruby archive and the directory where you unpacked it.

If you prefer, you can also use [rvm](https://rvm.io/), the Ruby Version Manager to install Ruby 2.2.7.

In either case, be careful that there are no conflicts with any pre-existing ruby installation (e.g. see the note about Passenger Phusion below).

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
Descend into the newly created whitelab directory and issue the following commands:

```
$ gem install bundler
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
$ rake assets:precompile db:drop db:create db:migrate RAILS_ENV=production
```

This will precompile all css, images and javascript files, and also create the MySQL database to store the user profiles and query results.

```
NB: Any "rake" commands will initialize the application in the background to check for errors. During first initialization the application will
retrieve lists of available metadata en documents from the index and stores them for use in the interface (i.e. to dynamically calculate filter coverage). If your index is of considerable size, this may take some time. Please do not interrupt the process.
```

In certain cases, running the above command may generate an error message. Here's an overview of some error messages and possible causes:

```
undefined method `keys' for nil:NilClass
/vol1/redirect-sites/opensonar/whitelab/app/helpers/blacklab_helper.rb:393
```

This might indicate that your corpus does not have a metadata field with the name "Corpus_title". To correct this, when indexing your corpus, either place a setting "meta-Corpus_title=mycorpusname" in a file called indexer.properties in the current directory, or pass an option "---meta-Corpus_title mycorpusname" (note the 3 dashes!) to the IndexTool. See [Indexing with BlackLab](http://inl.github.io/BlackLab/indexing-with-blacklab.html) for more information.

```
undefined method `[]' for nil:NilClass
/vol1/redirect-sites/opensonar/whitelab/app/helpers/blacklab_helper.rb:630
```

This might indicate that BlackLab Server could not be reached. Please check that the BlackLab Server WAR is in the correct place and Tomcat has deployed it. It might be helpful to try accessing BlackLab Server directly through the browser, e.g. http://yourhostname:8080/blacklab-server/.

```
ERROR: Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock'
```

This might indicate that the MySQL socket file is in a different place on your flavour of Linux. Locate the socket file (e.g. on CentOS, it's in /var/lib/mysql/mysql.sock) and edit the file config/database.yml with the correct path.

```
ERROR: cannot load such file -- bundler/setup
```

This might indicate that Passenger Phusion is using the wrong version of Ruby. To indicate the correct version of Ruby Passenger should use, edit the passenger.conf file in the Apache conf.d directory (e.g. /etc/httpd/conf.d/passenger.conf) and change the PassengerRuby setting to the correct ruby binary. If you used rvm on CentOS to install Ruby 2.2.7, that would be:

```
PassengerRuby /usr/local/rvm/gems/ruby-2.2.7/wrappers/ruby
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
