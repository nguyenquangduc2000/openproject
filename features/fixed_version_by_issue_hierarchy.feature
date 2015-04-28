#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: The work_package hierarchy defines the allowed versions for each work_package dependent on the type
  As a team member
  I want to CRUD work_packages with a reliable target version system
  So that I know what target version an work_package can have or will be assigned

  Background:
    Given there is 1 project with:
        | name       | ecookbook |
        | identifier | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And there is a role "scrum master"
    And the role "scrum master" may have the following rights:
        | view_master_backlog     |
        | view_taskboards         |
        | update_sprints          |
        | update_stories          |
        | create_impediments      |
        | update_impediments      |
        | update_tasks            |
        | view_wiki_pages         |
        | edit_wiki_pages         |
        | view_work_packages      |
        | edit_work_packages      |
        | manage_subtasks         |
        | create_tasks            |
        | add_work_packages       |
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And there is a default issuepriority with:
        | name   | Normal |
    And the backlogs module is initialized
    And the following types are configured to track stories:
        | Story |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Epic  |
        | Task  |
        | Bug   |
    And the type "Task" has the default workflow for the role "scrum master"
    And there is 1 user with:
        | login | markus |
        | firstname | Markus |
        | Lastname | Master |
    And the user "markus" is a "scrum master"
    And the project has the following sprints:
        | name       | start_date | effective_date  |
        | Sprint 001 | 2010-01-01        | 2010-01-31      |
        | Sprint 002 | 2010-02-01        | 2010-02-28      |
        | Sprint 003 | 2010-03-01        | 2010-03-31      |
        | Sprint 004 | 2.weeks.ago       | 1.week.from_now |
        | Sprint 005 | 3.weeks.ago       | 2.weeks.from_now|
    And the project has the following stories in the following sprints:
        | subject | sprint     |
        | Story A | Sprint 001 |
        | Story B | Sprint 001 |
        | Story C | Sprint 002 |
    And I am already logged in as "markus"

  @javascript
  Scenario: Creating a task, via the taskboard, as a subtask to a story sets the target version to the story´s version
    Given I am on the taskboard for "Sprint 001"
     When I click to add a new task for story "Story A"
      And I fill in "Task 0815" for "subject"
      And I press "OK"
     Then I should see "Task 0815" as a task to story "Story A"
      And the request on task "Task 0815" is finished
      And the task "Task 0815" should have "Sprint 001" as its target version

  @javascript
  Scenario: Stale Object Error when creating task via the taskboard without 'Remaining Hours' after having created a task with 'Remaining Hours' after having created a task without 'Remaining Hours' (bug 9057)
    Given I am on the taskboard for "Sprint 001"
     When I click to add a new task for story "Story A"
      And I fill in "Task1" for "subject"
      And I fill in "3" for "remaining_hours"
      And I press "OK"
      And I click to add a new task for story "Story A"
      And I fill in "Task2" for "subject"
      And I press "OK"
      And I click to add a new task for story "Story A"
      And I fill in "Task3" for "subject"
      And I fill in "3" for "remaining_hours"
      And I press "OK"
      And the request on task "Task1" is finished
      And the request on task "Task2" is finished
      And the request on task "Task3" is finished
     Then there should not be a saving error on task "Task3"
      And the task "Task1" should have "Sprint 001" as its target version
      And the task "Task2" should have "Sprint 001" as its target version
      And the task "Task3" should have "Sprint 001" as its target version
      And task Task1 should have remaining_hours set to 3
      And task Task3 should have remaining_hours set to 3

  #Scenario: Moving a task between stories on the taskboard
  # not testable for now

  @javascript
  Scenario: Creating a task, via subtask, as a subtask to a story sets the new task's fixed version to the parent's fixed version
     When I go to the page of the work package "Story A"
      And I follow the link to add a subtask
      And I select "Task" from "work_package_type_id"
      And I fill in "Task 0815" for "work_package_subject"
      And I click on the first button matching "Create"
     Then I should see "Sprint 001" within "dd.-fixed-version"

  Scenario: Creating a task, via new work_package, as a subtask to a story set´s the new task´s fixed version to the parent´s fixed version
     When I go to the new work_package page of the project called "ecookbook"
      And I select "Task" from "work_package_type_id"
      And I fill in "Task 0815" for "work_package_subject"
      And I fill in the id of the work_package "Story A" as the parent work_package
      And I click on the first button matching "Create"
     Then I should see "Sprint 001" within "dd.-fixed-version"

  Scenario: Creating a task, via new work_package, as a subtask to a story and setting a fixed version is overriden by the parent´s fixed version (bug 8904)
     When I go to the new work_package page of the project called "ecookbook"
      And I select "Task" from "work_package_type_id"
      And I fill in "Task 0815" for "work_package_subject"
      And I fill in the id of the work_package "Story A" as the parent work_package
      And I select "Sprint 003" from "work_package_fixed_version_id"
      And I click on the first button matching "Create"
     Then I should see "Sprint 001" within "dd.-fixed-version"

  Scenario: Moving a task between stories via work_package/edit (bug 9324)
    Given the project has the following tasks:
          | subject | parent  |
          | Task 1  | Story A |
    When I go to the edit page of the work_package "Task 1"
     And I fill in the id of the work_package "Story C" as the parent work_package
     And I press "Submit"
    Then I should see "Sprint 002" within "dd.-fixed-version"

  Scenario: Changing the fixed_version of a task with a non backlogs parent work_package (bug 8354)
    Given the project has the following work_packages:
      | subject      | sprint     | type    |
      | Epic 1       | Sprint 001 | Epic       |
      And the project has the following tasks:
      | subject | parent |
      | Task 1  | Epic 1 |
    When I go to the edit page of the work_package "Task 1"
     And I select "Sprint 002" from "work_package_fixed_version_id"
     And I press "Submit"
    Then I should see "Successful update." within "div.flash"

  Scenario: Changing the fixed_version of an epic should not change the target version of the child (bug 8903)
    Given the project has the following work_packages:
      | subject      | sprint     | type    | parent |
      | Epic 1       | Sprint 001 | Epic       |        |
      | Task 1       | Sprint 002 | Task       | Epic 1 |
   When I go to the edit page of the work_package "Epic 1"
    And I select "Sprint 003" from "work_package_fixed_version_id"
    And I press "Submit"
   Then I should see "Successful update." within "div.flash"
    And the task "Task 1" should have "Sprint 002" as its target version

  Scenario: Modification of a backlogs story with tasks is still possible (bug 9711)
    Given the project has the following tasks:
      | subject | parent  |
      | Task 1  | Story A |
      | Task 2  | Story A |
    When I go to the edit page of the work_package "Story A"
     And I select "Sprint 002" from "work_package_fixed_version_id"
     And I click "Submit"
    Then I should not see "Data has been updated by another user." within "div.flash"
     And the story "Story A" should have "Sprint 002" as its target version
     And the task "Task 1" should have "Sprint 002" as its target version
     And the task "Task 2" should have "Sprint 002" as its target version
