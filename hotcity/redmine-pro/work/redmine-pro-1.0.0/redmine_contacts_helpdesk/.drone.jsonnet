local Pipeline(rubyVer, license, db, redmine) = {
  kind: "pipeline",
  name: rubyVer + "-" + db + "-" + redmine + "-" + license,
  steps: [
    {
      name: "tests",
      image: "redmineup/redmine_contacts_helpdesk",
      commands: [
        "service postgresql start && service mysql start && sleep 5",
        "export PATH=~/.rbenv/shims:$PATH",
        "export CODEPATH=`pwd`",
        "/root/run_for.sh redmine_contacts_helpdesk+" + license + " ruby-" + rubyVer + " " + db + " redmine-" + redmine
      ]
    }
  ]
};

[
  Pipeline("2.4.1", "pro", "mysql", "trunk"),
  Pipeline("2.4.1", "light", "mysql", "trunk"),
  Pipeline("2.4.1", "pro", "pg", "trunk"),
  Pipeline("2.4.1", "light", "mysql", "4.1"),
  Pipeline("2.4.1", "pro", "pg", "4.1"),
  Pipeline("2.4.1", "pro", "mysql", "4.1"),
  Pipeline("2.4.1", "pro", "pg", "4.0"),
  Pipeline("2.2.6", "pro", "mysql", "3.4"),
  Pipeline("2.2.6", "light", "mysql", "3.4"),
  Pipeline("2.2.6", "pro", "pg", "3.4"),
  Pipeline("2.2.6", "light", "pg", "3.4"),
  Pipeline("2.2.6", "pro", "mysql", "3.0"),
  Pipeline("1.9.3", "pro", "pg", "2.6")
]
