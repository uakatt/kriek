Kriek
=====

Automate Subversion Merges...

that's really just about it.

Usage
=====

Kriek is an interactive commandline tool. There are a few files in the repository that show my attempts to give it a frontend.

To use Kriek, `cd` into the base of the Subversion project that you wish to merge revisions _into_. Then run the `kriek.rb` command:

```
$ cd <project_base>
$ ruby <path_to_kriek>/kriek.rb
```

You will then be prompted with the kriek prompt. Type `?` for the menu:

```
Prost!                                                      (Type '?' for help.)
> ?
[]
[]
Kriek. KATTS: <undefined>; Release Number: <undefined>
SET DEBUG ON|OFF             Set debug mode on or off
SET KATTS <katts>            Set the KATTS number for releasing this cherry-pick
SET REL <rel>                Set the release number for this cherry-pick
Add Range <from>:<to>        Merge a range of  svn revisions (currently I have: [])
Add Commit <revision> [...]  Merge one or more svn revisions (currently I have: [])
Add LIQuibase <revision>     Copy a liquibase changeset to kfs-cfg-dbs/branches/release
REMove Range <from>:<to>     Remove a  range  of svn revisions from the above merge list
REMove Commit <revision>     Remove an individual svn revision from the above merge list
SVN Info                     Print `svn info' results for current individual revisions
SVN Log [-v]                 Print `svn log'  results for current individual revisions
FIND FILEs                   Print any associated files for current individual revisions
FIND JIRAs                   Print any associated Jiras for current individual revisions
FIND LIQuibase               Print any liquibase changesets found in current individual revisions
FIND WORKFlow                Print any workflow changes found in current individual revisions
PREView                      Preview the svn commands to run
RUN                          Run the svn commands NOW
Quit                         Quit kriek without executing any svn merges or copies.
>
```

These are all of the available commands. The uppercase letters show what is required to type for unambiguous prefixes. The following are valid commands:

```
svn info
svn inf
svn i
find files
find file
find liquibase
find liq
preview
prev
```

The general workflow for kriek is the following:

1. `> set KATTS 1234` will set the Jira ticket that is the task of releasing this release. This is only used when committing Liquibase files.
2. `set rel 58` will set the release number to "rel-3.0-58". This is only used when committing Liquibase files.
3. `> add commit 11223 11224 11227 11229 11231` will add SVN revision numbers to the list of revisions to be merged.
4. `> add commit 11002 11004 11003` will add more. The revisions are sorted every time you add more.
5. `> svn info` will execute an `svn info` against each revision and print out the results.
6. `> find files` will execute `svn log -v` against each revision, keeping track of all of the affected files, and then prints out the list.
7. `> find jiras` will execute `svn log -v` against each revision, searching the commit messages for Jira numbers, keeping track of them, and then prints out this list.
8. `> find workflow` will search the file list for any in a `/workflow/` directory, and print them.
9. `> preview` will print out the `svn merge` commands that `run` will execute.
10. `> run` will run said `svn merge` commands.

## To change for your institution:

In `lib/kriek.rb` you will most definitely need to change:

* `SVN_URL`
* `SVN_COMMIT_URL`
* `SVN_DB_BRANCHES_URL`
* `SVN_DB_UPDATE_URL`
* `JIRA_PATTERN`

## This README is incomplete.

More to come.
