# audit-vhosts

### Usage

##### `ruby audit-vhosts.rb`

### What does it do?

##### Goes through the `/etc/httpd/virtualhosts` directory, rips out ServerName and ServerAlias directives. Then attempts to resolve those urls via an external nameserver. Thereby evaluating whether or not the system on which this tool is run, is indeed the live host of the url in question. 

##### From that information the tool will then inform the user of the following details:
* Total virtualhosts
* Total errors 
* Total successes
* Defunkt virtualhosts
* Required virtualhosts

##### It will also spit out output to that end, allowing detailed analysis of superfluous aliases and defunkt virtualhosts
