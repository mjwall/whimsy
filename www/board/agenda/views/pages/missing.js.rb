#
# A page showing all flagged reports
#

class Missing < React
  def initialize
    @checked = {}
  end

  # update checkmarks on first load
  def componentDidMount()
    self.componentWillReceiveProps()
  end

  # update check marks based on current Index
  def componentWillReceiveProps()
    Agenda.index.each do |item|
      @checked[item.title] = true unless defined? @checked[item.title]
    end
  end

  def render
    first = true

    Agenda.index.each do |item|
      if item.missing
        _h3 class: item.color do
          if item.attach =~ /^[A-Z]+/
            _input type: 'checkbox', name: 'selected', value: item.title,
              checked: @checked[item.title], onChange:-> {
                @checked[item.title] = !@checked[item.title]
                self.forceUpdate()
              }
          end

          _Link text: item.title, href: "flagged/#{item.href}",
            class: ('default' if first)
          first = false

          _span.owner " [#{item.owner} / #{item.shepherd}]"

          if item.flagged_by
            flagged_by = Server.directors[item.flagged_by] || item.flagged_by
            _span.owner " flagged by: #{flagged_by}"
          end
        end

        _AdditionalInfo item: item, prefix: true
      end
    end

    _em.comment 'None' if first
  end
end
