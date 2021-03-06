#
# Main component, responsible for:
#
#  * Initial loading and polling of the agenda
#
#  * Rendering a Header, a item view, and a Footer
#
#  * Resizing view to leave room for the Header and Footer
#

class Main < React
  # common layout for all pages: header, main, footer, and forms
  def render
    if not @item
      _p 'Not found'
    else

      _Header item: @item

      view = nil
      _main do
        React.createElement(@item.view, item: @item,
         ref: proc {|component| Main.view=component})
      end

      _Footer item: @item, buttons: @buttons, options: @options

      # emit hidden forms associated with the buttons displayed on this page
      if @buttons
        @buttons.each do |button|
          if button.form
            React.createElement(button.form, item: @item, server: Server,
              button: button)
          end
        end
      end
    end
  end

  # initial load of the agenda, and route first request
  def componentWillMount()
    # copy server info for later use
    for prop in @@server
      Server[prop] = @@server[prop]
    end

    Agenda.load(@@page.parsed, @@page.digest)
    Minutes.load(@@page.minutes)

    self.route(@@page.path, @@page.query)

    # free memory
    @@page.parsed = nil
  end

  # encapsulate calls to the router
  def route(path, query)
    route = Router.route(path,query)

    @item = route.item
    @buttons = route.buttons
    @options = route.options

    Main.view = nil unless Main.item and Main.item.view == route.item.view
    Main.item = route.item
  end

  # navigation method that updates history (back button) information
  def navigate(path, query)
    history.state.scrollY = window.scrollY
    history.replaceState(history.state, nil, history.path)
    Main.scrollTo = 0
    self.route(path, query)
    history.pushState({path: path, query: query}, nil, path)
    window.onresize()
  end

  # refresh the current page
  def refresh()
    self.route(history.state.path, history.state.query)
  end

  # dummy exported refresh method (replaced on client side)
  def self.refresh()
  end

  # additional client side initialization
  def componentDidMount()
    # export navigate and refresh methods
    Main.navigate = self.navigate
    Main.refresh  = self.refresh

    # store initial state in history, taking care not to overwrite
    # history set by the Search component.
    if not history.state or not history.state.query
      path = @@page.path

      if path == 'bootstrap.html'
        path = document.location.href
        base = document.getElementsByTagName('base')[0].href
        path = path.slice(base.length) if path.start_with? base
      end

      history.replaceState({path: path}, nil, path)
    end

    # listen for back button, and re-route/re-render when it occcurs
    window.addEventListener :popstate do |event|
      if event.state and defined? event.state.path
        Main.scrollTo = event.state.scrollY || 0
        self.route(event.state.path, event.state.query)
      end
    end

    # start watching keystrokes
    Keyboard.initEventHandlers()

    # whenever the window is resized, adjust margins of the main area to
    # avoid overlapping the header and footer areas
    def window.onresize()
      main = ~'main'
      if 
        window.innerHeight <= 400 and 
        document.body.scrollHeight > window.innerHeight
      then
        document.querySelector('footer').style.position = 'relative'
        document.querySelector('header').style.position = 'relative'
        main.style.marginTop = 0
        main.style.marginBottom = 0
      else
        document.querySelector('footer').style.position = 'fixed'
        document.querySelector('header').style.position = 'fixed'
        main.style.marginTop = "#{~'header.navbar'.clientHeight}px"
        main.style.marginBottom = "#{~'footer.navbar'.clientHeight}px"
      end

      if Main.scrollTo == 0 or Main.scrollTo
        if Main.scrollTo == -1
          jQuery('html, body').
            animate({scrollTop: document.documentElement.scrollHeight}, :fast)
        else
          window.scrollTo(0, Main.scrollTo)
          Main.scrollTo = nil
        end
      end
    end

    # do an initial resize
    Main.scrollTo = 0
    window.onresize()

    # if agenda is stale, fetch immediately; otherwise save etag
    Agenda.fetch(@@page.etag, @@page.digest)

    # start Service Worker
    PageCache.register() if PageCache.enabled
  
    # start backchannel
    Events.monitor()
  end

  # after each subsequent re-rendering, resize main window
  def componentDidUpdate()
    window.onresize()
  end
end
