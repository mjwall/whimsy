#!/usr/bin/env ruby
# Wvisible:brand,trademarks
PAGETITLE = 'Listing of Apache Trademarks'

$LOAD_PATH.unshift File.realpath(File.expand_path('../../../lib', __FILE__))
require 'csv'
require 'json'
require 'whimsy/asf'
require 'wunderbar'
require 'wunderbar/bootstrap'
require 'wunderbar/jquery'
require 'net/http'

# Fieldnames/values from counsel provided docket.csv
MNAM = 'TrademarkName'
COUNTRY = 'CountryName' 
STAT = 'TrademarkStatus'
CLASS = 'Class'
REG = 'RegNumber'
APPNUMBER = 'AppNumber'
CLASSGOODS = 'ClassGoods'
REGISTERED = 'Registered'
USA = 'United States of America'

# Transform docket spreadsheet into structured JSON
def csv2json
  brand_dir = ASF::SVN['private/foundation/Brand']
  csv = CSV.read("#{brand_dir}/docket.csv", headers:true)
  docket = {}
  csv.each do |r|
    r << ['pmc', r[MNAM].downcase.sub('.org','').sub(' & design','')]
    key = r['pmc'].to_sym
    mrk = {}
    %W[ #{STAT} #{COUNTRY} #{CLASS} #{APPNUMBER} #{REG} #{CLASSGOODS} ].each do |col|
      mrk[col] = r[col]
    end  
    if not docket.key?(key)
      docket[key] = { r[MNAM] => [mrk] }
    else
      if not (docket[key]).key?(r[MNAM])
        docket[key][r[MNAM]] = [mrk]
      else
        docket[key][r[MNAM]] << mrk      
      end
    end
  end
  
  docket
end

# Since the CSV changes rarely, it is manually checked in separately
_json do
  csv2json
end

def _unreg(pmc, proj, parent, n)
  _div.panel.panel_default  id: pmc do
    _div.panel_heading role: "tab", id: "urh#{n}" do
      _h4.panel_title do
        _a.collapsed role: "button", data_toggle: "collapse",  aria_expanded: "false", data_parent: "##{parent}", href: "#urc#{n}", aria_controls: "urc#{n}" do
          _ proj['name']
          _{"&trade; software"}
        end
      end
    end
    _div.panel_collapse.collapse id: "urc#{n}", role: "tabpanel", aria_labelledby: "urh#{n}" do
      _div.panel_body do
        _a href: proj['homepage'] do
          _ proj['name']
        end
        _ ': '
        _ proj['description']
      end
    end
  end
end

def _marks(marks)
  marks.each do |mark, items|
    _ul.list_group do
      _li!.list_group_item.active do
        _{"#{mark} &reg;"}
      end
      items.each do |itm|
        if itm[STAT] == REGISTERED then
          if itm[COUNTRY] == USA then
            _li.list_group_item do
              _a! "In the #{itm[COUNTRY]}, class #{itm[CLASS]}, reg # #{itm[REG]}", href: "https://tsdr.uspto.gov/#caseNumber=#{itm[REG]}&caseSearchType=US_APPLICATION&caseType=DEFAULT&searchType=statusSearch"
            end
          else
            _li.list_group_item "In #{itm[COUNTRY]}, class #{itm[CLASS]}, reg # #{itm[REG]}"
          end
        end
      end
    end
  end
end

def _project(pmc, proj, marks)
  _div.panel.panel_primary id: pmc do
    _div.panel_heading do 
      _h3!.panel_title do 
        _a! proj['name'], href: proj['homepage']
        _{"&reg; software"}
      end
    end
    _div.panel_body do
      _{"The ASF owns the following registered trademarks for our #{proj['name']}&reg; software:"}
    end
    _marks marks
  end
end

def _apache(marks)
  _div.panel.panel_primary id: 'apache' do
    _div.panel_heading do 
      _h3.panel_title do 
        _{"Our APACHE&reg; trademarks"}
      end
    end
    _div!.panel_body do
      _{"Our APACHE&reg; trademark represents our house brand of consensus-driven, community built software for the public good."}
    end
    _marks marks
  end
end

_html do
  _body? do
    _whimsy_header PAGETITLE
    brand_dir = ASF::SVN['private/foundation/Brand']
    docket = JSON.parse(File.read("#{brand_dir}/docket.json"))
    projects = JSON.parse(Net::HTTP.get(URI('https://projects.apache.org/json/foundation/projects.json')))

    _whimsy_content do
      _h3 'The ASF holds the following registered trademarks:'
      docket.each do |pmc, marks|
        if pmc == 'apache' then
          _apache(marks)
        elsif projects[pmc] then
          _project pmc, projects[pmc], marks
        else
          _.comment! '# TODO map all pmc names to projects or podlings'
          _project 'Apache ' + pmc.capitalize, 'https://' + pmc + '.apache.org', marks
        end
      end
      
      _h3 'The ASF holds the following unregistered trademarks:'
      parent = "unreg_a" # TODO: split up by letter
      _div.panel_group id: parent, role: "tablist", aria_multiselectable: "true" do
        projects.each_with_index do |(pnam, proj), num|
          unless docket[pnam] then
            _unreg(pnam, proj, parent, num)
          end
        end
      end
    end

    _whimsy_footer({
      "https://www.apache.org/foundation/marks/resources" => "Trademark Site Map",
      "https://www.apache.org/foundation/marks/list/" => "Official Apache Trademark List",
      "https://www.apache.org/foundation/marks/contact" => "Contact Us About Trademarks"
      })
  end
end
