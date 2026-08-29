@noninteractive
Feature: Command Line Interface non interactive commands

  Scenario: show usage with --help
  When I run `rubyripper_cli --help`
  Then the exit status should be 0
  And the stdout should contain exactly:
  """
  Usage: rubyripper_cli [options]
    -V, --version        Show current version of rubyripper.
    -f, --file <FILE>    Load configuration settings from file <FILE>.
    -v, --verbose        Display verbose output.
    -c, --configure      Change configuration settings.
    -d, --defaults       Skip questions and rip the disc.
        --testdisc <CD>  Provide a directory to stub disc queries.
    -B, --batch          Exit after the disc is done ripping.
    -h, --help           Show this usage statement.

  """

  Scenario: show usage with -h
  When I run `rubyripper_cli -h`
  Then the exit status should be 0
  And the stdout should contain exactly:
  """
  Usage: rubyripper_cli [options]
    -V, --version        Show current version of rubyripper.
    -f, --file <FILE>    Load configuration settings from file <FILE>.
    -v, --verbose        Display verbose output.
    -c, --configure      Change configuration settings.
    -d, --defaults       Skip questions and rip the disc.
        --testdisc <CD>  Provide a directory to stub disc queries.
    -B, --batch          Exit after the disc is done ripping.
    -h, --help           Show this usage statement.

  """

  Scenario: show version number with -V
  When I run `rubyripper_cli -V`
  Then the exit status should be 0
  And the stdout should contain exactly:
  """
  Rubyripper version 0.9.2

  """

  Scenario: show version number with --version
  When I run `rubyripper_cli --version`
  Then the exit status should be 0
  And the stdout should contain exactly:
  """
  Rubyripper version 0.9.2

  """
