# ISE2 Data Importer

This repository contains a collection of scripts to convert data from the Internet Shakespeare Editions version 2 into TEI for use with ISE3. In many cases, the conversion will be rather rough and the output will require editing by a human before use.

## Usage

All scripts can be run with (Ant)[https://ant.apache.org/], using the build.xml file in this directory.

* Run `ant -p` for a list of available scripts.
* Run `ant -lib lib/ <target>` to run a particular script, or `ant -lib lib/` to convert everything.

ISE2 data to be processed must be added into the "ise2" folder, organized similarly to the (ISE eXist app's content folder)[http://internetshakespeare.uvic.ca/exist/rest/db/apps/iseapp/content/]. **ISE2 data is not covered under the license for this code, and requires permission from the copyright holders to modify and redistribute.** Sample data from The Merchant of Venice is provided in this repository under a (Creative Commons BY-NC-SA license)[https://creativecommons.org/licenses/by-nc-sa/4.0/] courtesy of Janelle Jenstad.

The "ise3" folder must minimally contain orgography.xml and personography.xml TEI files. The scripts will fail if they cannot find org/person entries in these files corresponding to ISE2 users mentioned in the metadata. Additionally, taxonomies.xml will be used for ISE2 resp and work ID equivalencies, and the scripts may fail and/or produce invalid TEI output if it is not avaialable. Bibliography entries will only be generated if a skeleton bibliography.xml TEI file exists. Sample data for each of these documents is provided in this repository.

Output will be validated against the ODD/RelaxNG/Schematron provided in the "sch" folder, if provided.

## Dependancies

* OpenSP, specifically osx (http://openjade.sourceforge.net/doc/)
* Ant-Contrib (http://ant-contrib.sourceforge.net)
* isetools (included) (https://github.com/internetshakespeare/isetools)
* SaxonHE 9.8 (included) (http://www.saxonica.com)
* Jing (included) (https://github.com/relaxng/jing-trang)
