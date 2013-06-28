Feature: Uploading cookbooks to a Chef Server
  As a Berkshelf CLI user
  I need a way to upload cookbooks to a Chef Server that I have installed into my Bookshelf
  So they are available to Chef clients

  Scenario: With no arguments
    Given the cookbook store has the cookbooks:
      | fake | 1.0.0 |
      | ekaf | 2.0.0 |
    And I write to "Berksfile" with:
      """
      cookbook 'fake', '1.0.0'
      cookbook 'ekaf', '2.0.0'
      """
    When I successfully run `berks upload`
    Then the output should contain:
      """
      Uploading fake (1.0.0) to: 'http://localhost:4000/'
      Uploading ekaf (2.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | fake   | 1.0.0 |
      | ekaf   | 2.0.0 |
    And the exit status should be 0

  Scenario: With a path location in the Berksfile
    Given a cookbook named "fake"
    And I write to "Berksfile" with:
      """
      cookbook 'fake', path: './fake'
      """
    When I successfully run `berks upload`
    Then the output should contain:
      """
      Uploading fake (0.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | fake | 0.0.0 |
    And the exit status should be 0

  Scenario: With a git location in the Berksfile
    Given the cookbook store has the cookbooks:
      | berkshelf-cookbook-fixture | 0.1.0 |
    And I write to "Berksfile" with:
      """
      cookbook 'berkshelf-cookbook-fixture', ref: 'v0.1.0'
      """
    When I successfully run `berks upload`
    Then the output should contain:
      """
      Uploading berkshelf-cookbook-fixture (0.1.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | berkshelf-cookbook-fixture | 0.1.0 |
    And the exit status should be 0

  Scenario: With a single cookbook
    Given the cookbook store has the cookbooks:
      | fake  | 1.0.0 |
      | ekaf  | 2.0.0 |
    And the cookbook store contains a cookbook "reset" "3.4.5" with dependencies:
      | fake | ~> 1.0.0 |
    And I write to "Berksfile" with:
      """
      cookbook 'fake', '1.0.0'
      cookbook 'ekaf', '2.0.0'
      cookbook 'reset', '3.4.5'
      """
    When I successfully run `berks upload reset`
    Then the output should contain:
      """
      Uploading reset (3.4.5) to: 'http://localhost:4000/'
      Uploading fake (1.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | reset | 3.4.5 |
      | fake  | 1.0.0 |
    And the Chef Server should not have the cookbooks:
      | ekaf  | 2.0.0 |
    And the exit status should be 0

  Scenario: With multiple cookbooks
    Given the cookbook store has the cookbooks:
      | ntp  | 1.0.0 |
      | vim  | 1.0.0 |
      | apt  | 1.0.0 |
    Given I write to "Berksfile" with:
      """
      cookbook 'ntp', '1.0.0'
      cookbook 'vim', '1.0.0'
      cookbook 'apt', '1.0.0'
      """
    When I successfully run `berks upload ntp vim`
    Then the output should contain:
      """
      Uploading ntp (1.0.0) to: 'http://localhost:4000/'
      Uploading vim (1.0.0) to: 'http://localhost:4000/'
      """
    And the output should not contain:
      """
      Uploading apt (1.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | ntp |
      | vim |
    And the Chef Server should not have the cookbooks:
      | apt |
    And the exit status should be 0

  Scenario: With the --only flag
    Given the cookbook store has the cookbooks:
      | core    | 1.0.0 |
      | system  | 1.0.0 |
    Given I write to "Berksfile" with:
      """
      group :group_a do
        cookbook 'core', '1.0.0'
      end

      group :group_b do
        cookbook 'system', '1.0.0'
      end
      """
    When I successfully run `berks upload --only group_a`
    Then the output should contain:
      """
      Uploading core (1.0.0) to: 'http://localhost:4000/'
      """
    And the output should not contain:
      """
      Uploading system (1.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | core | 1.0.0 |
    And the Chef Server should not have the cookbooks:
      | system | 1.0.0 |
    And the exit status should be 0

  Scenario: With the --only flag specifying multiple groups
    Given the cookbook store has the cookbooks:
      | core    | 1.0.0 |
      | system  | 1.0.0 |
    Given I write to "Berksfile" with:
      """
      group :group_a do
        cookbook 'core', '1.0.0'
      end

      group :group_b do
        cookbook 'system', '1.0.0'
      end
      """
    When I successfully run `berks upload --only group_a group_b`
    Then the output should contain:
      """
      Uploading core (1.0.0) to: 'http://localhost:4000/'
      Uploading system (1.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | core   | 1.0.0 |
      | system | 1.0.0 |
    And the exit status should be 0

  Scenario: With the --except flag
    Given the cookbook store has the cookbooks:
      | core    | 1.0.0 |
      | system  | 1.0.0 |
    Given I write to "Berksfile" with:
      """
      group :group_a do
        cookbook 'core', '1.0.0'
      end

      group :group_b do
        cookbook 'system', '1.0.0'
      end
      """
    When I successfully run `berks upload --except group_b`
    Then the output should contain:
      """
      Uploading core (1.0.0) to: 'http://localhost:4000/'
      """
    And the output should not contain:
      """
      Uploading system (1.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | core | 1.0.0 |
    And the Chef Server should not have the cookbooks:
      | system | 1.0.0 |
    And the exit status should be 0

  Scenario: With the --except flag specifying multiple groups
    Given the cookbook store has the cookbooks:
      | core    | 1.0.0 |
      | system  | 1.0.0 |
    Given I write to "Berksfile" with:
      """
      group :group_a do
        cookbook 'core', '1.0.0'
      end

      group :group_b do
        cookbook 'system', '1.0.0'
      end
      """
    When I successfully run `berks upload --except group_a group_b`
    Then the output should not contain:
      """
      Uploading core (1.0.0) to: 'http://localhost:4000/'
      Uploading system (1.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should not have the cookbooks:
      | core   | 1.0.0 |
      | system | 1.0.0 |
    And the exit status should be 0

  Scenario: With an invalid cookbook
    Given a cookbook named "cookbook with spaces"
    And I write to "Berksfile" with:
      """
      cookbook 'cookbook with spaces', path: './cookbook with spaces'
      """
    When I run `berks upload`
    Then the output should contain:
      """
      The cookbook 'cookbook with spaces' has invalid filenames:
      """
    And the exit status should be "InvalidCookbookFiles"

  Scenario: With the --skip-dependencies flag
    Given the cookbook store has the cookbooks:
      | fake  | 1.0.0 |
      | ekaf  | 2.0.0 |
    And the cookbook store contains a cookbook "reset" "3.4.5" with dependencies:
      | fake | ~> 1.0.0 |
    And I write to "Berksfile" with:
      """
      cookbook 'fake', '1.0.0'
      cookbook 'ekaf', '2.0.0'
      cookbook 'reset', '3.4.5'
      """
    When I successfully run `berks upload reset -D`
    Then the output should contain:
      """
      Uploading reset (3.4.5) to: 'http://localhost:4000/'
      Uploading fake (1.0.0) to: 'http://localhost:4000/'
      """
    And the Chef Server should have the cookbooks:
      | reset | 3.4.5 |
      | fake  | 1.0.0 |
    And the Chef Server should not have the cookbooks:
      | ekaf  | 2.0.0 |
    And the exit status should be 0

  Scenario: When the cookbook already exist
    Given the cookbook store has the cookbooks:
      | fake  | 1.0.0 |
    And the Chef server has frozen cookbooks:
      | fake  | 1.0.0 |
    And I write to "Berksfile" with:
      """
      cookbook 'fake', '1.0.0'
      """
    When I successfully run `berks upload`
    Then the output should contain:
      """
      Skipping fake (1.0.0) (already uploaded)
      """
    And the exit status should be 0

  @chef_server @slow_process
  Scenario: When the cookbook already exist and is a metadata location
    Given a cookbook named "fake"
    And the cookbook "fake" has the file "Berksfile" with:
      """
      metadata
      """
    When I cd to "fake"
    And the Chef server has frozen cookbooks:
      | fake  | 0.0.0 |
    When I run `berks upload`
    Then the output should contain:
      """
      The cookbook fake (0.0.0) already exists and is frozen on the Chef server. Use the 'force' option to override.
      """
    And the CLI should exit with the status code for error "FrozenCookbook"
