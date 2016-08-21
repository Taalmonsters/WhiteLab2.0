# Installation with the Neo4J backend
=====================================

This guide explains step by step how to install WhiteLab 2.0 with the Neo4j backend and how to index corpora using the WhiteLab 2.0 Importer.

NB: Basic knowledge of Linux application and server management is assumed.

NB: Since the index may take up quite some resources, it is advised to run the WhiteLab 2.0 backend on its own dedicated server. 
The installation and configuration instructions provided assume that this is the case. The web application may be hosted on another
server, since it uses REST calls to communicate with the index.

Requirements
============

- Neo4j
- WhiteLab 2.0 Neo4j Plugin
- WhiteLab 2.0 Importer
- Ruby
- Apache and Phusion Passenger
- MySQL
- WhiteLab 2.0 web application

Neo4j
=====

Download [Neo4j](http://neo4j.com/download/). Two editions are available: Community and Enterprise. Please consult the licenses to determine which edition to download. 
WhiteLab 2.0 works with both editions and has been tested with versions 2.3.0 up to 3.0.0.

Unpack Neo4j in the folder where you want to have it installed. The file conf/neo4j-wrapper.conf contains the parameters for the JVM. Be sure to set the available heap
size to a value that suits your server and index size by uncommenting and adjusting the following lines:

wrapper.java.initmemory=512
wrapper.java.maxmemory=512

If you plan to index and disclose large corpora in WhiteLab 2.0, then it is advised to set this value to about 50% of your total available RAM minus 2-4 Gb for OS operations.
Besides heap space, the size of Neo4j’s cache also needs to be configured according to your server’s specifications. Open the file neo4j.properties and uncomment the following line:

dbms.pagecache.memory=10g

Adjust the value to your desired cache size. For use with large corpora it is advised to set the cache size to about 75% of the maximum heap space.
If you are using Neo4j Enterprise version 2.X, please make sure to add or uncomment the following line in conf/neo4j.properties to enable the High Performance Cache:

cache-type=hpc
	
See [this page](http://neo4j.com/docs/stable/performance-guide.html) for further information regarding Neo4j's configuration.

WhiteLab 2.0 Neo4j Plugin
=========================

Download the [plugin](https://github.com/Taalmonsters/WhiteLab2.0-Neo4j-Plugin). Unpack it and move into the unpacked directory. Use the command 'mvn clean package' to create the plugin jar-file in the target directory.

```
NB: Please make sure that the Neo4j version defined in pom.xml is the same as the version of your Neo4j installation.
```

Two jars will be created: whitelab-neo4j-extension-1.0.jar and whitelab-neo4j-extension-1.0-jar-with-dependencies.jar. Move the version whitelab-neo4j-extension-1.0-jar-with-dependencies.jar to the plugins folder of your Neo4j installation directory.
Next, open and edit the file conf/neo4j-server.properties. First, change the location of the database to the full path of the directory where you plan to store your database:

```
org.neo4j.server.database.location=/path/to/whitelab.db
```

Note that whitelab.db is a folder, not a file, and should be created before you start the Neo4j server. Add the following line to the end of the file to enable the WhiteLab 2.0 plugin on your server:

```
org.neo4j.server.thirdparty_jaxrs_classes=nl.whitelab.neo4j.admin=/whitelab/admin,nl.whitelab.neo4j.search=/whitelab/search,nl.whitelab.neo4j.explore=/whitelab/explore
```

Lastly, enable security on the Neo4j server by uncommenting the following line:

```
org.neo4j.server.webserver.https.enabled=true
```

Congratulations! You have now setup Neo4j for use with WhiteLab 2.0. To start the server and check if everything is correctly installed, you can run the following command from the Neo4j base directory (‘$’ represents the terminal console and is not part of the command):

```
$ ./bin/neo4j start
```

If you see the message "WARNING: Max 1024 open files allowed, minimum of 40 000 recommended. See the Neo4j manual." when starting Neo4j, then add the following lines to /etc/security/limits.conf (replace ‘user’ with the username of the user running Neo4j):

```
user   soft    nofile  40000
user   hard    nofile  100000
```

and uncomment this line in /etc/pam.d/su:

```
session    required   pam_limits.so
```

and reboot the server.

After the server has been started, you can access the database by pointing your web browser to http://localhost:7474. When first opening this interface, it will prompt you for a username and password. The defaults are neo4j/neo4j and after login you will be asked to choose a new password.
When you have set your Neo4j password, be sure to store the username and password in environment variables titled NEO4J_USER and NEO4J_PW and make them available to the system (add them to your bash profile).
Of course, the database folder is empty, no data is present in the database at this time. For now, stop the server using:

```
$ ./bin/neo4j stop
```

WhiteLab 2.0 Importer
=====================

To create an index that is compatible with WhiteLab 2.0, downlad the [WhiteLab 2.0 Importer](https://github.com/Taalmonsters/WhiteLab2.0-Importer). Unpack the archive, descend into the create folder and run 'mvn clean package'. This creates a file 'whitelab-neo4j-importer-1.0-jar-with-dependencies.jar' in the target subdirectory.

```
NB: Please make sure that the Neo4j version defined in pom.xml is the same as the version of your Neo4j installation.
```

The importer can index multiple corpora at once. Make sure your input directory has the following structure and files:

```
input_dir
+-- corpus1
	+-- indexer.properties
	+-- input
		+-- collection1.tar.gz
		+-- collection2.tar.gz
	+-- metadata
		+-- indexmetadata.json
		+-- corpus1_metadata.zip
```

The collection archives should contain the corpus documents in [FoLiA](https://proycon.github.io/folia/) format. The metadata archive should contain 1 metadata file per corpus document, which can be in either CMDI or IMDI format.
The indexer.properties file looks something like this:

```
title=corpus_title
displayName=Corpus Display Name
textFormat=folia
contentParserClass=FoLiAParser
metadataParserClass=CGNIMDIParser 			# options: CGNIMDIParser or SoNaRCMDIParser
metadataFormat=imdi 						# options: imdi or cmdi
metadataExtension=imdi # the actual extension of the metadata files in the archive
audioFormat=mp3,wav 						# comma-separated list of available audio formats, if any
audioWebFormat=mp3							# audio format used for playback in the browser
audioExportFormat=wav						# audio format used for export
metadataZipFile=metadata/CGN-metadata.zip	# relative location of the metadata archive
metadataPathInZip=sessions					# the base path under which all documents are found in the metadata archive
```

The indexmetadata.json file is optional. If you have an existing BlackLab index with an indexmetadata.json file, then you can use that file.

To run the Importer, use the following command:

```
$ java -jar whitelab-neo4j-importer-1.0-jar-with-dependencies.jar /path/to/input/directory /path/to/whitelab.db create -c true
```

If necessary, you can set the heap size using "java -Xms10G -Xmx10G" and adjust the values to your needs.

This process may take a long time to complete, because it will have to pass over every consecutive token/field in the corpus and metadata. This process can't be threaded because of writing restrictions on the index.
The indexing of the entire SoNaR-500 and CGN corpora combined takes approximately 18 hours.
The "-c true" flag tells the Importer to count the tokens per class (corpus, collection, document, and annotations) after indexing and store the values for easy retrieval by WhiteLab 2.0.

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

In order to enable Apache to deploy Ruby on Rails applications, Phusion Passenger needs to be installed as well. The following instructions explain how this is done on Ubuntu 14.04. Issue this command to add the Passenger repository key:

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

We are now ready to install the WhiteLab 2.0 web application. Download it from [here](https://github.com/Taalmonsters/WhiteLab2.0) and unpack it in /var/www/html. For convenience, you may rename the unpacked directory to, for instance, 'whitelab'.
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

If you wish to use BlackLab and BlackLab Server instead, use:

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

WhiteLab 2.0 includes functionality for creating cron jobs that check and clean the database at regular intervals. To use them issue the following command from the WhiteLab 2.0 root directory:

```
$ whenever -w
```

This will write the job schedule defined in config/schedule.rb to your crontab file.

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