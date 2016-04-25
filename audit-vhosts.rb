#!/usr/bin/ruby
# audit-vhosts.rb
# Author: ianlshaw

# Concurrent dns queries with: Resolv, this will need some thinking
# I don't think it runs on 1.8.7........... rvm hmmmmmmmmmmm

# Captures null responses from dig as errors, they return a 0 but
# a response with length of 0 should be considered an error.

require 'rubygems'
require 'open-uri'
require 'colorize'

VHOSTDIR = '/etc/httpd/virtualhosts/'
BREAK = '----------'

# Default the error int
@errors = 0

# Default the successes int
@successes = 0

# Default the error list array
@error_list = []

# Default the success list array
@success_list = []

# Default the defunkt vhosts array
@defunkt_vhosts = []

# Default the required vhsosts array
@required_vhosts = []

# Default the per_vhost_errors int
@per_vhost_errors = 0

def find_vhosts
  puts 'Finding vhosts.'

  # Create an array of filenames from the vhost directory but
  # reject the up and up up directory constructs, since they will bomb out.
  @vhost_names = Dir.entries(VHOSTDIR).reject { |entry| entry == '.' || entry == '..' }

  # Provide a count of elements in the Array.
  @count = @vhost_names.length
end

def grab_urls
  puts 'Grabbing urls'

  # For every vhost found...
  @vhost_names.each do |vhost|
    # Create an absolute filepath
    filename = VHOSTDIR + vhost

    # Then read the contents of the file into a variable.
    file = IO.read(filename)

    # Grab out the lines we care about, the ones
    # containing urls which are listened on.
    servernames = file.grep(/ServerName/)
    serveraliases = file.grep(/ServerAlias/)

    # Count how many aliases contain asterixes,
    # they'll be removed from the array, but we need the count.
    asterixes = serveraliases.grep(/\*/)
    asterix_count = asterixes.length

    # Count up the aliases, useful info...
    aliascount = serveraliases.length

    # Grab only the url of the ServerName, noone cares about the directive.
    prettyname = servernames.to_s.split.last

    # Inform le user.
    puts vhost.blue
    puts 'ServerName'.yellow
    puts prettyname
    puts vhost + " has #{aliascount} aliases."
    puts asterix_count.to_s + ' removed due to asterisk bullshit.'
    puts 'ServerAliases'.yellow

    # Firstly, we check the ServerName.
    test_url(prettyname)

    # Sanitize the array by removing any lines containing an asterix.
    aliases_minus_asterix = serveraliases.reject { |s| /\*/ =~ s }

    # Loop through the alias array.
    aliases_minus_asterix.each do |line|
      # Truncate the directive.
      singlealias = line.split.last
      puts singlealias

      # Next we check each alias, one by one.
      test_url(singlealias)
    end

    # If the amount of errors in this vhost is equal to the amout of aliases...
    # + 1 because of ServerName
    if @per_vhost_errors == aliases_minus_asterix.length + 1

      # Add the vhost as a string to the defunkt_vhosts array
      @defunkt_vhosts.push(vhost)
    else

      # Otherwise, we assume that at least one alias resolved correctly
      # and therefore add the vhost to the required_vhosts array
      @required_vhosts.push(vhost)
    end

    # While we test
    puts 'vhost error count '.red + @per_vhost_errors.to_s

    # Reset the local error count.
    @per_vhost_errors = 0

    # Formatting shit.
    puts BREAK
    puts
  end
end

# Ascertain the public IP of the machine on which
# the script is run. This allows it to be node-agnostic.
def find_public_ip
  @public_ip = open('http://whatismyip.akamai.com').read
end

# Finally, we get to shell out.
def test_url(url)
  # Attempt to resolve the name or alias.
  # Query external nameserver, on non-default port (Thanks RackSpace!)
  raw_output = `dig @208.67.222.222 +short -p 5353 #{url}`

  if $?.success?
    # Truncate all but the last line.
    parsed_output = raw_output.split.last
    puts "Resolves to #{parsed_output}"

    # Check against public ip.
    if parsed_output != @public_ip
      puts 'Which resolves elsewhere!'.red

      # Increment the error count.
      @errors += 1

      # Increment the per_vhost_errors count
      @per_vhost_errors += 1

      # Add the url to the array of errors.
      @error_list.push(url)
    else
      puts 'Which resolves here.'.green

      # Increment the success count
      @successes += 1

      # Add the url to the array of successes.
      @success_list.push(url)
    end

  else
    # Bomb
    puts "Dig faulted on: #{url} investigate."
    exit(1)
  end
end

def outro
  # Informed user, yay!
  puts 'Failures: '.red
  puts BREAK.red
  puts @error_list
  puts BREAK.red
  puts 'Successes: '.green
  puts BREAK.green
  puts @success_list
  puts BREAK.green
  puts
  puts 'Defunkt vhosts:'.red
  puts BREAK.red
  puts @defunkt_vhosts
  puts BREAK.red
  puts
  puts 'Required vhosts:'.green
  puts BREAK.green
  puts @required_vhosts
  puts BREAK.green
  puts
  puts BREAK.light_blue
  puts "Total vhosts: #{@count}".light_blue
  puts "Total errors: #{@errors}".red
  puts "Total successes: #{@successes}".green
  puts "Defunkt vhosts: #{@defunkt_vhosts.length}".red
  puts "Required vhosts: #{@required_vhosts.length}".green
  puts BREAK.light_blue
end

find_public_ip
find_vhosts
grab_urls
outro
