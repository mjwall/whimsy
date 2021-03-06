#!/usr/bin/env ruby
$LOAD_PATH.unshift File.realpath(File.expand_path('../../../lib', __FILE__))

require 'whimsy/asf'
require 'wunderbar/bootstrap'
require 'date'
require 'json'
require 'wunderbar/jquery/stupidtable'

# separator / is added when link is generated
ROSTER = "https://whimsy.apache.org/roster/committer"

# locate and read the attendance file
MEETINGS = ASF::SVN['private/foundation/Meetings']
attendance = JSON.parse(IO.read("#{MEETINGS}/attendance.json"))

# extract and format dates
dates = attendance['dates'].sort.
map {|date| Date.parse(date).strftime('%Y-%b')}

# compute mappings of names to ids
members = ASF::Member.list
active = Hash[members.select {|id, data| not data['status']}]
nameMap = Hash[members.map {|id, data| [id, data[:name]]}]
idMap = Hash[nameMap.to_a.map(&:reverse)]

# analyze attendance
matrix = attendance['matrix'].map do |name, meetings|
  id = idMap[name]
  next unless id and active[id]
  data = meetings.sort.reverse.map(&:last)
  first = data.length
  missed = (data.index {|datum| datum != '-'} || data.length)
  
  [id, name, first, missed]
end

# produce HTML
_html do
  _body? do
    _whimsy_header 'Active Members not participating in meetings'
    _whimsy_content do
      
    @meetingsMissed = (@meetingsMissed || 3).to_i
      
    _div.row do
      _div.col_md_6 do
        _div.panel.panel_primary do
          _div.panel_heading {_h3.panel_title 'Select Date'}
          _div.panel_body do
            _form_ do
              _span "List of members that have not participated, starting with the "
              _select name: 'meetingsMissed', onChange: 'this.form.submit()' do
                dates.reverse.each_with_index do |name, i|
                  _option name, value: i+1, selected: (i+1 == @meetingsMissed)
                end
              end
              _span "meeting.  Active members does not include emeritus or deceased members."
            end
          end
        end
      end
      _div.col_md_6 do
        _div.panel.panel_primary do
          _div.panel_heading {_h3.panel_title 'Definitions'}
          _div.panel_body do
            _ 'Participating is defined by doing at least one of the following:'
            _ul do
              _li 'Attending a members meeting'
              _li 'Voting in an election'
              _li 'Assigning a proxy'
            end
          end
        end
      end
    end
    
    count = 0
    _table.table.table_hover do
      _thead do
        _tr do
          _th 'Name', data_sort: 'string'
          _th 'Membership start date', data_sort: 'string'
          _th 'Last participated', data_sort: 'string'
        end
      end
      
      matrix.each do |id, name, first, missed|
        next unless id
        
        if missed >= @meetingsMissed
          _tr_ do
            _td! {_a nameMap[id], href: "#{ROSTER}/#{id}"}
            _td dates[-first-1] || dates.first
            if missed >= first
              _td {_em 'never'}
            else
              _td dates[-missed-1]
            end
          end
          count += 1
        end
      end
    end
    
    _div.count "Count: #{count} members inactive for #{@meetingsMissed} meetings."
    
    _script %{
      var table = $(".table").stupidtable();
      table.on("aftertablesort", function (event, data) {
        var th = $(this).find("th");
        th.find(".arrow").remove();
        var dir = $.fn.stupidtable.dir;
        var arrow = data.direction === dir.ASC ? "&uarr;" : "&darr;";
        th.eq(data.column).append('<span class="arrow">' + arrow +'</span>');
        });
      }
    end
  end
end
  
_json do
  meetingsMissed = (@meetingsMissed || 3).to_i
  
  inactive = matrix.select do |id, name, first, missed|
    id and missed >= meetingsMissed
  end
  
  Hash[inactive.map {|id, name, first, missed| 
    [id, {name: name, missed: missed, status: 'no response yet'}]
    }]
end
