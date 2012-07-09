# cherry pick script
#
# GOAL: * interactively add a rebase, and individual commits that the user intends to fold in.

require_relative './lib/kriek'
require 'readline'

k = Kriek.new
puts "Prost!                                                      (Type '?' for help.)"

loop do
  #print "> "
  input = Readline::readline('> ')
  Readline::HISTORY.push(input)
  #input = gets; input.chomp!
  input.split(';').each do |inp|
    case #inp
    when inp =~ /^\s*SET +DEBUG +(ON|OFF)\s*$/i                         # SET DEBUG
      k.debug = ($1 =~ /on/i ? true : false)
    when inp =~ /^\s*SET +KATTS +((katts-)?\d+)\s*$/i                     # SET KITT
      kitt = $1
      kitt = kitt =~ /katts-(\d+)/i ? $1 : kitt
      print "Setting KATTS to KATTS-#{kitt}..."
      k.kitt = "KATTS-#{kitt}"
      puts " done."


    when inp =~ /^\s*SET +REL +((3.0-)?\d+)\s*$/i                       # SET REL
      rel = $1
      rel = rel =~ /3.0-(\d+)/i ? $1 : rel
      print "Setting rel to 3.0-#{rel}..."
      k.release_number = "3.0-#{rel}"
      puts " done."

    when inp =~ /^\s*(MENU|H(el?|elp)?|\?)\s*$/i                        # MENU | Help | ?
      puts k.menu

    when inp =~ /^\s*A(dd?)? +R(an?|ange?)? +(\d+:\d+)\s*$/i            # Add Range
      puts "Adding range: #{$3}..."
      k.add_range $3

    when inp =~ /^\s*A(dd?)? +C(om?|ommi?|ommit)? +([0-9 ]+)\s*$/i      # Add Commit
      $3.split(/ +/).each do |c|
        print "Adding commit: #{c}..."
        result = k.add_commit c
        if result.is_a? String
          print " done. "
          puts result
        else
          puts result ? " done." : "\nError: #{c} is already in the merge list."
        end
      end

    when inp =~ /^\s*A(dd?)? +LIQ(ui?|uiba?|uibase?)? +([0-9 ]+)\s*$/i  # Add LIQuibase
      rev = $3
      print "Adding liquibase changeset from #{rev}..."
      result = k.add_liquibase rev
      print result
      puts result =~ /Error/i ? "" : " done." 

    when inp =~ /^\s*REM(ov?|ove)? +R(an?|ange?)? +(\d+:\d+)\s*$/i      # REMove Range
      print "Removing range: #{$3}..."
      result = k.remove_range $3
      puts result ? " removed." : "\nError: #{$3} was not found!"

    when inp =~ /^\s*REM(ov?|ove)? +C(om?|ommi?|ommit)? +(\d+)\s*$/i    # REMove Commit
      print "Removing commit: #{$3}..."
      result = k.remove_commit $3
      puts result ? " removed." : "\nError: #{$3} was not found!"

    when inp =~ /^\s*SVN +I(nf?|nfo)?\s*$/i                             # SVN Info
      puts "Printing svn info..."
      puts k.svn_info

    when inp =~ /^\s*SVN +L(og?)?( +-v)?\s*$/i                          # SVN Log
      puts "Printing svn log..."
      puts k.svn_log $2

    when inp =~ /^\s*FIND +FILEs?\s*$/i                                 # FIND FILEs
      puts "Finding associated files..."
      puts k.files.sort_by {|e| e[:fname]}.map { |e| e[:fname] }

    when inp =~ /^\s*FIND +JIRAs?\s*$/i                                 # FIND JIRAs
      puts "Finding associated JIRAs..."
      puts k.jiras.inspect

    when inp =~ /^\s*FIND +LIQ(ui?|uiba?|uibase?)?\s*$/i                # FIND LIQuibase
      print "Finding liquibase changesets..."
      liquibase_changesets = k.liquibase_changesets
      puts liquibase_changesets.empty? ? " none." : ""
      liquibase_changesets.each { |l| puts "  "+l }

    when inp =~ /^\s*FIND +WORKF(lo?|low)?\s*$/i                        # FIND WORKFlow
      print "Finding workflow changes..."
      workflow_changes = k.workflow_changes
      puts workflow_changes.empty? ? " none." : ""
      workflow_changes.each { |r,workflows| workflows.each { |w| puts "  rev #{r}: #{w}" } }

    when inp =~ /^\s*PREV(ie?|iew)?\s*$/i                               # PREView
      puts "Previewing svn commands..."
      puts k.preview

    when inp =~ /^\s*RUN\s*$/i                                          # RUN
      puts "Running svn commands..."
      puts k.run!

    when inp =~ /^\s*Q(ui?|uit)?\s*$/i                                  # Quit
      puts "Quitting..."
      exit

    else
      puts "I did not understand that command. Maybe too many krieks..."

    end
  end
end
