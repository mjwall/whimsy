#!/usr/bin/env ruby

=begin
APP to generate the correct ezmlm syntax for moderators
=end

require 'wunderbar'

$SAFE = 1

_html do
  _style %{
    textarea, .mod, label {display: block}
    legend {background: #141; color: #DFD; padding: 0.4em}
    .error, ._stderr {color: #F00}
    table { border-collapse: separate; border-spacing: 50px 0; }
  }
  # ensure the generated text is selected ready for copy-pasting
  _script %{
    window.onload=function() {
      var sel = window.getSelection();
      sel.removeAllRanges();
      var range = document.createRange();
      var dest = document.getElementById('dest');
      range.selectNodeContents(dest);
      sel.addRange(range);
      // TODO auto copy to clipboard (tricky)
    }
  }

  _body? do
    _form method: 'post' do
      _fieldset do
        _legend 'Mail Moderation Helper'
        _h3.error do
          _ 'This is a BETA version. ('
          _a "Feedback", href: "mailto:dev@whimsical.apache.org?Subject=Feedback on moderation helper app"
          _ 'welcome.)'
        end
        _p 'This form generates the correct ezmlm mailing list address for various moderator requests.'
        _p do
          _ 'Enter the ASF mailing list name, subscriber email (if needed) and press generate.'
          _br
          _ 'The generated To: address can be copy/pasted into an email, or you may find the link works for you.'
        end
        _table do
          _tr do
            _th 'Mailing list'
            _th 'Subscriber'
          end
          _tr do
            _td do
              _input.name name: 'maillist', size: 40, pattern: '[^@]+@([-\w]+)?', required: true, value: @maillist,
                placeholder: 'user@project or announce@'
              _ '.apache.org '
            end
            _td do
              _input.name name: 'email', size: 40, pattern: '[^@]+@[^@]+', value: @email, placeholder: 'user@domain.example'
            end
          end
          _tr do
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "list", required: true, checked: false
                _ 'list (current subscribers)'
              end
            end
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "subscribe", required: true, checked: false
                _ 'subscribe'
              end              
            end
          end
          _tr do
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "log", required: true, checked: false
                _ 'log (history of changes to the subscribers)'
              end
            end
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "unsubscribe", required: true, checked: true
                _ 'unsubscribe'
              end              
            end
          end
          _tr do
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "allow-list", required: true, checked: false
                _ 'allow-list'
              end
            end
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "allow-subscribe", required: true, checked: false
                _ 'allow-subscribe'
              end              
            end
          end
          _tr do
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "allow-log", required: true, checked: false
                _ 'allow-log'
              end
            end
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "allow-unsubscribe", required: true, checked: false
                _ 'allow-unsubscribe'
              end              
            end
          end
          _tr do
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "deny-list", required: true, checked: false
                _ 'deny-list'
              end
            end
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "deny-subscribe", required: true, checked: false
                _ 'deny-subscribe'
              end              
            end
          end
          _tr do
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "deny-log", required: true, checked: false
                _ 'deny-log'
              end
            end
            _td do
              _label do
                _input type: "radio", name: "cmd", value: "deny-unsubscribe", required: true, checked: false
                _ 'deny-unsubscribe'
              end              
            end
          end
          _tr do
            _td '(the above operate on the list only)'
            _td '(the above require a subscriber email address)'
          end
        end
        _p do
          _ul do
            _li 'subscribers can post and will receive mail'
            _li 'allow-subscribers can post; they do not get copies of mails (this is used for e.g. press@)'
            _li 'deny-subscribers cannot post; their posts will be rejected without needing moderation'
          end
        end
        _input type: 'submit', value: 'Generate'
      end
    end

    if _.post?
      ml0,ml1 = @maillist.split('@')
      if ml1
        ml1 += '.apache.org'
      else
        ml1 = 'apache.org'
      end
      em = @email.split('@')
      _br
      _br
      if @cmd.end_with? 'subscribe' # also catches unsubscribe
        unless @email.length > 0
          _h3.error 'Need subscriber email address'
          break
        end
        dest = "#{ml0}-#{@cmd}-#{em[0]}=#{em[1]}@#{ml1}"
      else
        dest = "#{ml0}-#{@cmd}@#{ml1}"
      end
      _span.dest! dest
      _br
      _br
      _a "Send Mail", href: "mailto:#{dest}?Subject=#{dest}"
    end
  end
end
