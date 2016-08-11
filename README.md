# WhiteLab 2.0
==============

WhiteLab 2.0 is a Ruby on Rails implementation of [WhiteLab](https://github.com/TiCCSoftware/WhiteLab), 
a web application for the search and exploration of large corpora with linguistic annotations.

Main changes in this version:
- Added support for multiple corpora;
- The Search page is set as the home page and the original Home page has been moved to Info;
- Admin interface to control contents of the Info page, interface translations, and available metadata;
- Added support for a Neo4J backend comprised of a [data importer](https://github.com/Taalmonsters/WhiteLab2.0-Importer) and [search plugin](https://github.com/Taalmonsters/WhiteLab2.0-Neo4J-Plugin) as an alternative to [BlackLab](https://github.com/INL/BlackLab);
- Added support for audio. Both the Neo4J and the BlackLab backends allow for playback of fragments matching query hits, and of entire files;
- Custom indexers have been created for BlackLab that are suited for importing corpora consisting of FoLiA files with or without phonetic transcriptions and audio time codes, with either CMDI or IMDI metadata files.
- The site tour has been replaced with easier to navigate page instructions.

Installation and configuration
==============================

Instructions on how to install and configure the WhiteLab 2.0 web application and all it's prerequisites can be found [here](docs/install/README.md).

Usage
=====

Instructions regarding the usage of WhiteLab 2.0 can be found [here](docs/usage/README.md).