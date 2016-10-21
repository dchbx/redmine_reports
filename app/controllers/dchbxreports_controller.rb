class DchbxreportsController < ApplicationController
  unloadable
  helper :queries
  include QueriesHelper

  def index
    @cq = IssueQuery.where(visibility: 2).order('project_id ASC')
  end

  def velocity
    @output = {}
    @output['totalIssuesWithWBSandStoryPoints'] = IssueQuery.find(208)
  end

  def usersReturnForDef
    @output = {}
    journalDetails = JournalDetail.where(value: 6).where(property: "attr").where(prop_key: "status_id")
    journalDetails.each do |jd|
      user_id = false
      jd.journal.details.where(prop_key: 'assigned_to_id').each do |jd_user|
        user_id = jd_user.value
      end
      unless user_id == false
        if @output[user_id].nil?
          @output[user_id] = {}
          @output[user_id]['issue_count'] = {};
          JournalDetail.where(value: user_id).where(property: "attr").where(prop_key: "assigned_to_id").each do |jdd|
            @output[user_id]['issue_count'][jdd.journal.journalized_id] = true;
          end
          @output[user_id]['rfd_count'] = 1
        elsif @output[user_id]['rfd_count'].nil?
          @output[user_id]['rfd_count'] = 1
        else
          @output[user_id]['rfd_count'] = @output[user_id]['rfd_count'] + 1
        end
      end
    end
    @output.each do |user_id,user_info|
      @output[user_id]['user'] = User.where(id: user_id).where(status: 1).first
      @output[user_id]['issue_count'] = @output[user_id]['issue_count'].count()
      @output[user_id]['per'] = (@output[user_id]['rfd_count'].to_f / @output[user_id]['issue_count'].to_f ) * 100
    end
    ## figure out thrashing per issue
    @issueOut = {}
    Issue.where(closed_on: nil).where(project_id:[24,94]).each do |issue|
      @issueOut[issue.id] = {}
      @issueOut[issue.id]['thrashCount'] = 0
      @issueOut[issue.id]['issue'] = issue
      issue.journals.each do |journal|
        @issueOut[issue.id]['thrashCount'] = @issueOut[issue.id]['thrashCount'] + journal.details.where(prop_key:'status_id').where(property: "attr").where(value:[9,33,28,6,8,4]).count
      end
    end
    @issueOut.sort_by {|key,value| value['thrashCount'].to_i }
  end

  def duedates
    @output = {
      'Issues Not Started Past Start Date' => {
        'total' => {
          'query_id' => 190,
        },
        'left' => {
          'query_id' => 191,
        }
      },
      'Issues Past Due' =>{
        'total' => {
          'query_id' => 188
        },
        'left' => {
          'query_id' => 189
        }
      },
      'Issues Closed' => {
        'total' => {
          'query_id' => 192
        }
      },
      'Issues In Flight' => {
        'total' => {
          'query_id' => 195
        }
      }
    }
    @output.each do |barTitle,barPercents|
      unless @output[barTitle]['total'].nil?
        @output[barTitle]['total']['query'] = IssueQuery.find(@output[barTitle]['total']['query_id'])
        @output[barTitle]['total']['issue_count'] = @output[barTitle]['total']['query'].issue_count
      end
      unless @output[barTitle]['left'].nil?
        @output[barTitle]['left']['query'] = IssueQuery.find(@output[barTitle]['left']['query_id'])
        @output[barTitle]['left']['issue_count'] = @output[barTitle]['left']['query'].issue_count
        ##figure out percents!
        @output[barTitle]['percentDone'] = ( @output[barTitle]['left']['issue_count'].to_f / @output[barTitle]['total']['issue_count'].to_f ) * 100
        @output[barTitle]['percentLeft'] = 100 - @output[barTitle]['percentDone'].to_f
      end
    end
    ##bottom issue list
    @issueList = Issue.where(project_id:94).where(fixed_version_id:107).order('status_id').order('updated_on DESC')
    @bugIssueList = Issue.where(project_id:24).order('status_id')
  end

  # def stakeholders
  #   issueStatusIdForStakeholderReview = 8
  #   @issuesInStakeholderReview = Issue.where('status_id = ?', issueStatusIdForStakeholderReview).order('assigned_to_id ASC, id ASC')
  # end

  def sla
    ## This can help us tell if an issue is closed or not
    issueStatus = IssueStatus.all
    ## This gives us all the issues, to make sure we don't have to call the db X times
    @projects_to_track = [12,26,33,20,21,22,16,23,24,94,98,97,25]
    issues = Issue.where(project_id: @projects_to_track)
    ## Trackers
    trackers = Tracker.all
    ## Issue priorities
    issuePriorities = Enumeration.where("type = 'IssuePriority'")
    ##processed var we pass to view
    @slaReport = {}
    ## run over each issue, and each sla, to generate our data
    Setting.plugin_redmine_reports['slas'].each_with_index do |sla,id|
      @slaReport[id] = {}
      @slaReport[id]['type'] = sla['type']
      @slaReport[id]['id'] = sla['id']
      @slaReport[id]['timeToResolve'] = sla['timeToResolve']
      @slaReport[id]['daysToResolve'] = sla['timeToResolve'] / (24*60*60)
      @slaReport[id]['totalIssues'] = 0
      @slaReport[id]['closedIssues'] = 0
      @slaReport[id]['closedIssuesInProgressTime'] = 0
      @slaReport[id]['openInSlaIssues'] = 0
      @slaReport[id]['openPastSlaIssues'] = 0

      ##find the name of the SLA we are tracking
      if sla['type'] == "trackers"
        trackers.each do |tracker|
          if tracker.id.to_i == sla['id'].to_i
            @slaReport[id]['name'] = "Tracker: #{tracker.name}"
          end
        end
      end
      if sla['type'] == "enumerations"
        issuePriorities.each do |pri|
          if pri['id'].to_i == sla['id'].to_i
            @slaReport[id]['name'] = "Priority: #{pri.name}"
          end
        end
      end
      if sla['type'] == "issue_status"
        myIssueName = IssueStatus.where('id = ?',sla['id'].to_i).first.name
        @slaReport[id]['name'] = "Issue Status: #{myIssueName}"
      end
      ##loop our issues and find our data
      issues.each do |issue|
        if (
          sla['type'] == "trackers" &&
          issue['tracker_id'].to_i == sla['id'].to_i
        ) ||
        (
          sla['type'] == "enumerations" &&
          issue['priority_id'].to_i == sla['id'].to_i
        ) ||
        (
          sla['type'] == "issue_status" &&
          issue['status_id'].to_i == sla['id'].to_i
        )
          ##figure out if the issue is currently closed or not
          issueIsClosed = false
          issueStatus.each do |status|
            if issue['status_id'].to_i == status['id'].to_i
              if status.is_closed
                issueIsClosed = true
                if issue['closed_on'].to_i > Time.new.to_i - Setting.plugin_redmine_reports['slaShowProgressTime'].to_i
                  @slaReport[id]['closedIssuesInProgressTime'] = @slaReport[id]['closedIssuesInProgressTime'] + 1
                end
              end
            end
          end
          ##figure out if the issue is in our SLA period
          if issueIsClosed == false
            if to_boolean(sla['sinceCreation'])
              timeSince = issue['created_on'].beginning_of_day.to_i + sla['timeToResolve'].to_i
            else
              timeSince = issue['updated_on'].beginning_of_day.to_i + sla['timeToResolve'].to_i
            end
            if timeSince < Time.new.to_i
              @slaReport[id]['openPastSlaIssues'] = @slaReport[id]['openPastSlaIssues'] + 1
            else
              @slaReport[id]['openInSlaIssues'] = @slaReport[id]['openInSlaIssues'] + 1
            end
          else
            @slaReport[id]['closedIssues'] = @slaReport[id]['closedIssues'] + 1
          end
          ##record our total number of issues for this sla
          @slaReport[id]['totalIssues'] = @slaReport[id]['totalIssues'] + 1
        end
      end
    end
  end


  def status
    @issueStatuses = IssueStatus.where('is_closed = ?', false)
    @users = User.all()
    @issues = {}
    @issueStatuses.each do |status|
      @issues[status['id']] = Issue.where('closed_on IS NULL').where('status_id = ?',status['id']).where(project_id: [24,94]).order('updated_on ASC')
    end
  end

  def userHoldUp
    @userStats = {}
    issueStatus = IssueStatus.all
    users = User.where('status = 1').order(:lastname)
    ##users = User.where('status = ?','active').or('status = ?', 'registered')
    users.each do |user|
      totalWaitTime = 0
      userIssues = {}
      issues = Issue.where("assigned_to_id = ?",user['id']).where(project_id: [24,94])
      issues.each do |issue|
        ##figure out if the issue is currently closed or not
        issueIsClosed = false
        issueStatus.each do |status|
          if issue['status_id'].to_i == status['id'].to_i
            if status.is_closed
              issueIsClosed = true
            end
          end
        end
        if issueIsClosed == false
          totalWaitTime = totalWaitTime + (Time.new.to_i - issue['updated_on'].to_i)
          userIssues[i] = issue
        end
      end
      @userStats[user['id'].to_s] = {
        'user' => user,
        'totalWaitTime' => totalWaitTime,
        'issues' => userIssues,
      }
    end
    ##@userStats.sort! { |a,b| a['totalWaitTime'] <=> b['totalWaitTime'] }
  end
  private
  def i
    @i ||= -1
    @i += 1
  end
  def to_boolean(str)
    str == 'true'
  end
end
