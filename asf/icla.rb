module ASF

  class ICLA
    include Enumerable

    def self.find_by_id(value)
      return if value == 'notinavail'
      new.each do |id, name, email|
        if id == value
	  return Struct.new(:id, :name, :email).new(id, name, email)
        end 
      end
      nil
    end

    def self.find_by_email(value)
      value = value.downcase
      ICLA.new.each do |id, name, email|
        if email.downcase == value
	  return Struct.new(:id, :name, :email).new(id, name, email)
        end 
      end
      nil
    end

    def self.availids
      return @availids if @availids
      availids = []
      ICLA.new.each {|id, name, email| availids << id unless id == 'notinavail'}
      @availids = availids
    end

    def each(&block)
      officers = ASF::SVN['private/foundation/officers']
      iclas = File.read("#{officers}/iclas.txt")
      iclas.scan(/^([-\w]+):.*?:(.*?):(.*?):/).each(&block)
    end
  end

  class Person
    def icla
      @icla ||= ASF::ICLA.find_by_id(name)
    end

    def icla?
      ICLA.availids.include? name
    end
  end

  def self.search_archive_by_id(value)
    require 'net/http'
    require 'nokogiri'
    committers = 'http://people.apache.org/committer-index.html'
    doc = Nokogiri::HTML(Net::HTTP.get(URI.parse(committers)))
    doc.search('tr').each do |tr|
      tds = tr.search('td')
      next unless tds.length == 3
      return tds[1].text if tds[0].text == value
    end
    nil
  rescue
    nil
  end
end
