{i, p, img, span, a, button, hr, input, iframe, textarea, div, pre, table, tbody, tr, td, ul, li, svg, circle, path} = React.DOM
ReactTransitionGroup = React.addons.TransitionGroup

days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
  'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
]
zpad = (x) -> if x < 10 then '0'+x else ''+x
pretty_date = (d) ->
  if not (d instanceof Date)
    throw new Error("Not a Date")
  h = zpad(d.getHours())
  m = zpad(d.getMinutes())
  M = months[d.getMonth()]
  D = zpad(d.getDate())
  dow = days[d.getDay()]
  suffix = if D < 11 || D > 13
    switch D%10
      when 1 then 'st'
      when 2 then 'nd'
      when 3 then 'rd'
      else 'th'
  else
    'th'
  pretty_d = "#{dow}, #{M} #{D}#{suffix}"
  pretty_t = "#{h}:#{m}"
  return [pretty_d, pretty_t]

data =
  zooms:
    alarm:
      cx: 1245
      cy: 413
      r: 30
    TV:
      cx: 471
      cy: 358
      r: 60
    nest:
      cx: '37.35%'
      cy: '48.5%'
      r: 35
  tv:
    w: 640
    h: 360
    x: -55
    y: -69

Over = React.createClass({
  displayName: 'Over'
  render: ->
    cl =  'overlay '
    if @props.className
      cl += @props.className

    (div className: cl)
})

Nest = React.createClass({
  displayName: 'Nest'
  render: ->
    cl = 'nest-img nest'

    ch = [
      (div key: 'temp', className: 'nest-text nest-temp', @props.temp)
    ]
    if @props.unit
      ch.push(div key: 'unit', className: 'nest-text nest-unit', @props.unit)

    (div
      className: cl
      ch)
})

Clock = React.createClass({
  displayName: 'Clock'
  componentDidMount: ->
    rootNode = @getDOMNode()
    center = (node) ->
      $n = $(node)
      nw = $n.width()
      nh = $n.height()

      l = $n.offset().left - nw/2
      t = $n.offset().top - nh/2

      $n.offset(left: l, top: t)
    # center(rootNode)
  render: ->
    if (d = @props.datetime)
      [pretty_d, pretty_t] = pretty_date(d)

      ch = [
        (div {key: 'al', className: 'clock-alarm'}, "Alarm set at")
        (div {key: 'time', className: 'clock-time'}, pretty_t)
        (div {key: 'date', className: 'clock-date'}, pretty_d)
      ]
    else
      ch = [
        (div key: 'no', className: "clock-nope", "No alarm set")
      ]

    cl = 'clock clock-img'
    (div
      ref: 'clock'
      className: cl
      (div className: 'pebble-screen', ch))
})

TV = React.createClass({
  displayName: 'TV'
  getDefaultProps: ->
    channel: null
  componentDidMount: ->
    rootNode = @getDOMNode()
    # tv
    center = (node) ->
      $n = $(node)
      nw = $n.width()
      nh = $n.height()

      l = $n.offset().left - nw/2
      t = $n.offset().top - nh/2

      $n.offset(left: l, top: t)

    frame_node = @refs['frame'].getDOMNode()
    # center(frame_node)

    if (if_node = @refs['if']?.getDOMNode())
      $(if_node).attr('frameborder', '0')
  componentDidUpdate: (prevProps, prevState) ->
    if (if_node = @refs['if']?.getDOMNode())
      $(if_node).attr('frameborder', '0')
  render: ->
    channels =
      pebble: 'eP9q8Ws6e2o'
      cats: 'J---aiyznGQ'

    if (chan = @props.channel) && (video = channels[chan])
      ch_screen = [(iframe
        id: "ytplayer"
        key: 'if'
        ref: 'if'
        type: "text/html"
        width: "#{data.tv.w}"
        height: "#{data.tv.h}"
        src: "https://www.youtube.com/embed/#{video}?autoplay=1&controls=0&disablekb=1&fs=0&loop=1&modestbranding=1&showinfo=0&html5=1"
      )]
    else
      ch_screen = []

    cl = 'tv-frame'
    (div
      ref: 'frame'
      key: 'frame'
      className: cl
      [
        (div
          ref: 'screen'
          key: 'screen'
          className: 'tv-screen'
          style:
            position: 'relative'
            left:     data.tv.x
            top:      data.tv.y
          ch_screen
        )
      ]
    )
})

rows = _.shuffle [
  ["Turn on all the lights", (intent, entities) ->
    intent == 'lights' && entities?.everywhere?.value == 'true' && entities?.on_off?.value == 'on']
  ["Turn off the lights in the kitchen", (intent, entities) ->
    intent == 'lights' && entities?.room?.value == 'kitchen' && entities?.on_off?.value == 'off']
  ["Set the temperature to 68 degrees", (intent, entities) ->
    intent == 'thermostat_set' && entities?.temperature?.value?.temperature?]
  ["Wake me up at 7 tomorrow morning", (intent, entities) ->
    intent == 'alarm_set' && entities?.datetime?.value]
  ["Turn on the TV", (intent, entities) ->
    intent == 'tv_onoff' && entities?.on_off?.value == 'on']
  ["What time is it in Paris?", (intent, entities) ->
    intent == 'time' && entities?.location?.value == 'Paris']
  ["Tell me the weather in Las Vegas", (intent, entities) ->
    intent == 'weather' && entities?.location?.value]
  ["How is Google doing on the stock market?", (intent, entities) ->
    intent == 'stockprice' && entities?.stock_name?.value]
  ["Close the door", (intent, entities) ->
    intent == 'doors' && (entities?.door_action?.value in ["close", "lock"])]
  ["I want to watch cats", (intent, entities) ->
    intent == 'tv_onoff' && (entities?.tv_channel?.value in ['cats', 'cat'])]
]
CheckList = React.createClass({
  displayName: 'CheckList'
  render: ->
    done = @props.done || []
    j = -1
    row = (body, pred) =>
      cl = if _.some(done, ([x,y]) -> pred(x, y))
        'fa fa-check-circle-o'
      else
        'fa fa-circle-o'
      j++
      (li { key:''+j, className: 'check-row' }, [
        (i key: 'i', className: cl)
        (span key: 's', body)
      ])

    not_done = ([lbl, f]) ->
      !_.some done, ([x, y]) ->
        f(x, y)

    ch = _.chain(rows)
    .filter(not_done)
    .take(4)
    .map(([lbl, f]) -> (row lbl, f))
    .unshift(div key:'try', className: 'try', "Did you try...")
    .value()

    (div {className: 'checklist', key: 'info'}, [
      (ul {key: 'examples', className: 'check-rows'}, ch)
    ])
})

Message = React.createClass({
  displayName: 'Message'
  render: ->
    if @props.msg
      msg = (span key: 'm', @props.msg)
    else
      msg = (CheckList key: 'cl', done: @props.done)

    (ReactTransitionGroup
      transitionName: 'message'
      component: div
      className: 'message-box'
      [
        (pre key: 'm', className: 'msg', msg)
        (div key: 'p', className: 'portrait')
      ])
})

KV = React.createClass({
  displayName: 'KV'
  render: ->
    k   = @props.k
    kl  = k.length
    max_kl = @props.longest_k
    v   = if _.isString(v = @props.v)
      v
    else
      JSON.stringify(v, false, 2)
    pad = ''
    n   = max_kl - kl
    for foobar in [0..n]
      pad += '&nbsp;'

    (div
      className: 'witbox-kv ' + (@props.className || '')
      [
        (span
          className: 'witbox-k'
          # style:
          #   borderColor: @props.color
          k)
        (span dangerouslySetInnerHTML: __html: pad)
        (pre className: 'witbox-v', "= #{v}")
      ])
})

WitBox = React.createClass({
  displayName: 'WitBox'
  render: ->
    intent = @props.intent || 'no intent'
    entities = @props.entities
    longest_k = _.reduce entities, (acc, e, k) ->
      if k && (l = k.length) > acc
        l
      else
        acc
    , 'intent'.length

    ents = _.chain(entities)
    .map((e, k) ->
      (KV k: k, v: e.value, longest_k: longest_k, color: Wit.color(e))
    )
    .unshift(KV k: 'intent', v: intent, longest_k: longest_k)
    .flatten(true)

    ch = [
        # (div className: 'witbox-title', "Wit")
        # (Wit.Tagged
        #   className: 'witbox-tagged'
        #   phrase: "What's the weather tomorrow in Palo Alto?"
        #   tags: entities)
        # (hr className: 'witbox-hr')
        (div
          className: 'witbox-kvs'
          ents)
    ]

    (div
      className: 'witbox bar-item'
      ch)
})

Bar = React.createClass({
  displayName: 'Bar'
  componentDidMount: ->

    # currently, @ws needs these methods ->

    @ws = new WebSocket("ws://localhost:8888")
    @ws.onmessage = (e) ->
      [intent, entities, resp] = JSON.parse(e.data)
      @props.got(intent, entities, resp)

    # rootNode = @getDOMNode()
    # mic
    # node = @refs['mic'].getDOMNode()
    # @ws.onaudiostart = =>
    #   @tooltip('stop')
    #   @props.onAudioStart()
    # @ws.onready = =>
    #   @props.onReady()
    #   @tooltip('start')

    # @ws.onerror = (e, err) =>
    #   @props.onError(e, err)
    # @ws.onresult = (intent, entities, resp) =>
    #   @props.got(intent, entities, resp)
  tooltip: (msg) ->
    body = if msg == 'start'
      'Click here to start (or press Space)'
    else
      'Click here to stop (or press Space)'

    node = @getDOMNode()
    if !node
      console.error("No node for tooltip")
      return

    # cleanup
    if @tooltip_node
      @tooltip_node.tooltip('destroy')

    $n = $(node)
    $n.tooltip
      placement: 'top'
      title: body
      trigger: 'manual'
    $n.tooltip('show')
    @tooltip_node = $n

    if msg == 'stop'
      bs_data = $n.data('bs.tooltip')
      tip = bs_data.tip()
      arrow = bs_data.arrow()
      tip.addClass('tooltip-record')

    # recreate on resize
    $(window).one 'resize', (e) => @tooltip(msg)
  render: ->
    chan = @props.tv_channel
    active = switch @props.active
      when 'alarm'
        (Clock key: 'alarm', datetime: @props.datetime)
      when 'nest'
        (Nest key: 'nest', temp: @props.temp, unit: @props.unit)
      when 'TV'
        (TV key: 'tv', channel: chan && chan.toLowerCase())

    active = if active
      (ReactTransitionGroup
        key: 'active'
        transitionName: 'item'
        component: div
        className: 'active-item'
        active)
    else
      (Message key: 'msg', msg: @props.msg, done: @props.done)

    ur_own = if not active
      (div key: 'own', className: 'own', [
        (a className: 'btn', href: 'https://wit.ai', "Make your own voice interface!")
      ])

    box =
      (WitBox
        key: 'wit'
        intent: @props.intent
        entities: @props.entities)

    ch = _.compact([
      box
      (div key: 'mic', ref: 'mic', className: 'bar-item')
      active
    ])

    (div {className: 'bar'}, ch)
})

Arrow = React.createClass({
  displayName: 'Arrow'
  componentDidMount: ->
    node = @getDOMNode()
    $n = $(node)
    @interval = setInterval =>
      $n.removeClass('wiggle')
      setTimeout -> $n.addClass('wiggle')
    , 3000
  componentWillUnmount: ->
    clearInterval(@interval)
  render: ->
    (div
      className: 'wit-arrow animated wiggle'
      [
        (i className: 'fa fa-long-arrow-up')
      ])
})

Demo = React.createClass({
  displayName: 'Demo'
  getInitialState: ->
    msg: ''
    on_off:
      lights_kitchen: 'off'
      lights_bedroom: 'off'
      lights_office: 'off'
      lights_livingroom: 'off'
    active: null
    tv_channel: null
    alarm_time: null
    nest_temp: 68
    nest_unit: null
    arrow: true
  componentWillMount: (rootNode) ->
    @msg("Welcome to your virtual home. Click on the microphone and speak home automation commands.")
    yes
  handleError: (e, err) ->
    console.log 'error', err

    msgs = switch err.infos?.code
      when "RESULT"
        [
           "I didn't quite catch that ㅠ.ㅠ"
           "Sorry what? ^-^\""
           "Go again? ._."
           "What was that? ^-^\""
        ]
      when "TIMEOUT"
        ["Wit seems to be down..."]
      when "RECORD"
        ["An error occured while recording your voice :<"]
      else
        ["Something went wrong..."]

    idx = _.random(0, msgs.length-1)
    @msg(msgs[idx])
  msg: (msg) ->
    if @msg_t
      clearTimeout(@msg_t)

    @msg_t = setTimeout =>
      @setState(msg: '')
    , 5000

    @setState(msg: msg)
  already: (k, v) ->
    pretty = switch k?.toLowerCase()
      when 'lights_kitchen' then 'The light in the kitchen'
      when 'lights_bathroom' then 'The light in the bathroom'
      when 'lights_bedroom' then 'The light in the bedroom'
      when 'lights_office' then 'The light in the office'
      when 'tv' then 'The TV set'
      when 'alarm' then 'Pebble said the alarm'
      else 'It'

    @msg("#{pretty} is already #{v}!")
  make_active: (k, persistent) ->
    if @active_t
      clearTimeout(@active_t)

    if not persistent
      @active_t = setTimeout =>
        @setState(active: null)
      , 5000

    @setState(active: k)
  reset: (obj) ->
    re = /lights_/
    _.each obj, (v, k) ->
      return if re.test(k)
      obj[k] = 'off'
  got: (intent, entities, resp) ->
    if (f = @[intent])
      if resp.outcome?.confidence && resp.outcome.confidence < 0.2
        return @handleError("Sorry :(", infos: { code: 'RESULT' })

      f.call(@, entities)
      @setState
        done: (@state.done || []).concat([[intent, entities]])
        intent: intent
        entities: entities
    else
      console.log "Unknown intent", intent, entities
      @msg("Your intent is #{intent} but I have not been trained to do that...")
  # entities methods
  need_room: ->
    @msg("Sounds like you forgot to specify a room")
  get_room: (entities) ->
    room_ent = entities?.room
    if (v = room_ent?.value) && (v in ['kitchen', 'bathroom', 'bedroom', 'living room', 'office'])
      if v == 'bathroom'
        v = 'bedroom'
      if v == 'living room'
        v = 'livingroom'

      v
    else
      null
  do_on_off: (val = 'off', desired) ->
    if desired == 'toggle'
      if val == 'off'
        'on'
      else
        'off'
    else
      desired
  on_off: (entities, key, opts = {}) ->
    { room_required, quiet } = opts

    on_off = entities.on_off?.value
    if !(on_off in ['on', 'off', 'toggle'])
      @msg("Say what?") unless quiet
      return

    o_o = _.extend({}, @state.on_off)

    # turn on every room for this key?
    if entities.everywhere?.value == 'true'
      re = new RegExp("^#{key}_")
      _.each o_o, (v, k) =>
        if re.test(k)
          o_o[k] = @do_on_off(o_o[k], on_off)
    else
      if (room = @get_room(entities))
        key += "_#{room}"
      else if room_required
        @need_room() unless quiet
        return

      current = o_o[key]
      new_val = @do_on_off(current, on_off)

      o_o[key] = new_val

      # msg if dummy
      if current == new_val
        @already(key, current) unless quiet

    @setState(on_off: o_o)
    new_val
  handleReady: ->
    if @state.arrow
      @setState(arrow: false)
  render: ->
    O_O = @state.on_off

    svg_ch = _.chain([] || data.zooms)
    .map((v, k) =>
      {cx,cy,r} = v

      sw = 6
      st = '#eee'
      if @state.active == k
        (circle
          key: k
          cx: cx
          cy: cy
          r: r
          fill: 'none'
          strokeWidth: sw
          stroke: st)
    )
    .compact()
    .value()

    re = /^lights_/
    lights_ch = _.chain(O_O)
    .map((v, k) ->
      if (k == 'doors' || re.test(k)) && (v == 'off')
        (Over key: k, className: k)
    )
    .compact()
    .value()

    toggle = (k, intent, entities) =>
      (e) =>
        ents = _.extend(on_off: {value: 'toggle'}, entities)
        @msg('Toggling ' + k)
        @[intent](ents)

    toggle_lights = (room) ->
      k = "lights"
      toggle(k, "lights", room: {value: room})

    toggle_active = (item) ->
      intent = switch item
        when 'nest' then 'thermostat_set'
        when 'alarm' then 'alarm_set'
        when 'TV' then 'tv_onoff'

      toggle(item, intent, {})

    allow_arr = if @state.arrow
      (Arrow {})

    nya = if !@state.arrow
      (a
        key: 'made'
        href: 'https://wit.ai'
        className: 'made-by', [
          (span {key: 'nom', className: 'nom'}, "Powered by Wit.AI")
          (span {key: 'nya', className: 'nya animated'}, " ^~^")])

    blog = if !@state.arrow
      (a
        key: 'blog'
        className: 'blogpost'
        href: 'https://wit.ai/blog'
        [
          "Read our "
          (span className: 'postlink', "blog post")
          " explaining what Wit does"
        ])

    ch = _.chain([
      (Over
        key: 'h'
        className: 'house')
      (ReactTransitionGroup
        key: 'lights'
        transitionName: 'lights'
        component: div
        lights_ch)
      (ReactTransitionGroup
        key: 'svg'
        transitionName: 'svg'
        className: 'svg-canvas overlay'
        component: svg
        svg_ch)
      (Bar
        key: 'b'
        msg: @state.msg
        onError: @handleError
        got: @got
        intent: @state.intent
        entities: @state.entities
        done: @state.done
        active: @state.active
        temp: @state.nest_temp
        unit: @state.nest_unit
        datetime: @state.alarm_time
        onReady: @handleReady
        onAudioStart: =>
          @on_off({ on_off: { value: 'off' } }, 'TV', quiet: true)
        tv_channel: O_O.TV == 'on' && @state.tv_channel)
      (div
        key: 'btns'
        className: 'btns'
        style: { display: 'none' }
        [
          (button
            key: 'n'
            onClick: (toggle_active 'nest')
            'nest')
          (button
            key: 't'
            onClick: (toggle_active 'TV')
            'TV')
          (button
            key: 'a'
            onClick: (toggle_active 'alarm')
            'alarm')
          (button
            key: 'kit'
            onClick: (toggle_lights 'kitchen')
            'kitchen')
          (button
            key: 'br'
            onClick: (toggle_lights 'bedroom')
            'bedroom')
          (button
            key: 'office'
            onClick: (toggle_lights 'office')
            'office')
          (button
            key: 'livingroom'
            onClick: (toggle_lights 'livingroom')
            'livingroom')])
      (p
        key: 'json'
        className: 'json'
        style: { display: 'none' }
        JSON.stringify(_.pick(@state, 'on_off', 'active')))
      nya
      blog
      allow_arr
    ])
    .compact()
    .value()

    (div
      className: 'demo'
      ch)

  ###
   o8o                  .                             .
   `"'                .o8                           .o8
  oooo  ooo. .oo.   .o888oo  .ooooo.  ooo. .oo.   .o888oo  .oooo.o
  `888  `888P"Y88b    888   d88' `88b `888P"Y88b    888   d88(  "8
   888   888   888    888   888ooo888  888   888    888   `"Y88b.
   888   888   888    888 . 888    .o  888   888    888 . o.  )88b
  o888o o888o o888o   "888" `Y8bod8P' o888o o888o   "888" 8""888P'
  ###
  alarm_onoff: (entities) ->
    k = 'alarm'
    @on_off(entities, k)
    @make_active(k)
  alarm_set: (entities) ->
    datetime = entities.datetime?.value?.from

    if not datetime
      @msg("I don't know when to schedule your alarm...")
      return

    d = new Date(datetime)
    [da, ti] = pretty_date(d)
    @msg("I set an alarm at #{ti} on #{da}")
    @make_active('alarm')
    @setState(alarm_time: d)
  blinds: (entities) ->
    @msg("The blinds are fine as they are!")
  doors: (entities) ->
    k = 'doors'
    v = entities?.door_action?.value

    # normalize
    if v in ['unlock', 'open']
      v = 'on'
    else if v in ['lock', 'close']
      v = 'off'

    # take action
    if v == 'on'
      @msg('I opened the door!')
    else if v == 'off'
      @msg('I closed the door!')
    else
      @msg('What about the door?')

    o_o = _.extend {}, @state.on_off
    o_o[k] = v
    @setState(on_off: o_o)
  fans: (entities) ->
    @msg("You're mistaken, there are no fans in this house!")
  greetings_bye: (e) ->
    @msg("Alright, see you later!")
  greetings_hi: (e) ->
    @msg("Howdy!")
  greetings_insult: (e) ->
    @msg("Don't be mean.. I be sad now ㅠ.ㅠ")
  greetings_mood: (e) ->
    @msg("All work and no play makes Wit a dull boy...")
  lights: (entities) ->
    @on_off(entities, 'lights', room_required: true)
  stockprice: (entities) ->
    stock = entities.stock_name?.value
    if not stock
      return @msg("Finance... what stocks are you interested in?")

    @msg("#{stock} you say... Let me look it up...")

    # hack.
    tag = document.createElement('script')
    tag.src = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=#{stock}&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
    window.YAHOO = {
      Finance:
        SymbolSuggest:
          ssCallback: (data) =>
            tag.remove()
            ticker = data.ResultSet?.Result?[0]?.symbol

            if not ticker
              @msg("I don't know any company called #{stock}..!")
              return

            $.ajax
              type: 'GET'
              url: "http://finance.yahoo.com/webservice/v1/symbols/#{ticker}/quote?format=json"
              dataType: 'jsonp'
              error: =>
                console.log 'error', arguments
                @msg("Something went wrong when looking up #{stock} (#{ticker})..!")
              success: (data) =>
                fields = data.list?.resources?[0]?.resource?.fields
                if not fields
                  @msg("I couldn't find info about #{stock} (#{ticker})..!")
                  return

                { name, price, symbol } = fields
                price = parseFloat(price, 10).toFixed(3)
                @msg("#{name} (#{symbol}) stock price is at $#{price} right now")
    }
    document.body.appendChild(tag)
  time: (entities) ->
    loc = entities.location?.value

    f = (d) =>
      [da, ti] = pretty_date(d)

      if loc
        @msg("It is #{ti}, on #{da} in #{loc}")
      else
        @msg("It is #{ti}, on #{da}")

    if !loc
      return f(new Date())

    @msg "The time in #{loc} is... err.. let me think"
    $.ajax
      method: 'GET'
      url: "http://api.geonames.org/searchJSON?q=#{encodeURIComponent(loc)}&username=blandw"
      dataType: 'jsonp'
      error: =>
        @msg "Something went wrong while locating #{loc} ;<"
        console.log arguments
      success: (data) =>
        lat  = data.geonames?[0]?.lat
        lng  = data.geonames?[0]?.lng
        name = data.geonames?[0]?.name

        if !(lat && lng && name)
          return @msg "Couldn't find info about #{loc} ;<"

        $.ajax
          type: 'GET'
          url: "http://api.geonames.org/timezoneJSON?lat=#{lat}&lng=#{lng}&username=blandw"
          dataType: 'jsonp'
          success: (data) =>
            time = data.time
            if not time
              return @msg "Couldn't find the time in #{loc} ;<"

            [_x, y, M, d, h, m] = time.match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
            x = new Date()
            x.setFullYear(y)
            x.setMonth(M-1)
            x.setDate(d)
            x.setHours(h)
            x.setMinutes(m)
            f(x)

  thermostat_set: (entities) ->
    temp = entities.temperature?.value?.temperature

    if not temp
      @msg("What temperature would you like?")
      return

    temp %= 100
    unit = entities.temperature?.value?.unit

    pretty_unit = if not unit
      ''
    else
      ' ' + unit
    @msg("I set the thermostat to #{temp}°#{pretty_unit}")

    @make_active('nest')
    @setState(nest_temp: temp, nest_unit: unit)
  tv_onoff: (entities) ->
    k = 'TV'
    @make_active(k, true)
    new_val = @on_off(entities, k)

    ch = entities.tv_channel?.value || entities.channel?.value
    # normalize
    if ch == 'cat'
      ch = 'cats'

    if new_val == 'on'
      if !(ch in ['pebble', 'cats'])
        ch = 'pebble'
      @msg("I set the TV channel to #{ch}")
    else if new_val == 'off'
      @msg("I turned off the TV!")

    @setState(tv_channel: ch)
  water_plants: (entities) ->
    @msg("I'm a robot, I can't water things!")
  weather: (entities) ->
    loc = entities?.location?.value
    rel = entities?.weather_location_relative?.value

    if !loc && !rel
      rel = 'outside'

    fetch_weather = (url) =>
      @msg("Let me fetch the weather for #{loc}...")

      $.ajax
        type: 'GET'
        url: url
        dataType: 'jsonp'
        error: =>
          console.log 'error', arguments
          return @msg("Something went wrong while fetching weather information...")
        success: (data) =>
          if _.isArray(data.list)
            data = data.list[0]
          else if not data.weather
            return @msg("I couldn't find any weather info for #{loc}...")

          { name, main, weather } = data
          { temp } = main
          { description, icon } = weather?[0]
          icon_url = "http://openweathermap.org/img/w/#{icon}.png"
          temp = Math.round(temp)

          @msg([
            "It is #{temp}ºC in #{name}, with #{description}"
            (img src: icon_url)
          ])

    if rel && rel == 'inside'
      @make_active('nest')
      return

    if rel && rel == 'outside'
      loc = 'your location'
      if not navigator.geolocation
        return @msg("I don't know what your location is")
      else
        navigator.geolocation.getCurrentPosition (pos) =>
          { latitude, longitude } = pos.coords
          url = "http://api.openweathermap.org/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&units=metric&mode=json"
          fetch_weather(url)
    else
      url = "http://api.openweathermap.org/data/2.5/find?q=#{loc}&units=metric&mode=json"
      fetch_weather(url)

    # url = "http://dev.virtualearth.net/REST/v1/Locations?query=#{loc}&includeNeighborhood=false&include=false&maxResults=1&key=AscS64ge2aM2VcsRkB2MMRFam1CJokBO-g7THUSZEEJledKkoPSkOuf09E_hVAnJ"
    # $.ajax
    #   type: 'GET'
    #   url: url
    #   dataType: 'jsonp'
    #   jsonp: 'jsonp'
    #   error: => console.log 'error', arguments
    #   success: (data) =>
    #     console.log  data
    #     coords = data.resourceSets?[0]?.resources?[0]?.geocodePoints?[0]?.coordinates
    #     if not coords
    #       return @msg("Excuse my ignorance, I don't know where #{loc} is...")
    #     [lat, long] = coords
})

$ ->
  React.renderComponent (Demo {}), document.getElementById('demo')
