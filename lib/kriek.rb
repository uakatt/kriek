# WHAT the WHAAAT: cherry pick script
#
# GOAL:            * interactively add a rebase, and individual commits that the user intends to fold in.
#                  * pre-confirm list of commits
#
# TODO: SVN Info, SVN Log, WORKFlow, FIND JIRAs only work on @commits
# TODO: Implement liquibase copies
# TODO: Implement CHERRYPICK RELEASE NUMBER

require File.join(File.dirname(__FILE__), 'array')

class Kriek
  SVN_URL             = "https://subversion.uits.arizona.edu/kitt/kitt/financial-system"
  SVN_COMMIT_URL      = "https://subversion.uits.arizona.edu/kitt/kitt/financial-system/kfs/trunk"
  SVN_DB_BRANCHES_URL = "https://subversion.uits.arizona.edu/kitt/kitt/financial-system/kfs-cfg-dbs/branches"
  SVN_DB_UPDATE_URL   = "https://subversion.uits.arizona.edu/kitt/kitt/financial-system/kfs-cfg-dbs/branches/release/update"
  JIRA_PATTERN = "\(?:KFSI\|KITT\)-\(?:\\d\+\)" # alternative to escaping every regex operatoris escaping later...
  attr_accessor :commits, :ranges, :kitt, :release_number, :debug

  def initialize
    @commits = []
    @ranges = []
    @liquibase_changesets = []
  end

  def menu
    m = ""
    m << "Kriek. KITT: #{@kitt || '<undefined>'}; Release Number: #{@release_number || '<undefined>'}\n"
    m << "SET DEBUG ON|OFF             Set debug mode on or off\n"
    m << "SET KITT <kitt>              Set the KITT number for releasing this cherry-pick\n"
    m << "SET REL <rel>                Set the release number for this cherry-pick\n"
    m << "Add Range <from>:<to>        Merge a range of  svn revisions (currently I have: #{rowize(@ranges, 96, 80, 57)})\n"
    m << "Add Commit <revision> [...]  Merge one or more svn revisions (currently I have: #{rowize(@commits, 96, 80, 57)})\n"
    m << "Add LIQuibase <revision>     Copy a liquibase changeset to kfs-cfg-dbs/branches/release\n"
    if not @liquibase_changesets.empty?
      m << "                                    (currently I have: [#{@liquibase_changesets.map{ |lc| lc[:commit]+" contains "+lc[:name] }.join("\n                                                        ") }])\n"
    end
    m << "REMove Range <from>:<to>     Remove a  range  of svn revisions from the above merge list\n"
    m << "REMove Commit <revision>     Remove an individual svn revision from the above merge list\n"
    m << "SVN Info                     Print `svn info' results for current individual revisions\n"
    m << "SVN Log [-v]                 Print `svn log'  results for current individual revisions\n"
    m << "FIND FILEs                   Print any associated files for current individual revisions\n"
    m << "FIND JIRAs                   Print any associated Jiras for current individual revisions\n"
    m << "FIND LIQuibase               Print any liquibase changesets found in current individual revisions\n"
    m << "FIND WORKFlow                Print any workflow changes found in current individual revisions\n"
    m << "PREView                      Preview the svn commands to run\n"
    m << "RUN                          Run the svn commands NOW\n"
    m << "Quit                         Quit kriek without executing any svn merges or copies.\n"
  end

  def add_commit(c)
    if @commits.include? c
      return false
    end
    @commits << c
    return true if @commits.sorted?

    @commits.sort!
    return "(Commits were not sorted. So I sorted them. You're welcome.)"
  end

  def add_range(r)
    @ranges << r
  end

  # This is a goofy one. To add a liquibase changeset that was committed in revision c,
  # we must go find the build branch that held onto that liquibase changeset. In order to
  # find that build branch, we walk through the revisions starting with c, looking for a
  # commit message indicating a new build is released. There are actually a ton of these.
  # Here is an example:
  #
  #   r17312    AUTO: Updating data.xml install.xml update.xml. Adding keywords
  #   r17313    Auto: Updating version
  #   r17314    Auto: setting externals for kfs 3.0-742
  #   r17315-17 Auto: releasing financial-system/deployment/ 3.0-742
  #   r17318-20 Auto: releasing financial-system/conversion-scripts/ 3.0-742
  #   r17321-26 Auto: releasing financial-system/kfs-cfg-dbs/ 3.0-742
  #   r17327-29 Auto: releasing financial-system/kfs/ 3.0-742
  #   r17330    AUTO: Clearing update.xml from kfs-cfg-dbs
  #
  # In the interest of not pinging Subversion for 19 revisions, I am only going to ping
  # until I find Auto: setting externals for kfs 3.0-742
  def add_liquibase(c)
    log = svn_log_rev(c, "-v")
    if log =~ /^   . \/financial-system\/kfs-cfg-dbs\/trunk\/update\/(.+.xml)$/
      name = $1
    else
      return "KRIEK ERROR: no liquibase changesets found in revision #{c}"
    end

    build = nil
    commit = c.to_i

    while commit < c.to_i + 200
      log = svn_log_rev(commit.to_s, "-v")
      if log =~ /Auto.*(setting externals|releasing).*3.0-(\d+)/i
        build = $2
        break
      end
      commit += 4  # I could increment by 1, but this moves faster and will still hit one
    end            # of the revisions, like in the example above.

    if build.nil?
      return "KRIEK ERROR: could not find the build following revision #{c}..."
    end

    #puts "Found the build that follows #{c} at #{commit}; it is 3.0-#{build}"
    lc_jiras = jiras_rev(c).join(" ")
    changeset = {:name => name, :commit => c, :build => build, :jiras => lc_jiras}
    @liquibase_changesets << changeset
    return " found #{name} for #{lc_jiras}, preserved in build 3.0-#{build}..."
  end

  def be_considerate(this_sleep = 30)
    (1..(this_sleep/5)).each do
      print "."
      sleep 5
    end
    puts ""
  end

  def rowize(ary, max_width=80, first_row_len=0, left_margin=0)
    ary = ary.dup
    puts ary.inspect
    return "[]" if ary.empty?
    s = "["
    while ary.first && (s + ary.first + " ").length < (max_width - first_row_len - 1) # -1 for the '['
      s << ary.shift + " "
    end
    s << "\n"
    until ary.empty?
      line = " "*left_margin
      while !ary.empty? and (line + ary.first + " ").length < (max_width - 1) # -1 for the '['
        line << ary.shift + " "
      end
      line << "\n" unless ary.empty?
      s << line
    end
    s << "]"
  end

  def preview
    s = ""
    @ranges.each do |r|
      s << "    svn merge -r #{r} #{SVN_COMMIT_URL}\n"
    end
    @commits.each do |c|
      s << "    svn merge -c #{c} #{SVN_COMMIT_URL}\n"
    end
    @liquibase_changesets.each do |lc|
      message = "#{@kitt || '<missing cherry-pick kitt>'} #{lc[:jiras]} Grabbing changelog for rel-#{@release_number || '<missing release number>'}"
      s << "    svn cp -m \"#{message}\" #{SVN_DB_BRANCHES_URL}/3.0-#{lc[:build]}/update/#{lc[:name]} #{SVN_DB_UPDATE_URL}"
    end
    s
  end

  def remove_commit(c)
    @commits.delete c
  end

  def remove_range(r)
    @ranges.delete r
  end

  def run!
    s = ""
    @ranges.each do |r|
      #breather = 25
      #attempts = 5
      #command = "svn merge -r #{r} #{SVN_COMMIT_URL} 2>&1"
      #while attempts > 0
      #  puts "Executing: #{command} ..."
      #  svn_success = system command
      #  break if svn_success
      #  print "Gah! svn is not my friend. Trying again in #{breather += 5} seconds"
      #  attempts -= 1
      #  be_considerate(breather)
      #end
      #unless svn_success
      #  puts "Error! Could not execute: #{command}"
      #  puts "Cancelling the rest of the merges in this Run."
      #  return false
      #end

      r =~ /(\d+):(\d+)/
      r1 = $1.to_i; r2 = $2.to_i
      puts "Attempting to merge revisions #{r1} through #{r2}: #{r2-r1 +1} revisions..."
      result = run_merge("#{r1}:#{r2}")
      if result == false
        r_ary = [[r1,r2]]
        until r_ary.empty?
          sleep 1
          if result == true
            puts "Success at #{r_ary[0].inspect}!"
            r_ary.shift
            break if r_ary.empty?
          else
            r1, r2 = r_ary[0]
            if r2-r1 < 10
              puts "Attempting to merge revisions #{r1} through #{r2} didn't go so well."
              puts "And they are less than 10 revisions apart. So we're done here. Aborting."
              return false
            end
            puts "Attempting to merge revisions #{r1} through #{r2} didn't go so well. Cutting in half..."
            big = r_ary.shift
            small1 = [ big[0],              (big[0]+big[1])/2]
            small2 = [(big[0]+big[1])/2 +1,  big[1]          ]
            r_ary.unshift(small1, small2)
            puts "r_ary: #{r_ary.inspect}"
          end

          r1, r2 = r_ary[0]
          result = run_merge("#{r1}:#{r2}")
        end
      end
    end
    @commits.each do |c|
      breather = 25
      attempts = 5
      command = "svn merge -c #{c} #{SVN_COMMIT_URL} 2>&1"
      while attempts > 0
        puts "Executing: #{command} ..."
        svn_success = system command
        break if svn_success
        print "Gah! svn is not my friend. Trying again in #{breather += 5} seconds"
        attempts -= 1
        be_considerate(breather)
      end
    end
    #copies?
    s
  end

  def run_merge(r)
    # MOCKING
    #r =~ /(\d+):(\d+)/
    #r1 = $1.to_i; r2 = $2.to_i
    #return mock_run_merge(r2-r1 +1)

    breather = 25
    attempts = 3
    svn_success = false
    command = "svn marge -r #{r} #{SVN_COMMIT_URL} 2>&1"
    while attempts > 0
      puts "Executing #{command} ..."
      svn_success = system command
      break if svn_success
      print "Gah! svn is not my friend. Trying again in #{breather += 5} seconds"
      attempts -= 1
      be_considerate(breather)
    end
    unless svn_success
      puts "Error! Could not execute: #{command}"
      puts "Cancelling the rest of the merges in this run."
      return false
    end
    return true
  end

  def mock_run_merge(r, guarantee=200.0)
    a = guarantee/r
    b = rand
    puts "MOCKING #{r}: #{a} >? #{b}"
    return a > b
  end

  def svn_backticks(stuff, attempts=5, breather=25)
    while attempts > 0
      stdout = `svn #{stuff} 2>&1`
      return stdout unless stdout =~ /truncated/
      print "Gah! svn is not my friend. Trying again in #{breather += 5} seconds"
      attempts -= 1
      be_considerate(breather)
    end
    return false
  end

  def svn_system(stuff, attempts=5, breather=25)
    while attempts > 0
      puts "Executing: svn #{stuff} 2>&1 ..."
      svn_success = system("svn #{stuff} 2>&1")
      break unless svn_success
      print "Gah! svn is not my friend. Trying again in #{breather += 5} seconds"
      attempts -= 1
      be_considerate(breather)
    end
  end

  def svn_info
    s = ""
    @commits.each do |c|
      stdout = svn_backticks "info #{SVN_URL}@#{c}"
      if stdout
        s << stdout
      else
        s << "KRIEK ERROR: svn info failed 5 times. So sorry."
      end
    end
    s
  end

  def svn_log(opts = "")
    s = ""
    @ranges.each do |range|
      range =~ /(\d+):(\d+)/
      r1 = $1.to_i
      r2 = $2.to_i
      #print "(" if @debug
      #(r1..r2).each do |rev|
      #  print "#{rev} " if @debug
        stdout = svn_backticks "log -r #{range} #{opts} #{SVN_URL}"
        if stdout
          s << stdout
        else
          s << "KRIEK ERROR: svn log failed 5 times. So sorry."
        end
      #end
      puts ")" if @debug
    end

    @commits.each do |c|
      stdout = svn_backticks "log -r #{c} #{opts} #{SVN_URL}"
      if stdout
        s << stdout
      else
        s << "KRIEK ERROR: svn log failed 5 times. So sorry."
      end
    end
    s
  end

  def svn_log_rev(c, opts = "")
    stdout = svn_backticks "log -r #{c} #{opts} #{SVN_URL}"
    if stdout
      return stdout
    else
      return "KRIEK ERROR: svn log failed 5 times. So sorry."
    end
  end
  
  # ------------------------------------------------------------------------
  # r17311 | jwingate@CATNET.ARIZONA.EDU | 2011-03-29 16:03:34 -0700 (Tue, 29 Mar 2011) | 1 line
  # Changed paths:
     # M /financial-system/kfs/trunk/work/src/edu/arizona/kfs/vnd/document/workflow/VendorMaintenanceDocument.xml
     # M /financial-system/kfs/trunk/work/src/org/kuali/kfs/module/purap/document/workflow/VendorCreditMemoDocument.xml

  # KFSI-3367/KITT-2344 Add CentralAdministrationReview routing to Vendor and Vendor Credit Memo documents.
  # ------------------------------------------------------------------------
  # ------------------------------------------------------------------------
  # r17331 | jwingate@CATNET.ARIZONA.EDU | 2011-03-29 16:21:32 -0700 (Tue, 29 Mar 2011) | 1 line
  # Changed paths:
     # M /financial-system/kfs/trunk/work/src/edu/arizona/kfs/module/purap/document/workflow/PurchaseOrderAmendmentDocument.xml

  # KFSI-3497/KITT-2347 Add Contract Manager routing to Purchase Order Amendment document.
  # ------------------------------------------------------------------------
  def files
    f = []
    log = svn_log("-v")
    log.scan(/r(\d+).*?\nChanged paths:\n(.*?)\n\n/m) do |match|
      revision = $1
      files = $2
      files.split("\n").each do |line|
        if line =~ /\s+(\w) (.+)/
        change = $1
        fname  = $2
        f << {:revision => revision, :fname => fname, :change => change }
        end
      end
    end
    f
  end
  
  def jiras
    j = []
    log = svn_log("-v")
    log.scan(/\n\n(.*?)\n-----/m) do |match|
      match = match.first
      match.scan(/(#{JIRA_PATTERN})/).each do |mat|
        j << mat.first
      end
    end
    j
  end
  
  def jiras_rev(c)
    j = []
    log = svn_log_rev(c, "-v")
    log.scan(/\n\n(.*?)\n-----/m) do |match|
      match = match.first
      match.scan(/(#{JIRA_PATTERN})/).each do |mat|
        j << mat.first
      end
    end
    j
  end
  
  def liquibase_changesets
    l = []
    log = svn_log("-v")
    this_revision = nil
    this_build = nil
    log.split(/\n/).each do |line|
      if ( line =~ /^r(\d+)/ )
        this_revision = "r#{$1}"
      end

      if ( line =~ /^Auto: releasing .* 3.0-(\d+)/ )
        this_build = "3.0-#{$1}"
      end

      if ( line =~ /^   D (.*kfs-cfg-dbs\/trunk\/update\/(.+)\.xml)$/     or
           line =~ /^   D (.*kfs-cfg-dbs\/trunk\/latest\/\w+\/(.+)\.xml)$/
         )
        changeset = $1
        file_name = $2
        l.each_with_index do |ch, i|
          if ch[file_name]
            l[i] << " (included in #{this_build})"
          end
        end
      end

      if ( line =~ /^   A (.*kfs-cfg-dbs\/trunk\/update\/(.+)\.xml)$/     or
           line =~ /^   A (.*kfs-cfg-dbs\/trunk\/latest\/\w+\/(.+)\.xml)$/
         )
        changeset = $1
        file_name = $2
        if file_name =~ /^KITT-\d{4}$/
          l << "#{this_revision} #{changeset}"
        else
          comment = "(but #{file_name}.xml isn't named like KITT-XXXX.xml)"
          len = 79-comment.length
          l << "#{changeset}\n#{" "*len} #{comment}"
        end
      end
    end
    l.uniq
  end

  def workflow_changes
    w = {}
    current_revision = ""
    log = svn_log("-v")
    log.split(/\n/).each do |line|
      if line =~ /^r(\d+) \|/
        current_revision = $1.to_s
      end

      if line =~ /^   \w (.*trunk.*workflow.*\.xml)$/
        w[current_revision] ||= []
        w[current_revision] << $1
      end
    end
    w
  end
end
