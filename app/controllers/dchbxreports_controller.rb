class DchbxreportsController < ApplicationController
  unloadable



  def index
  end


  def sla
    ## This can help us tell if an issue is closed or not
    issueStatus = IssueStatus.all
    ## This gives us all the issues, to make sure we don't have to call the db X times
    issues = Issue.all
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
      ##loop our issues and find our data
      issues.each do |issue|
        if (
          sla['type'] == "trackers" &&
          issue['tracker_id'].to_i == sla['id'].to_i
        ) ||
        (
          sla['type'] == "enumerations" &&
          issue['priority_id'].to_i == sla['id'].to_i
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
            if ( issue['created_on'].to_i + sla['timeToResolve'].to_i ) < Time.new.to_i
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
      @issues[status['id']] = Issue.where('closed_on IS NULL').where('status_id = ?',status['id']).order('updated_on ASC')
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
      issues = Issue.where("assigned_to_id = ?",user['id'])
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
end
