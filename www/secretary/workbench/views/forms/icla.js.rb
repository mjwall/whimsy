class ICLA < React
  def initialize
    @filed = false
    @checked = nil
    @submitted = false
  end

  def render
    _h4 'ICLA'

    _div.buttons do
      _button 'clear form', disabled: @filed,
        onClick: -> {@pubname = @realname = @email = @filename = ''}
    end

    _form method: 'post', action: '../../tasklist/icla', target: 'content' do
      _input type: 'hidden', name: 'message'
      _input type: 'hidden', name: 'selected'
      _input type: 'hidden', name: 'signature', value: @@signature

      _table.form do
        _tr do
          _th 'Real Name'
          _td do
            _input name: 'realname', value: @realname, required: true,
               disabled: @filed, onChange: self.changeRealName
          end
        end

        _tr do
          _th 'Public Name'
          _td do
            _input name: 'pubname', value: @pubname, required: true,
              disabled: @filed, onFocus: -> {@pubname ||= @realname}
          end
        end

        _tr do
          _th 'E-mail'
          _td do
            _input name: 'email', value: @email, required: true, type: 'email',
              disabled: @filed
          end
        end

        _tr do
          _th 'File Name'
          _td do
            _input name: 'filename', value: @filename, required: true,
              pattern: '[a-zA-Z][-\w]+(\.[a-z]+)?', disabled: @filed
          end
        end
      end

      _table.form do
        _tr do
          _th 'User ID'
          _td do
            _input name: 'user', value: @user, onBlur: self.validate_userid,
              disabled: @filed, pattern: '^[a-z][-a-z0-9_]+$'
          end
        end

        _tr do
          _th 'Project'
          _td do
            _input name: 'project', value: @project, disabled: @filed
          end
        end

        _tr do
          _th 'Vote Link'
          _td do
            _input type: 'url', name: 'votelink', value: @votelink,
              disabled: @filed
          end
        end
      end

      _input.btn.btn_primary value: 'File', type: 'submit', ref: 'file'
    end
  end

  # on initial display, default various fields based on headers, and update
  # state 
  def componentDidMount()
    name = @@headers.name || ''

    # reorder name if there is a single comma present
    parts = name.split(',')
    if parts.length == 2 and parts[1] !~ /^\s*(jr|ph\.d)\.?$/i
      name = "#{parts[1].strip()} #{parts[0]}" 
    end

    @realname = name
    @pubname = name
    @filename = self.genfilename(name)
    @email = @@headers.from
    self.componentDidUpdate()

    # watch for status updates
    window.addEventListener 'message', self.status_update
  end

  def componentWillUnmount()
    window.removeEventListener 'message', self.status_update
  end

  # as fields change, enable/disable the associated buttons and adjust
  # input requirements.
  def componentDidUpdate()
    # ICLA file form
    valid = %w(realname pubname email filename).all? do |name|
      document.querySelector("input[name=#{name}]").validity.valid
    end

    # new account request form
    %w(user project votelink).each do |name|
      input = document.querySelector("input[name=#{name}]")
      input.required = @user && !@user.empty?
      valid &= input.validity.valid
    end

    $file.disabled = !valid or @filed or @submitted

    # wire up form
    jQuery('form')[0].addEventListener('submit', self.file)
    jQuery('input[name=message]').val(window.parent.location.pathname)
    jQuery('input[name=selected]').val(@@selected)

    # Safari autocomplete workaround: trigger change on leaving field
    # https://github.com/facebook/react/issues/2125
    if navigator.userAgent.include? "Safari"
      Array(document.getElementsByTagName('input')).each do |input|
        input.addEventListener('blur', self.onblur)
      end
    end
  end

  def changeRealName(event)
    @realname = event.target.value;
    @filename = self.genfilename(event.target.value)
  end

  # generate file name from the real name
  def genfilename(realname)
    return asciize(realname.strip()).downcase().gsub(/\W+/, '-')
  end

  # when leaving an input field, trigger change event (for Safari)
  def onblur(event)
    jQuery(event.target).trigger(:change)
  end

  # handle ICLA form submission
  def file(event)
    setTimeout 0 do
      @submitted = true
      @filed = true
    end
  end

  # validate userid is available
  def validate_userid(event)
    return unless @user and @user != @checked
    input = event.target
    HTTP.post('../../actions/check-id', id: @user).then {|result|
      input.setCustomValidity(result.message)
      @checked = @user
    }.catch {|message|
      alert message
    }
  end

  # when tasks complete (or are aborted) reset form
  def status_update(event)
    @submitted = false
    @filed = false
  end
end
