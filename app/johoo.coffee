### 外部設定 初期化 ###

INIT_FILE = 'app/mid.json'
DOMAIN = ''
bgImageApi = ''
APP_FILE = ''


pmviewer = "";

cache = ''

tileImageExtension = '.jpg'

initialZoomSizeArr = {}

tileWidth = 0
tileHeight = 0

motifWidth = 0
motifHeight = 0

searchApi = ''

tileImageDir = ''
zoomImageDir = ''

indiTwitterText = ''
campTwitterText = ''

snsLinkage = false

commentZoom = false
pinchTrigger = 15
minBlockSize = 1
minZoom = 1
tlImageWidth = 80

nowZoom = minZoom
prevZoom = minZoom
zoomSize = []

blockList = []

###
 *
 * Class PhotomosaicViewer メインクラス
 * 表示別にクラスを分けるようにすること
###
class PhotomosaicViewer extends Backbone.View
  el: '#Johoo'

  initialize:=>
    #環境設定とか
    @uniBrowse = new Browser

    minZoom = initialZoomSizeArr[Browser.device]
    nowZoom = minZoom
    prevZoom = minZoom+1
    css_href = 'css/johoo_'+Browser.device+'.css' + cache

    $("<link/>",
      rel: "stylesheet",
      type: "text/css",
      href: css_href
    ).appendTo $('head')

    @setup("")

  onOrient:=>
    Shadow.setSize()
    #@smallMap.setup()
    @popup.resize()
    $(@el).show()

  openPopupFromId:(_id)=>
    p = 0
    $.getJSON searchApi,{'id':_id},(data,status)=>
      #タップ拡大時に特殊なフラグによって条件分岐するならココ
      ##and "#{data.img}" isnt 'undefined'
      if status and data isnt null
        p = data[0][0].num
        @popup.openPopupFromPoint p
        @marker.setResult p
        @marker.render()
    .fail ->
      console.log 'error:'+status

  openPopupFromTimeline:(_id)=>
    @popup.clear()
    @searchPanel.hide()
    #@smallMap.show()
    Pyramid.show()
    ControlPanel.show()

    nowZoom = arrZoomSizeX.length-2
    prevZoom = arrZoomSizeX.length-3

    @marker.setResult _id
    @marker.render()
    @pyramid.moveToNum _id

  moveToCenterFromNum:(_num)=>
    #@smallMap.show()

    nowZoom = arrZoomSizeX.length-2
    prevZoom = arrZoomSizeX.length-3

    @marker.setResult _num
    @marker.render(500)
    @pyramid.moveToNum _num


    #メイン画面へ戻る
  backtomain:=>
    @searchPanel.hide()
    @pyramid.closePopup()
    @popup.closePopup()
    Pyramid.show()
    ControlPanel.show()
    #検索パネル表示イベント
  showSearchPanel:=>
    @popup.clear()
    @searchPanel.show()
    #@smallMap.hide()
    Pyramid.hide()
    ControlPanel.hide()

  setup:(_init)=>
    #基底モデル
    @smodel = new SModel

    #半透明黒背景クラス
    @shadow = new Shadow

    #フォトモザイク部分
    @pyramid = new Pyramid

    #拡大表示クラス
    @popup = new Popup

    #検索パネルクラス
    @searchPanel = new SearchPanel

    #コンパネ ズームボタン、検索ウィンドウ表示ボタン、ヘルプ表示ボタンとか
    @controlPanel = new ControlPanel

    @blockLoader = new BlockLoader

    #検索位置を示すマーカー
    @marker = new Marker

    if Browser.device isnt 'pc'
      $(window).on "orientationchange", =>
        $(@el).hide()

        setTimeout =>
          Browser.setup()
          @onOrient()
        ,1000
    else
      $(window).on "resize", =>
        $(@el).hide()

        setTimeout =>
          Browser.setup()
          @onOrient()
        ,1000

    #メイン画面へ戻る
    @searchPanel.on 'backtomain', =>
      @router.navigate "",
        trigger: true

    @popup.on 'backtomain', =>
      @router.navigate "",
        trigger: true
    @popup.on 'getCenterNum',(_num) =>
      @moveToCenterFromNum(_num)

    @pyramid.on 'openPopupFromPoint',(_p) =>

      $.getJSON searchApi,{'n':_p},(data,status)=>
        #タップ拡大時に特殊なフラグによって条件分岐するならココ
        if status and data isnt null
          if data[0].id isnt undefined
            p = data[0].num
            @router.navigate "mosaic/n/#{p}/",
              trigger: true

      .fail ->
        console.log 'error:'+status

    #検索パネル表示イベント
    @controlPanel.on 'showSearchPanel', =>
      @router.navigate "search/",
        trigger: true

    #検索位置を示すマーカーを表示
    @pyramid.on 'marker', (e)=>
      @marker.render(e)

    #検索開始イベント
    @searchPanel.on 'startSearch', =>
      @marker.clear()

    #タイムラインクリック時のイベント
    @searchPanel.on 'onclicktimeline',(d) =>
      @router.navigate "timeline/#{d}/",
        trigger: true

    @pyramid.on 'moving',(c) ->
      #@smallMap.setCoords c
    #コンパネイベント
    @controlPanel.on 'change',(h) =>
      @pyramid.update h

    #フォトモザイクを標準位置へセット
    @controlPanel.on 'onclickhomebutton', =>
      nowZoom = minZoom
      prevZoom = minZoom+1
      @pyramid.update()
      @pyramid.pyramidSetPositionToCenter()
      setTimeout =>
        @pyramid.update()
      ,100

    @controlPanel.on 'onclickformbutton', =>
      $.fancybox.open
        type: 'iframe'
        src: 'http://test.pitcom.jp/form/?page=input'
        buttons:['close']
        touch: false

    Browser.setup()
    @onOrient()
    @controlPanel.trigger 'onclickhomebutton'

    ###
    # Router振り分け
    ###
    @router = new Backbone.Router
    @router.route "mosaic/id/:id/", (_id)=> @openPopupFromId(_id)
    @router.route "mosaic/n/:n/", (_n)=>
      @popup.openPopupFromPoint(_n)
      @marker.setResult _n
      @marker.render()
    @router.route "timeline/:id/", (_id)=> @openPopupFromTimeline(_id)
    @router.route "search/", (_p)=> @showSearchPanel()
    @router.route "", => @backtomain()

    Backbone.history.start()

class SmallMap extends Backbone.View
  el: ''
  cursor: '#smallMapCursor'
  image: '#smallMapImage'
  m:4
  dm:1

  initialize:(_el,_url)=>
    @el = _el

    @dm = if Browser.device is 'smartphone' then 1 else 2
    @m = @m/@dm

    $(@el).css
      'overflow':'hidden'
      'background-image':"url('"+_url+"')"
      'background-repeat':'no-repeat'
      'background-size':zoomSize[1][0]/@m+' '+zoomSize[1][1]/@m

    $('<div>').
      attr('id','smallMapCursor').
      appendTo $(@el)

    @setup()

  setup:=>
    @defaultRatio = [@m/zoomSize[1][0],@m/zoomSize[1][1]]

    $(@cursor).css
      width:Browser.width/@m
      position:'relative'
      height:Browser.height/@m
      border:'solid 1px #FF0000'
      zIndex:40
      left:20
      top:50

    $(@el).css
      top:Browser.height-(zoomSize[1][1]/@m)-10
      width:zoomSize[1][0]/@m
      height:zoomSize[1][1]/@m

    @setCoords([Browser.width/2-zoomSize[nowZoom][0]/2,Browser.height/2-zoomSize[nowZoom][1]/2])

  setCoords:(c)=>
    $(@cursor).css
      left:(c[0]/(@m*(zoomSize[nowZoom][0]/zoomSize[1][0])))*-1
      top:(c[1]/(@m*(zoomSize[nowZoom][1]/zoomSize[1][1])))*-1
      width:Browser.width/(@m*(zoomSize[nowZoom][0]/zoomSize[1][0]))
      height:Browser.height/(@m*(zoomSize[nowZoom][1]/zoomSize[1][1]))

  hide:=>
    $(@el).hide()
  show:=>
    $(@el).show()

###*
 * Class SModel 現在はイベント管理のみ
###
class SModel extends Backbone.Model
  setEvent:(_target,_eventname)=>
    @.on _eventname,(_data) =>
      @cEvent(_eventname,_data)

  removeEvent:(_e)=>
    @.off _e

  cEvent:(_event,_data)=>
    @trigger "#{_event}R",_data

class SearchPanel extends Backbone.View
  el: '#SearchPanel'
  searchQuery: ''
  noMoreResult: false
  @timeline: ''

  initialize:=>
    #タイムラインを構築
    @timeline = new Timeline
    @timeline.on 'test', @test
    @timeline.on 'add', @appendTimeline
    @timeline.on 'onclicktimeline', @onclicktimeline

    @searchQuery = new SearchResult
    @loadingStatus = false
    @execSearched = false

    $(@el).hide()

    $.ajax '/assets/html/searchPanel.html',
      datatype: 'html'
    .then @searchpanelloaded
  searchpanelloaded:(data,status)=>
    if status isnt 'success'
      alert "ERROR:検索パネルが読み込めません"
    else
      #置換処理を入れる
      #@@@@@@@@@@@@@
      $(@el).html(data)
    $('#backToMainButton').on 'click', @onBackToMain
    @setup()

  onBackToMain:=>
    @trigger 'backtomain'

  onclicktimeline:(d)=>
    @clear()
    @trigger 'onclicktimeline',d

  appendTimeline:(tile)=>
    timelineChildView = new TimelineChildView model: tile

    $("#searchResult").append timelineChildView.render().el

  setup:=>
    #検索ボタンを有効化
    $('#searchSubmitButton').on 'click', @onTapSubmitButton

    #ボタンリスト(MVCは？)
    deleteValueButtons = []
    $('span.delig').each (i,o)->
      deleteValueButtons.push new DeleteValueButton $(@)
    $('input[type=text]').each (i,o)->
      $(@).on 'keyup', @inputKeyup

    #「続きを読む」を有効化
    $(@el).on 'bottom',@bottom
    list = JSON.parse(Cookies.get("_pit_id"))
    console.log(document.cookie)
    #decodeURIComponent
    new Suggest.LocalMulti("id","suggest",list,{dispMax:10,interval:1000})
    #スクロールされたら自動読み込み。現在凍結中。
    #$(window).scroll =>
    #  if $(document).height() < $(window).scrollTop()+Browser.height+4 and @loadingStatus is false and @execSearched
    #    @loading true
    #    $(@el).trigger 'bottom'
  inputKeyup:(e)=>
    alert e.keyCode
    if e.keyCode is 13
      @onTapSubmitButton()
      $(o).blur()

  bottom:=>
    setTimeout =>
      @sendQuery()
    ,1500

  loading:(bool)=>
    if bool
      $('#loadingAnimation').html('')
      $('#loadingAnimation').append('<img src="img/loadingAnimation.gif">')
      $('#loadingAnimation').height 48
      @loadingStatus = bool
    else
      $('#loadingAnimation').html('')
      if @noMoreResult isnt true
        $('#loadingAnimation').append('<span style="font-size:24px;margin:auto;vertical-align: middle;">タップして続きを見る</span>')
        $('#loadingAnimation').height 48
        $('#loadingAnimation').on 'click', =>
          @loading true
          $(@el).trigger 'bottom'
          $('#loadingAnimation').off()
      else
        $('#loadingAnimation').height 0

      @loadingStatus = bool

  onTapSubmitButton:=>
    $('#searchResultError').html('')

    @noMoreResult = false
    @execSearched = true
    @clear()
    @searchQuery.resetPageCount()
    @sendQuery()

    @trigger 'startSearch'

  sendQuery:=>
    #query = 'uid='+UID+'&'
    query = ''
    @searchQuery.off()
    @searchQuery.on 'return',(result) => @render result
    @searchQuery.on 'error', => @error

    #検索条件整形。とりあえず版に過ぎず、改良の余地あり。設定ファイルから読み込む方式にする事。
    if $('#SearchPanelInnerContents #id').val() isnt undefined
      query += 'id='+$('#SearchPanelInnerContents #id').val().trim()+'&'
    if $('#SearchPanelInnerContents #b1').val() isnt undefined
      query += 'b1='+$('#SearchPanelInnerContents #b1').val().trim()+'&'
    if $('#SearchPanelInnerContents #b2').val() isnt undefined
      query += 'b2='+$('#SearchPanelInnerContents #b2').val().trim()+'&'
    if $('#SearchPanelInnerContents #b3').val() isnt undefined
      query += 'b3='+$('#SearchPanelInnerContents #b3').val().trim()+'&'
    if $('#SearchPanelInnerContents #b4').val() isnt undefined
      query += 'b4='+$('#SearchPanelInnerContents #b4').val().trim()+'&'

    if query isnt '' then query.slice 0,-1

    @searchQuery.sendQuery query

  error:(t)=>
    @noMoreResult = true
    $('#searchResultError').html t

  render:(result)=>
    ERROR = result[1][0].ERROR

    switch ERROR
      when 'TOOMUCHRESULT'
        @error '<br />検索結果が100件を超えました。<br />条件を指定しなおしてください。'

      when 'NOTFOUND'
        @error '<br />検索にヒットしませんでした。'

      when 'NOWORD'
        @error '<br />検索条件を指定してください。'

      else
        TOTAL = result[1][1].TOTAL
        result = result[0]
        $('#searchResultError').html TOTAL+'件ヒットしました。'
        if result.length < 10
          @noMoreResult = true

        if result isnt ""
          for item in result
            tlChild = new TimelineChild
            tlChild.set
              data:item
            @timeline.add tlChild
        else
          alert("「"+value+"」では見つかりませんでした。")

    @loading false

  show:=>
    if $('#searchSubmitButton')[0] isnt undefined
      @clear()
      $.fancybox.open
        src: @el
        type: 'inline'
        buttons: ['close']
        smallBtn: false
        touch: false
        afterClose: =>
          @trigger "backtomain"

      $(@el).show()
      $('input[type=tel]').each =>
        $(@).focus()

    else
      setTimeout =>
        @show()
      ,100

  hide:=>
    $.fancybox.close()

    @execSearched = false
    @loadingStatus = false
    $('#searchResultError').html('')

    $(@el).hide()

  clear:=>
    @execSearched = false
    $('#loadingAnimation').off()
    $('#loadingAnimation').html('')
    @timeline.clear()

class DeleteValueButton extends Backbone.View
  el: ''
  button: ''

  initialize:(_el)=>
    @el = _el

    $('<span>').
      attr('id',@el.children('input').attr('id')+'DelButton').
      appendTo @el

    $('#'+@el.children('input').attr('id')+'DelButton').css {'position':'relative','height':'22px','width':'22px','top':'2px','right':'25px','background-image':'url(img/delval.png)','cursor':'pointer','display':'inline-block','backgroundRepeat':'no-repeat','backgroundPosition':'center'}

    @el.children('input').on 'keyup', =>
      if @el.children('input').val() is '' then $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':0} else $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':1}
    $('#'+@el.children('input').attr('id')+'DelButton').on 'click', =>
      @el.children('input').val('')
      $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':0}
      $('#'+@el.children('input').attr('id')+'DelButton').focus()

    $('#'+@el.children('input').attr('id')+'DelButton').css {'opacity':0}

class Timeline extends Backbone.Collection
  model: TimelineChild

  clear:=>
    @each (tlChild) ->
      tlChild.clear()

class TimelineChild extends Backbone.Model
  defaults:
    data: ''

  initialize:=>
    @on 'onclicktimeline',@onclicktimeline

  clear:=>
    @off
    @destroy
    @view.unrender()

class TimelineChildView extends Backbone.View
  tagName: 'div'
  data: ''

  events:
    "click"  :  "onclicks"
    "tap"  :  "onclicks"

  initialize:=>
    @model.view = @

  #tile描画に必要なhtml情報をreturnする
  render:=>
    item = @model.get 'data'
    @data = item

    # title and message column
    inner = $('<div>').
      attr('class','tlOutline')
    $('<div>').
      attr('class','tlTitle').
      html(item.b1).
      appendTo inner
    $('<div>').
      attr('class','tlMsg').
#forH
#      html(item.b2).
      appendTo inner

    tl = $(@el).
      attr('class','timelineChild').
#forH
      attr('id','timelineChild'+item.id)
    $('<img />')
      .attr('class','tlImg')
      .attr('width',tlImageWidth)
      .attr('src',zoomImageDir+item.img+tileImageExtension)
      .appendTo tl
    inner.
      appendTo tl
    $('<br />').
      attr('class','timelineBR').
      appendTo tl

    @

  unrender:=>
    $(@el).remove()
    $(@el).off()

  onclicks:=>
    @model.trigger 'onclicktimeline',@data.num

class SearchResult extends Backbone.View

  page:1
  linePerPage:30

  sendQuery:(query)=>
    if query isnt ''
      pageQuery = '&page='+@page
    else
      pageQuery = 'page='+@page
    $.ajax searchApi,
      type:"GET"
      data:query+pageQuery
      dataType:"json"
      error: (jqXHR, textStatus, errorThrown) =>
        @trigger 'error'
      success:(data) =>
        @nextPage()
        @queryResult data

  queryResult:(result)=>
    @trigger 'return',result

  resetPageCount:=>
    @page = 1

  nextPage:=> @page++

###*
 * Class Browser 環境設定関連
 * ブラウザチェック、それにあわせた描画領域の設定、アドレスバーを隠す等
 * 完成したらちゃんと書く
###
class Browser extends Backbone.View
  @device: ''
  @bname:''
  @orientation:''
  @os: ''
  @width: 0
  @height: 0
  @orient: 0
  @displayFix: 0
  @browserNameList:[{"name":'chrome'},{"name":'safari'},{"name":'firefox'},{"name":'androidbrowser'},{"name":'opera'}]

  initialize:->
    #デバイスをチェック 縦横サイズ
    Browser.setup()

  @setup:=>
    #iPhone or iPod

    @orientation = if Math.abs(window.orientation == 90) then "h" else "v"

    if navigator.userAgent.match /iPhone/i or navigator.userAgent.match /iPod/i
      Browser.device = 'iphone'

    #iPad
    else if navigator.userAgent.match /iPad/i
      Browser.device = 'ipad'

    #Android Phone
    else if navigator.userAgent.match /Android/i and navigator.userAgent.match /Mobile/i
      Browser.device = 'androidphone'

    #Android Tablet
    else if navigator.userAgent.match /Android/i
      Browser.device = 'androidtablet'

    #PC
    else
      Browser.device = 'pc'

    Browser.width = $(window).width()
    Browser.height = $(window).height()

    #描画範囲を決定
    $('#Pyramid').width Browser.width
    $('#Pyramid').height Browser.height

    #アドレスバーを隠す
    Browser.hideAddressBar()
  @tests:(_var)=>

    for b in @browserNameList
      if _var.toLowerCase().match(new RegExp(b.name))
        return b.name

  #PC以外ならアドレスバーを隠す処理をおこなう
  @hideAddressBar:->
    if Browser.getOS() is 'ios'
      setTimeout scrollTo,100,0,1

  @getDevice:=> @device
  @getOS:=> @os

class Utility
  @type = do ->
    classToType = {}
    for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
      classToType["[object "+name+"]"] = name.toLowerCase()
    (obj) ->
      strType = Object::toString.call(obj)
      classToType[strType] or "object"

  #対角線を求める
  @getDiagonal:(_x,_y)->
    if _x > 0 and _y > 0
      return Math.sqrt(Math.pow(_x,2)+Math.pow(_y,2))
    else
      return false

  #キャッシュ対策用乱数取得
  @getRandom:->
    return Math.floor(Math.random()*10000)
  @upperCase:(str)->
    return str.replace /[a-z]/g, (ch)->
      String.fromCharCode(ch.charCodeAt(0) & ~32)

###
 * Class Pyramidクラス
###
class Pyramid extends Backbone.View
  @outerel: '#Pyramid'

  el: "#Tiles"
  searchHit: ''

  ###
  初期化メソッド
  ###
  initialize:->
    hasTapEvent = =>
      div = document.createElement('div')
      div.setAttribute('ontouchstart', 'return')
      typeof div.ontouchstart is 'function'
    if Browser.device isnt 'pc'
      $(@el).on 'touchstart',@onMouseDown
      $(@el).on 'touchend',@onMouseUp
      $(@el).on 'touchmove',@onMouseMove

      $(@el).on 'gesturestart',@onGestureStart
      $(@el).on 'gesturechange',@onGestureMove
      $(@el).on 'gestureend',@onGestureEnd

    else
      $(@el).on 'mousedown',@onMouseDown
      $(@el).on 'mouseup',@onMouseUp
      $(@el).on 'mousemove',@onMouseMove

    #初期化
    @dragging = false

    @tiles = new Tiles
    @tiles.on 'add', @appendTile

    $(@el).css {'cursor':'-moz-grab'}

    #背景を設定
    $(@el).css
      'background-image':"url('#{bgImageApi}')"
      'background-size':'contain'

    #初期画面を表示
    @update()
    @pyramidSetPositionToCenter()

  @show = ->
    $(@outerel).show()
  @hide = ->
    $(@outerel).hide()

  ###
  マウスイベント関連メソッド群
  ###
  onMouseDown:(e)=>
    cords = Point.getPoint(e)
    Point.lock(e)

    if Point.isLock() is false
      $(@el).css
        transform:"scale(1)"
      e.preventDefault()

      @dragging = true

      if Utility.type(cords[0]) isnt 'array'
        $(@el).css {'cursor':'-moz-grab'}

        @dragStartX = cords[0]
        @dragStartY = cords[1]
        @dragStartLeft = $(@el).position().left
        @dragStartTop = $(@el).position().top
        @dragStartPyramidX = @getPyramidPos()[0]

        @dragStartPyramidY = @getPyramidPos()[1]
      else
        $(@el).css {'cursor':'-moz-grab'}

        @dragStartX = cords[0][0]/2+cords[1][0]/2
        @dragStartY = cords[0][1]/2+cords[1][1]/2
        @dragStartLeft = $(@el).position().left
        @dragStartTop = $(@el).position().top

        @dragStartPyramidX = @getPyramidPos()[0]

        @dragStartPyramidY = @getPyramidPos()[1]

  onMouseUp:(e)=>
    cords = Point.getPoint e

    if cords isnt undefined and Point.isLock() is false
      $(@el).css
        transform:"scale(1)"
      e.preventDefault()
      #e.stopPropagation()
      @dragging = false
      $(@el).css {'cursor':''}

      #マウスの位置がdownとupで変わらない＝単純クリックなら拡大表示実行
      cordx = if Utility.type(cords[0]) isnt 'array' then cords[0] else cords[0][0]
      cordy = if Utility.type(cords[1]) isnt 'array' then cords[1] else cords[0][1]

      if @isSingleTap(@dragStartX,cordx) and @isSingleTap(@dragStartY,cordy)
        #！！なぜか一行でいけないので！！　既に某か開かれていないかチェック
        if not Shadow.isShow() and nowZoom > 3
          $(@el).off 'touchend',@onMouseUp
          @trigger 'openPopupFromPoint',@getNumFromPoint [cords[0],cords[1]]
      else if @isSingleTap(@dragStartX,cordx) and @isSingleTap(@dragStartY,cordy) and @isOnTiles [cords[0][0],cords[0][1]]
        #！！なぜか一行でいけないので！！　既に某か開かれていないかチェック
        if not Shadow.isShow() and nowZoom > 3
          $(@el).off 'touchend',@onMouseUp
          @trigger 'openPopupFromPoint',@getNumFromPoint [cords[0][0],cords[0][1]]
      else
        #フォトモザイクを描画
        @update()

  onMouseMove:(e)=>
    cords = Point.getPoint e

    if cords isnt undefined and Point.isLock() is false
      e.preventDefault()
      if Utility.type(cords[0]) is "number" and @dragging is true
        $(@el).css {'left':@dragStartPyramidX+(@getMousePos(e)[0]-@dragStartX),'top':@dragStartPyramidY+(@getMousePos(e)[1]-@dragStartY)}
        @trigger 'moving',[@dragStartPyramidX+(@getMousePos(e)[0]-@dragStartX),@dragStartPyramidY+(@getMousePos(e)[1]-@dragStartY)]

  onGestureStart:(e)=>
    if Point.isLock() is false
      $(@el).css
        transform:"scale(1)"

  onGestureMove:(e)=>
    if Point.isLock() is false
      localX = @dragStartX-@dragStartLeft
      localY = @dragStartY-@dragStartTop

      dx = (zoomSize[nowZoom][0]-(zoomSize[nowZoom][0]*e.originalEvent.scale))/2
      dx = (dx/e.originalEvent.scale)+(zoomSize[nowZoom][0]-localX)

      dy = (zoomSize[nowZoom][1]-(zoomSize[nowZoom][1]*e.originalEvent.scale))/2
      dy = (dy/e.originalEvent.scale)+(zoomSize[nowZoom][1]-localY)

      $(@el).css
        transform:"scale(#{e.originalEvent.scale}) translate(#{dx}px,#{dy}px)"
        left:(zoomSize[nowZoom][0]-localX)*-1+(@dragStartLeft)
        top:(zoomSize[nowZoom][1]-localY)*-1+(@dragStartTop)

  onGestureEnd:(e)=>
    if Point.isLock() is false
      $(@el).css
        left:@dragStartLeft
        top:@dragStartTop
        transform:"scale(1)"
      #zoomSize
      cnt = 0
      if e.originalEvent.scale > 1
        for item in zoomSize
          if zoomSize[nowZoom][0]*e.originalEvent.scale > item[0] and item[0] isnt ""
          else if item[0] isnt undefined
            break
          cnt++
      else
        for item in zoomSize
          if zoomSize[nowZoom][0]*e.originalEvent.scale < item[0]
            break
          cnt++

      if nowZoom isnt cnt and cnt < zoomSize.length
        prevZoom = nowZoom
        nowZoom = cnt
        @update 'pinchZoom'
      else if cnt > zoomSize.length-1
        prevZoom = nowZoom
        nowZoom = zoomSize.length-2
        @update 'pinchZoom'

  zoomIn:(_z)->
    rate = Math.floor _z/2
    if nowZoom < zoomSize.length-1
      prevZoom = nowZoom
      if nowZoom+rate < zoomSize.length-1
        nowZoom = nowZoom+rate
      else
        nowZoom = zoomSize.length-1

  #ズームアウトボタンが押下された
  zoomOut:(_z)->
    _z = (_z-1)*10
    rate = Math.floor _z/2

    if nowZoom > minZoom
      prevZoom = nowZoom

      if nowZoom-rate > minZoom
        nowZoom = minZoom
      else
        nowZoom = nowZoom+rate

  #与えられた座標がフォトモザイク上であるかどうか調べる
  isOnTiles:(p)=>
    if p[0] >= @getPyramidPos()[0] &&
      p[1]>=@getPyramidPos()[1] &&
      p[0] <=zoomSize[nowZoom][0]+@getPyramidPos()[0] &&
      p[1] <= parseInt(zoomSize[nowZoom][1])+@getPyramidPos()[1]
      then true else false

  isSingleTap:(_a,_b)->
    if _a+3 > _b and _b > _a-3 then true else false

  getNumFromPoint:(p)=>
    xb = Math.floor (p[0]-@getPyramidPos()[0])/arrZoomSizeX[nowZoom]
    yb = Math.round (p[1]-@getPyramidPos()[1]+(arrZoomSizeX[nowZoom]/2))/arrZoomSizeY[nowZoom]
    yb = if yb is 0 or yb is 1 then 0 else yb-1
    xb++

    motifWidth*yb+xb

  ###*
   * 描画範囲調査メソッド
   * もっとスマートに出来たらなぁといつも思う
  ###
  checkActiveTile:=>
    #表示されている範囲の始点と終点のxy座標を調べる
    displayAreaStartX = if @getPyramidPos()[0] > 0 and Browser.width-Math.abs(@getPyramidPos()[0]) > 0 then 0 else Math.abs(@getPyramidPos()[0])
    displayAreaStartY = if @getPyramidPos()[1] > 0 and Browser.height-Math.abs(@getPyramidPos()[1]) > 0 then 0 else Math.abs(@getPyramidPos()[1])
    displayAreaEndX = if @getPyramidPos()[0]+zoomSize[nowZoom][0] > $('#Pyramid').width() then $('#Pyramid').width()-@getPyramidPos()[0] else zoomSize[nowZoom][0]
    displayAreaEndY = if @getPyramidPos()[1]+zoomSize[nowZoom][1] > $('#Pyramid').height() then $('#Pyramid').height()-@getPyramidPos()[1] else zoomSize[nowZoom][1]

    #マイナスはゼロとみなす
    displayAreaEndX = 0 if displayAreaEndX <= 0
    displayAreaEndY = 0 if displayAreaEndY <= 0

    #タイル番号へ
    loadStartX = Math.floor displayAreaStartX/tileWidth
    loadStartY = Math.floor displayAreaStartY/tileHeight
    loadEndX = if Math.floor displayAreaEndX/tileWidth is Math.floor zoomSize[nowZoom][0]/tileWidth then Math.floor(displayAreaEndX/tileWidth)-1 else Math.floor displayAreaEndX/tileWidth
    loadEndY = if Math.floor displayAreaEndY/tileHeight is Math.floor zoomSize[nowZoom][1]/tileHeight then Math.floor(displayAreaEndY/tileHeight)-1 else Math.floor displayAreaEndY/tileHeight

    [loadStartX,loadStartY,loadEndX,loadEndY]

  ###*
   * 描画メソッド
   * @param {startX} Number
   * @param {startY} Number
   * @param {endX} Number
   * @param {endY} Number
  ###
  render:(t)=>
    x = t[0]
    y = t[1]
    x2 = t[2]
    y2 = t[3]

    @tiles.removeAllTiles()
    while y <= t[3]
      while x <= t[2]
        #一応重複チェック
        if not @tiles.isSameTile nowZoom,x,y
          tile = new Tile
          tile.set
            x:x
            y:y
            z:nowZoom
            display:true
          @tiles.add tile
        x++
      y++
      x=t[0]
    y = t[1]

  ###*
   * イベントコールバック用 ズームサイズ
  ###
  update:(h)=>
    #表示位置分岐
    switch h
      when 'zoomIn'
        pos = @moveToZoomInPos()
        $(@el).find('img').hide()
        $(@el).animate({
            left:pos[0]
            top:pos[1]
            width:zoomSize[nowZoom][0]
            height:zoomSize[nowZoom][1]
          },200,@animateComplete
        )
        @trigger 'marker',200
      when 'zoomOut'
        $(@el).find('img').hide()
        pos = @moveToZoomOutPos()
        $(@el).animate({
            left:pos[0]
            top:pos[1]
            width:zoomSize[nowZoom][0]
            height:zoomSize[nowZoom][1]
          },200,@animateComplete
        )
        @trigger 'marker',200
      when 'pinchZoom'
        $(@el).find('img').hide()
        pos = @moveToPinchZoomPos()
#        $(@el).animate({
        $(@el).css({
          left:pos[0]
          top:pos[1]
          width:zoomSize[nowZoom][0]
          height:zoomSize[nowZoom][1]
        })
#          },200,@animateComplete
#        )
        @trigger 'marker',200
      else
        @render @checkActiveTile()
  animateComplete:=>
    $(@el).find('img').show()
    @render @checkActiveTile()

#    $(@el).width zoomSize[nowZoom][0]
#    $(@el).height zoomSize[nowZoom][1]
#    @render @checkActiveTile()

  ###*
   * Pyramidを指定numにあわせて移動させるメソッド
  ###
  moveToNum:(d)=>
    if d%motifWidth is 0
      tx = motifWidth*arrZoomSizeX[nowZoom]*-1
      ty = Math.floor((d/motifWidth)-1)*arrZoomSizeX[nowZoom]*-1
    else
      tx = d%motifWidth*arrZoomSizeX[nowZoom]*-1
      ty = Math.floor(d/motifWidth)*arrZoomSizeY[nowZoom]*-1

#    $(@el).css
#      left:(Browser.width/2)+tx+arrZoomSizeX[nowZoom]/2
#      top:(Browser.height/2)+ty-arrZoomSizeY[nowZoom]/2
    $(@el).animate({
      left:(Browser.width/2)+tx+arrZoomSizeX[nowZoom]/2
      top:(Browser.height/2)+ty-arrZoomSizeY[nowZoom]/2
    },200)
    setTimeout =>
      @update ''
    ,500

    @trigger 'moving',[(Browser.width/2)+tx+arrZoomSizeX[nowZoom]/2,(Browser.height/2)+ty-arrZoomSizeY[nowZoom]/2]

  moveToPinchZoomPos:=>
    if @dragStartTop isnt undefined and @dragStartLeft isnt undefined
#      $(@el).css
#        left:@dragStartLeft-((@dragStartX-@dragStartLeft)*(Math.pow(2,nowZoom-prevZoom)-1))
#        top:@dragStartTop-((@dragStartY-@dragStartTop)*(Math.pow(2,nowZoom-prevZoom)-1))
      pos = [
        @dragStartLeft-((@dragStartX-@dragStartLeft)*(Math.pow(2,nowZoom-prevZoom)-1)),
        @dragStartTop-((@dragStartY-@dragStartTop)*(Math.pow(2,nowZoom-prevZoom)-1))
      ]
#      @trigger 'moving',[$(@el).position().left,$(@el).position().top]

  moveToZoomInPos:=>
    pyramidPos = @convertToGrobalCenterPos $(@el).position().left,$(@el).position().top

    if nowZoom is zoomSize.length-1 and commentZoom is true
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0],pyramidPos[1]
    else
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0]*2,pyramidPos[1]*2

#    $(@el).css
#      left:newPyramidPos[0]
#      top:newPyramidPos[1]
    #to createjs
#    $(@el).animate({
#      left:newPyramidPos[0]
#      top:newPyramidPos[1]
#    })
    #@trigger 'moving',[newPyramidPos[0],newPyramidPos[1]]
    newPyramidPos

  moveToZoomOutPos:=>
    pyramidPos = @convertToGrobalCenterPos $(@el).position().left,$(@el).position().top

    if prevZoom isnt 8
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0]/2,pyramidPos[1]/2
    else if prevZoom is 8
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0],pyramidPos[1]
    else
      newPyramidPos = @convertToLocalCenterPos pyramidPos[0]/2,pyramidPos[1]/2

#    $(@el).css
#      left:newPyramidPos[0]
#      top:newPyramidPos[1]
#    $(@el).animate({
#      left:newPyramidPos[0]
#      top:newPyramidPos[1]
#    })
#    @trigger 'moving',[newPyramidPos[0],newPyramidPos[1]]
    newPyramidPos

  ###*
   * 座標コンバーター
  ###
  convertToGrobalCenterPos:(_x,_y)->
    if nowZoom isnt 1 or prevZoom is zoomSize.length-1
      prevPyramidWidth = zoomSize[prevZoom][0]
      prevPyramidHeight = zoomSize[prevZoom][1]
    else
      prevPyramidWidth = zoomSize[prevZoom][0]
      prevPyramidHeight = zoomSize[prevZoom][1]

    x = (_x+prevPyramidWidth/2)-Browser.width/2
    y = (_y+prevPyramidHeight/2)-Browser.height/2

    [x,y]

  ###*
   * 座標コンバーター2
  ###
  convertToLocalCenterPos:(_x,_y)->
    nowPyramidWidth =  zoomSize[nowZoom][0]
    nowPyramidHeight =  zoomSize[nowZoom][1]

    x =  _x-nowPyramidWidth/2+Browser.width/2
    y =  _y-nowPyramidHeight/2+Browser.height/2

    [x,y]

  ###
   * addイベントのコールバックメソッド
   * 原則としてcollectionへonする事
   * @param {tile} Tile
  ###
  appendTile:(tile)=>
    tileView = new TileView model: tile
    $(@el).append tileView.render().el

  ###
  Pyramid位置操作メソッド群
  ###
  #中央寄せ処理
  pyramidSetPositionToCenter:=>
    $(@el).css
      left:Browser.width/2-zoomSize[nowZoom][0]/2
      top:Browser.height/2-zoomSize[nowZoom][1]/2
      width:zoomSize[nowZoom][0]
      height:zoomSize[nowZoom][1]

    @trigger 'moving',[Browser.width/2-zoomSize[nowZoom][0]/2,Browser.height/2-zoomSize[nowZoom][1]/2]

  ###
   * 位置取得メソッド群
   * 基本はreturnする簡単なお仕事
   * @param {e} Event
  ###
  getMousePos:(e)->
    cords = Point.getPoint(e)
    [cords[0],cords[1]]

  getPyramidPos:=>
    [$(@el).position().left,$(@el).position().top]
  closePopup:=>
    $(@el).on 'touchend',@onMouseUp

class Marker extends Backbone.View
  result: ''

  initialize:=>
    weight = if Math.floor(nowZoom/2) < 1 then 1 else Math.floor(nowZoom/2)
    $('#Marker').animate({
      width:arrZoomSizeX[nowZoom]-(2*weight)
      height:arrZoomSizeY[nowZoom]-(2*weight)
    },0)

  clear:=>
    @result = ''
    $('#Marker').remove()

  setResult:(num)=>
    @result = num

  render:(_t)=>
    if _t is undefined
      _t = 200
    if @result isnt ''
#      $('#Marker').remove()

      tx = (@result%motifWidth-1)*arrZoomSizeX[nowZoom]
      ty = Math.floor(@result/motifWidth)*arrZoomSizeY[nowZoom]

      if this.result%motifWidth is 0
        tx = (motifWidth-1)*arrZoomSizeX[nowZoom]
        ty = Math.floor((this.result/motifWidth)-1)*arrZoomSizeX[nowZoom]
      else
        tx = (this.result%motifWidth-1)*arrZoomSizeY[nowZoom]
        ty = Math.floor(this.result/motifWidth)*arrZoomSizeY[nowZoom]

      if tx < 0
        tx = 0


      $('<div />').
        attr('id','Marker').
        appendTo $('#Tiles')

      weight = if Math.floor(nowZoom/2) < 1 then 1 else Math.floor(nowZoom/2)

      #marker!
      $('#Marker').animate({
        left:tx
        top:ty
        width:arrZoomSizeX[nowZoom]-(2*weight)
        height:arrZoomSizeY[nowZoom]-(2*weight)
      },_t)

      $('#Marker').css
        zIndex:3000
#        width:arrZoomSizeX[nowZoom]-(2*weight)
#        height:arrZoomSizeY[nowZoom]-(2*weight)
#        left:tx
#        top:ty
        border:'solid '+weight+'px #FF0000'
        'background-color':'rgba(255,0,0,0.4)'

      setTimeout =>
        @swap()
      ,1000

  swap:->
    $('#Marker').css {'zIndex':3000}

###*
 * Tileクラス
 * Tile画像に必要な情報のみ保持するModelクラス
 * @param {x} Number
 * @param {y} Number
 * @param {z} Number
 * @param {display} Boolean
###
class Tile extends Backbone.Model
  defaults:
    x:0
    y:0
    z:0
    display:false
  clear:=>
    @destroy
    @view.unrender()

###*
 * Class TileViewクラス Tile画像を描画したり削除する役割のみ
###
class TileView extends Backbone.View
  tagName: 'img'
  initialize:->
    @model.view = @

  #tile描画に必要なhtml情報をreturnする
  render: =>
    x = @model.get 'x'
    y = @model.get 'y'
    z = @model.get 'z'
    url = "#{tileImageDir}#{z}/#{y}/z#{z}x#{x}y#{y}#{tileImageExtension}" + cache

    $(@el).
      attr({id:'z'+z+'x'+x+'y'+y,src:url}).
      css({'position':'absolute','left':x*tileWidth,'top':y*tileHeight})
      .on 'load', ->
    @
  loadTile: ->


  unrender:=>
    $(@el).remove()

###*
 * Class Tiles Tileクラスを管理する役割。描画に関してのイベント管理とか。イベントの割り当ては原則、Pyramidクラスで行う
###
class Tiles extends Backbone.Collection
  model: Tile

  initialize:->

  isSameTile:(_z,_x,_y)=>
    data = []
    @each (tile) ->
      data.push tile
    for item in data
      if "#{item.get 'z'} #{item.get 'x'} #{item.get 'y'}" is "#{_z} #{_x} #{_y}"
        res = true
      else
        res = false
    res

  getNowVisibleList:=>
    data = []
    @each (tile) ->
      data.push tile
    data

  setRemove:=>
    data = []
    @each (tile) ->
      data.push tile

  removeCheckedTiles:->
    for tile in data
      if tile.get 'display' != true
        tile.clear()

  removeAllTiles:=>
    @each (tile) ->
      tile.clear()

###*
 * Class ControlPanel コンパネに表示するボタンとか管理
###
class ControlPanel extends Backbone.View
  @el: '#ControlPanel'

  initialize:=>
    #_.onAll @

    #ズームインボタン
    zoomInButton = new ClickOnlyButton {'el':'#ZoomInButton'}
    zoomInButton.on 'change',@zoomIn

    #ズームアウトボタン
    zoomOutButton = new ClickOnlyButton {'el':'#ZoomOutButton'}
    zoomOutButton.on 'change',@zoomOut

    #検索パネル表示ボタン
    showSearchPanelButton = new ClickOnlyButton {'el':'#SearchPanelButton'}
    showSearchPanelButton.on 'change',@showSearchPanel

    #タイムラインパネル表示ボタン
    showHomeButton = new ClickOnlyButton {'el':'#HomeButton'}
    showHomeButton.on 'change',@onclickhomebutton

    #タイムラインパネル表示ボタン
    showFormButton = new ClickOnlyButton {'el':'#FormButton'}
    showFormButton.on 'change',@onclickformbutton


  #ズームインボタンが押下された
  zoomIn:=>
    if nowZoom < zoomSize.length-1
      prevZoom = nowZoom
      nowZoom++
      @trigger 'change','zoomIn'

  #ズームアウトボタンが押下された
  zoomOut:=>
    if nowZoom > minZoom
      prevZoom = nowZoom
      nowZoom--
      @trigger 'change','zoomOut'

  #検索パネル表示ボタンが押下された
  showSearchPanel:=>
    @trigger 'showSearchPanel'

  #タイムラインパネル表示ボタンが押下された
  onclickhomebutton:=>
    @trigger 'onclickhomebutton'

  #投稿ボタンが押下された
  onclickformbutton:=>
    @trigger 'onclickformbutton'


  @show:=> $(@el).show()
  @hide:=> $(@el).hide()

#いまのところいらない子
class ControlPanelModel extends Backbone.Model

###*
 * Class ClickOnlyButton 汎用ボタンクラス。クラス名はちょっと考えたい。
 * @param div 描画用DOM
###
class ClickOnlyButton extends Backbone.View
  el: ''

  initialize:(_obj)=>
    #_.onAll @
    el = _obj.el
    $(@el).off()

    if Browser.device isnt 'pc'
      $(@el).on "touchend",@onMouseUp
    else
      $(@el).on "mouseup",@onMouseUp

  onMouseUp:(e)=>
    e.preventDefault()
    @trigger 'change'

  destroy:=>
    $(@el).off()
    $(@el).remove()

###*
 * Class Point イベントオブジェクトを受け取って座標を返すクラス。デバイス・ブラウザ問わずが基本思想
 * @param event マウスイベントオブジェクト
###
class Point
  @locked: false
  @plock:0

  @lock:(e)=>
    if e.originalEvent.touches isnt undefined
      if e.originalEvent.touches.length > 2 and @plock < 3
        @locked = true
      else
        @locked = false
      @plock = e.originalEvent.touches.length
    else
      @locked = false
      @plock = 1
  @isLock:=>
    @locked
  #座標を取得
  @getPoint:(e)->
    if Point.isTouch(e)
      #SP or Tab
      #for Single Touch
      if e.originalEvent.touches.length is 1
        #座標をかえす
        [e.originalEvent.touches[0].pageX,e.originalEvent.touches[0].pageY]

      #for Multi Touch
      else if e.originalEvent.touches.length > 1
        cords = []
        ftime = false
        for item in e.originalEvent.touches
          if item.pageX > hx and ftime is true
            hx = item.pageX
          else if ftime is false
            hx = item.pageX
          if item.pageX < lx and ftime is true
            lx = item.pageX
          else if ftime is false
            lx = item.pageX
          if item.pageY > hy and ftime is true
            hy = item.pageY
          else if ftime is false
            hy = item.pageY
          if item.pageY < ly and ftime is true
            ly = item.pageY
          else if ftime is false
            ly = item.pageY

          ftime = true
        #座標をかえす
        cords.push [hx,hy]
        cords.push [lx,ly]
        cords
      else
        [e.originalEvent.changedTouches[0].pageX,e.originalEvent.changedTouches[0].pageY]
    else
      #PC
      #座標をかえす
      [e.pageX,e.pageY]

  #タッチされている
  @isTouch:(e)-> e.originalEvent.touches
#テンポラリクラス
class Shadow extends Backbone.View
  @el: '#Shadow'

  @show:=>
    Shadow.setSize()
    $(@el).show()

  @hide:=>
    Shadow.setSize()
    $(@el).hide()

  resize:-> Shadow.setSize()

  @setSize:=>
    $(@el).width Browser.width
    $(@el).height Browser.height

  @setFullSize:(_h)=>
    $(@el).width Browser.width
    if Browser.height >_h+20
      $(@el).height Browser.height
    else
      $(@el).height $(@el).height _h+20

  @isShow:=>
    res = $(@el).css 'display'
    if res is 'none' then false else true

class Blocks extends Backbone.Collection
  model: Block

  initialize:->

  getNowVisibleList:=>
    data = []
    @each (tile) ->
      data.push tile
    data

  setRemove:=>
    data = []
    @each (tile) ->
      data.push tile

  removeCheckedTiles:->
    for tile in data
      if tile.get 'display' != true
        tile.clear()

  removeAllTiles:=>
    @each (tile) ->
      tile.clear()

class Block extends Backbone.Model
  defaults:
    url:''
    pos:0
    image:null
    id:0
    num:null
    fill: "#FF0000"
    x:0
    y:0
  get:(_attr)=>
    @attributes[_attr]
  next:=>
    @attributes["bid"]--
  prev:=>
    @attributes["bid"]++
  clear:=>
    @destroy

class BlockView extends Backbone.View
  el: null
  model: null
  base: null
  image: null

  initialize:(args)->
    @model = args.model
    @el = new createjs.Container()
    @base = new createjs.Shape()
    @base.graphics
      .beginFill(@model.get("fill"))
      .drawRect(0,0,@model.get("width"),@model.get("height"))
    @image = new createjs.Bitmap(@model.get("image"))

    @base.x=@model.get("x")
    @base.y=@model.get("y")
    @base.alpha = 0.5
    @el.addChild @base
    @el.addChild @image

    @image.x=@model.get("x")
    @image.y=@model.get("y")
  #tile描画に必要なhtml情報をreturnする
  render:=>
    @el
  clear:=>
    @el.removeChild @base
    @el.removeChild @model.get("image")
    @model.clear()
#    x = @model.get 'x'
#    y = @model.get 'y'
#    z = @model.get 'z'
 #   url = "#{tileImageDir}#{z}/#{y}/z#{z}x#{x}y#{y}#{tileImageExtension}" + cache

 #   $(@el).
 #     attr({id:'z'+z+'x'+x+'y'+y,src:url}).
 #     css({'position':'absolute','left':x*tileWidth,'top':y*tileHeight})
 #     .on 'load', ->
 #   @
 # loadTile: ->


#  unrender:=>
#    $(@el).remove()

class BlockLayout extends Backbone.View
  maxBlock: 7
  base: 
    x:(320/2)-(tileWidth/2)
    y:320/2
  blockList: []

  blockLayout: []

  initialize:=>
    @blockLayout = [{
      x:(320/2)-(tileWidth/2)-(256*3)*0.9-5
      y:(tileHeight-(256*0.9))/2
      scale:0.9
    },
    {
      x:(320/2)-(tileWidth/2)-(256*2)*0.9-5
      y:(tileHeight-(256*0.9))/2
      scale:0.9
    },
    {
      x:(320/2)-(tileWidth/2)-(256*0.9)-5
      y:(tileHeight-(256*0.9))/2
      scale:0.9
    },
    {
      x:(320/2)-(tileWidth/2)
      y:0
      scale:1
    },
    {
      x:(320/2)-(tileWidth/2)+256+5
      y:(tileHeight-(256*0.9))/2
      scale:0.9
    },
    {
      x:(320/2)-(tileWidth/2)+(256*2)+5
      y:(tileHeight-(256*0.9))/2
      scale:0.9
    },
    {
      x:(320/2)-(tileWidth/2)+(256*3)+5
      y:(tileHeight-(256*0.9))/2
      scale:0.9
    }]
  setLayout:(_list)=>
    for item in _list
      bid = item.model.get("bid")
      createjs.Tween.get(item.el,{loop:false},true)
        .to({
          x:@blockLayout[bid].x
          y:@blockLayout[bid].y
          scaleX:@blockLayout[bid].scale
          scaleY:@blockLayout[bid].scale
        },0)
  changeLayout:(_move)=>
    console.log 'changeLayout'
    for item in blockList
      bid = item.model.get("bid")
      num = item.model.get("num")
      if _move is "next"
        bid--
      else
        bid++

      if @blockLayout[bid] isnt undefined
        createjs.Tween.get(item.el,{loop:false},true)
          .to({
            x:@blockLayout[bid].x,scaleX:@blockLayout[bid].scale,scaleY:@blockLayout[bid].scale,
            y:(tileHeight-(item.model.get("height")*@blockLayout[bid].scale))/2
          },500,createjs.Ease.cubicIn)

  isNextBlockExists:=>
    for item in blockList
      bid = item.model.get("bid")
      if item.model.get("bid") == 4
        return true
    return false
  next:=>
    for item in blockList
      @changeLayout('next')
      item.model.next()
    @trigger 'layoutchanged','next'

  isPrevBlockExists:=>
    for item in blockList
      bid = item.model.get("bid")
      if item.model.get("bid") == 2
        return true
    return false

  prev:=>
    for item in blockList
      @changeLayout('prev')
      item.model.prev()
    @trigger 'layoutchanged','prev'
  loadPrevBlock:=>
    i=0
    dellist = []
    for item in blockList
      bid = item.model.get("bid")
      if bid > 6
        dellist.push i
      i++
    dellist.sort(
      (a,b)=>
        if(a > b) then return -1
        if(a < b) then return 1
        return 0
    )
    for i in dellist
      d = blockList.splice i,1
      @trigger "blockclear",{block:d[0],list:dellist}
      d[0].clear()
    @trigger "reload",'prev'
    @
  loadNextBlock:=>
    i=0
    dellist = []
    for item in blockList
      bid = item.model.get("bid")
      if bid < 0
        dellist.push i
      i++
    dellist.sort(
      (a,b)=>
        if(a > b) then return -1
        if(a < b) then return 1
        return 0
    )
    for i in dellist
      d = blockList.splice i,1
      @trigger "blockclear",{block:d[0],list:dellist}
      d[0].clear()
    @trigger "reload",'next'
    @

class BlockLoader extends Backbone.View
  initialize:=>


class ImageViewer extends Backbone.View
  el:'#imageViewer'
  stage: null
  container: null
  swipeMc: null
  width: 320
  height: 320
  num: 3
  loader: null
  imageList: []
  blockList: []
  nextButton: null
  prevButton: null
  blocklayout: null
  swipeObj:{}
  position:0
  direction:''
  vector:''

  initialize:=>
    # デフォルト値から環境別の値へ変更
#    @width = Browser.width-40
#    @height = Browser.height
    imageList = []
    @stage = new createjs.Stage('imageViewer')
    if createjs.Touch.isSupported()
      createjs.Touch.enable(@stage)
    @stage.canvas.width = @width
    @stage.canvas.height = @height
    wrap = new createjs.Container()
    @stage.addChild(wrap)

    @blocklayout = new BlockLayout()
    @blocklayout.on "blockclear",@blockclear
    @blocklayout.on "reload",@reload
    @blocklayout.on "layoutchanged",@layoutchanged

    @container = new createjs.Container()
    wrap.addChild(@container)

    @swipeMc = new createjs.Shape().set({x:30,y:0})
    @swipeMc.graphics.f("#fff").dr(0,0,256,256)
    wrap.addChild(@swipeMc)
    @swipeMc.alpha = 0.01

    @swipeMc.addEventListener("touchstart",@touchstart)
    @swipeMc.addEventListener("touchmove",@touchmove)
    @swipeMc.addEventListener("touchend",@touchend)

    @swipeMc.addEventListener("mousedown",@touchstart)
    @swipeMc.addEventListener("pressmove",@touchmove)
    @swipeMc.addEventListener("pressup",@touchend)
#        'touchstart mousedown': (e)=>
#            e.preventDefault()
#            console.log 'touchstart mousedown'+e.pageX
#        'touchmove mousemove': (e)=>
#            e.preventDefault()
#            console.log 'touchmove mousemove'+e.pageX
#        'touchend mouseup': (e)=>
#            e.preventDefault()
#            console.log 'touchend mouseup'+e.pageX


    @loader = new createjs.LoadQueue()
#    @loader.setMaxConnections(1)
    @loader.on("error",@loadError)
    @loader.on("fileload",@loadFile)
    @loader.on("complete",@loadComplete)

    @addButtons()

    @stage
  touchstart:(e)=>
  	console.log 'touchstart'
  	@position = @getPosition(e)
  	@direction =''
  touchmove:(e)=>
    if (@position - @getPosition(e) > 70)
      @direction = 'left'
    else if (@position - @getPosition(e) < -70)
      @direction = 'right'
  touchend:(e)=>
    if (@direction == 'right')
      @prev()
    else if (@direction == 'left')
      @next()
  getPosition:(e)=>
  	e.stageX

  setList:(_objs)=>
    @loader.loadManifest(_objs)
#    @loader.load()
  addList:(_obj)=>
    ret = []
    for item in _obj
      item.data = item
      item.src = 'swfData/blockimg/'+item.data["img"]+'.jpg'
#      item.src = 'api/getBlockImage.php?blockimg='+item.data["img"]
      item.type = createjs.LoadQueue.IMAGE
      ret.push item
    @loader.loadManifest(ret)
#    @loader.load()
  loadFile:(evt)=>
    @imageList.push {
        bid: evt.item.bid
        num: evt.item.num
        image: evt.result
      }
  loadError:(err)=>
    console.log 'error'+err
  loadComplete:(evt)=>
    for obj in @imageList
      obj["width"]  = tileWidth
      obj["height"] = tileHeight
      obj["bid"] = Number(obj.bid)
      obj["num"] = Number(obj.num)
      obj["image"] = obj.image

      bm = new Block(obj)
      bv = new BlockView model: bm
      blockList.push bv
      @container.addChild bv.render()
    @blocklayout.setLayout(blockList)

    @render()
    @imageList = []
    console.log 'stat'
    setTimeout =>
      @buttonon()
      @animateComplete()
    ,200
  animateComplete:=>
    console.log 'stat2'
    if(@vector == 'next')
      @next()
      @vector = ''
    if(@vector == 'prev')
      @prev()
      @vector = ''

  getCenterNum:=>
    for b in blockList
      bid = b.model.get("bid")
      num = b.model.get("num")
      if bid == 3 then return num
  blockclear:(obj)=>
    #コンテナからブロック画像を、配列から要素を削除
    block = obj.block
    dellist = obj.list

    @container.removeChild(block.render())

    #ボタンの無効化
    @buttonoff()
  reload:(_vector)=>
    @vector = _vector

    for b in blockList
#      b3 = 466
      num = b.model.get("num")
      bid = b.model.get("bid")
      if bid is 3 then b3 = num
    if @vector is 'next'
      $.getJSON searchApi,{'n':b3,'request':'4,5,6','base':3},(data,status)=>
        @addList(data)
    else
      $.getJSON searchApi,{'n':b3,'request':'0,1,2','base':3},(data,status)=>
        @addList(data)
    #次配列のロード
#    $.getJSON searchApi,{'n':data.num,'request':'0,1,2,4,5,6','base':3},(data,status)=>
#      @imageviewer.addList(data)

  addButtons:=>

    @nextButton = @createButton("▶")
    @nextButton.x = 292
    @stage.addChild(@nextButton)

    @prevButton = @createButton("◀")
    @stage.addChild(@prevButton)

    @buttonon()

    @
  buttonon:=>
    @prevButton.addEventListener('click',@prev,false)
    @nextButton.addEventListener('click',@next,false)

  
    createjs.Tween.removeTweens(@prevButton)
    createjs.Tween.removeTweens(@nextButton)
    createjs.Tween.get(@prevButton,{loop:false},true)
      .to({alpha:1},500)
    createjs.Tween.get(@nextButton,{loop:false},true)
      .to({alpha:1},500)

  buttonoff:=>
    @prevButton.removeEventListener('click',@prev)
    @nextButton.removeEventListener('click',@next)


    createjs.Tween.removeTweens(@prevButton)
    createjs.Tween.removeTweens(@nextButton)
    createjs.Tween.get(@prevButton,{loop:false},true)
      .to({alpha:0.3},200)
    createjs.Tween.get(@nextButton,{loop:false},true)
      .to({alpha:0.3},200)

  #キーボード操作用メソッド
  key:(code)=>
    switch code.which
      when 37
        @prev()
      when 39
        @next()

  prev:=>
    if @blocklayout.isPrevBlockExists()
      @blocklayout.prev() 
    else
      @blocklayout.loadPrevBlock()
      @buttonoff()

  next:=>
    if @blocklayout.isNextBlockExists()
      @blocklayout.next()
    else
      @blocklayout.loadNextBlock()
      @buttonoff()

  layoutchanged:(_move)=>
    @trigger 'load'+_move
  createButton:(_label)=>
    btn = new createjs.Container()
    btnBg = new createjs.Shape()
    btnBg.graphics.beginFill("black").drawRoundRect(0, 13, 28, 230, 0, 0);
    btnBg.alpha=0.2
    btn.addChild(btnBg)
    btnLabel = new createjs.Text(_label, "24px sans-serif", "white")
    btnLabel.textAlign = "center"
    btnLabel.textBaseline = "middle"
    btnLabel.shadow = new createjs.Shadow("rgba(0, 0, 0, 0.8)", 0, 0, 20);
    btnLabel.x=15
    btnLabel.y=130
    btn.addChild(btnLabel)

    btn
  render:=>
    createjs.Ticker.setFPS(60)
    createjs.Ticker.addEventListener("tick", @handler)
  handler:=>
    @stage.update()
  onCompletePrevMotion:(_cords)=>
    createjs.Tween.removeTweens(blockList[0])
    createjs.Tween.get(blockList[0],{loop:false},true)
      .to({x:_cords[0]},1000)
    blockList = [blockList[1],blockList[2],blockList[0]]
  show:=>
  hide:=>
  clear:=>
    for bv in blockList
      @container.removeChild bv.render()
      bv.clear()
    @imageList = []
    blockList = []
  keyon:=>
    window.addEventListener('keydown',@key,false)
  keyoff:=>
    window.removeEventListener('keydown',@key)
class Popup extends Backbone.View
  el: '#Popup'

  initialize:=>
    $.ajax '/assets/html/popup.html',
      datatype: 'html'
    .then @popupHtmlLoaded

  popupHtmlLoaded:(data,status)=>
    if status isnt 'success'
      console.log "ERROR:Popuphtmlが読み込めません"
    else
      $(@el).html(data)
    @base = $('#snsPost').html()
    @imageviewer = new ImageViewer
    @imageviewer.on("loadnext",@loadnext)
    @imageviewer.on("loadprev",@loadprev)

  loadnext:=>
    @reload @imageviewer.getCenterNum()
    @trigger 'getCenterNum',@imageviewer.getCenterNum()
  loadprev:=>
    @reload @imageviewer.getCenterNum()
    @trigger 'getCenterNum',@imageviewer.getCenterNum()

  openPopupFromPoint:(p)=>
#    Shadow.show()
    $.getJSON searchApi,{'n':p},(data,status)=>
      #タップ拡大時に特殊なフラグによって条件分岐するならココ
      ##and "#{data.img}" isnt 'undefined'    #Popup要素初期化
      if snsLinkage && data[0].b5 isnt 1
#        imgUrl = data[0].b1
        imgUrl = zoomImageDir+data[0].img+tileImageExtension
      else
        imgUrl = zoomImageDir+data[0].img+tileImageExtension
      if status and data isnt null
        @render(data[0],imgUrl)            
      else @hide()
    .fail ->
      @hide()

  clear:=>
    if $(@el).html() isnt ''
#      $("#Popup #closeButton").off()
      $("#Popup #loadImage").
        attr('src','')
    $(@el).hide()

  closePopup:(e)=>
#    @imageviewer.clear()
    @clear()
    $.fancybox.close()
    @hide()

  reload:(p)=>
    $.getJSON searchApi,{'n':p},(data,status)=>
      #タップ拡大時に特殊なフラグによって条件分岐するならココ
      ##and "#{data.img}" isnt 'undefined'    #Popup要素初期化
      if snsLinkage && data[0].b5 isnt 1
#        imgUrl = data[0].b1
        imgUrl = zoomImageDir+data[0].img+tileImageExtension
      else
        imgUrl = zoomImageDir+data[0].img+tileImageExtension
      if status and data isnt null
        @rerender(data[0],imgUrl)            
      else @hide()
    .fail ->
      @hide()
  render:(data,imgSrc)=>
    @imageviewer.setList([
      {
        bid: 3
        num: data.num
        src: imgSrc
        data: data
      }
    ])
#    $("#Popup #loadImage")
#      .css('margin-top',5)
#      .attr('src',imgSrc)
#      .on 'load', (status)=>
    @setDataToView(data)
    @snsButtonAction(data.id)
#        $("#Popup #loadImage").css("width", "300px")
#        $("#Popup img").css("vertical-align", "middle")
    @show()
    @imageviewer.keyon()
    $.getJSON searchApi,{'n':data.num,'request':'0,1,2,4,5,6','base':3},(data,status)=>
      @imageviewer.addList(data)
  rerender:(data,imgSrc)=>
    @setDataToView(data)
    @snsButtonAction(data.id)
    @imageviewer.keyon()

  setDataToView:(data)=>
    shareUrl = "#{DOMAIN}#{APP_FILE}#mosaic/id/#{data.id}/"
    $("#Popup .snsFacebookButton").attr('href',"https://www.facebook.com/sharer.php?u="+encodeURIComponent(shareUrl))
    $("#Popup .snsTwitterButton").attr('href',"https://twitter.com/intent/tweet?url="+encodeURIComponent(shareUrl)+"&text="+encodeURIComponent("#{indiTwitterText}"))
    $("#Popup .snsLineButton").attr('href',"https://line.me/R/msg/text/?"+"#{indiTwitterText}"+'%0D%0A'+shareUrl)
    txt = @base
    for item of data
      if snsLinkage == true
          txt = txt.replace(new RegExp('{#'+item+'#}','g'),data[item])
          $('#snsPost').html(txt)
          $("a:link").css("color", "#ffffff")
          $(".popupB1Style").css("fontSize", "1.2em")
          if data.b3 is "Tagtoru" or data.b5 is 1
            $('#snsPost a').css('pointer-events', 'none')
            $('#snsPost a').css('text-decoration', 'none')
      else
        $("#Popup .popup"+Utility.upperCase(item)+"Style").html data[item]
    if snsLinkage is true
      return $('#nonSnsPost').hide()
    else
      return $('#snsPost').hide()

#    $("#popupOuterText").animate({opacity:'1'},{duration: 500})

  snsButtonAction:(_id)->
    $("#Popup .snsFacebookButton").off()
    $("#Popup .snsFacebookButton").on "touchend",(e) ->
      _gaq.push(['_trackPageview', "/photomosaic/sp/fb/#{_id}"])

    $("#Popup .snsTwitterButton").off()
    $("#Popup .snsTwitterButton").on "touchend",(e) ->
      _gaq.push(['_trackPageview', "/photomosaic/sp/tw/#{_id}"])

    $("#Popup .snsLineButton").off()
    $("#Popup .snsLineButton").on "touchend",(e) ->
      _gaq.push(['_trackPageview', "/photomosaic/sp/line/#{_id}"])

  closeButtonAction:=>
    if Browser.device isnt 'pc'
      $("#Popup #closeButton").on "touchend",(e) =>
        #e.preventDefault()
        @closePopup(e)
        $("#Popup #closeButton").off()
    else
      $("#Popup #closeButton").on "mouseup",(e) =>
        #e.preventDefault()
        @closePopup(e)
        $("#Popup #closeButton").off()

  show:=>
    $(@el).show()

#    Shadow.show()
    $.fancybox.open
      src : '#Popup'
      type : 'inline'
      buttons : ['close']
      smallBtn : false
      touch: false
      afterClose: =>
        @imageviewer.clear()
        @imageviewer.keyoff()
        @trigger "backtomain"
#    Shadow.setFullSize($(@el).height())
    $("#Popup #loadImage").off()
  hide:=>
    @trigger "backtomain"
    $(@el).hide()

  resize:-> Shadow.setSize()

  @setSize:=>
    $(@el).width Browser.width
    $(@el).height Browser.height
getSection = (url,_data,callback) ->
  $.ajax url,
    type: 'GET'
    dataType: 'json'
    success: (data) =>
      return callback(data)

getUrlVars = (_id)=>
  vars = {}
  params = location.search.substring(1).split('&')

  for item in params
    #エスケープ要注意
    keySearch = item.search(/\=/)
    key = ''
    if keySearch isnt -1
      key = item.slice 0,keySearch
    val = item.slice(item.indexOf('=',0)+1)
    if key isnt ''
      vars[key] = decodeURI val
  vars[_id]

UID = getUrlVars 'uid'

DT = if getUrlVars 'dt' then getUrlVars 'dt' else 0

MID = getUrlVars 'mid'

# DTあるなしでIMQとソリューションの切り分け
if DT isnt 0
  motifWidth = (if DT is "2" or DT is "4" then 45 else 50)
  motifHeight = (if DT is "2" or DT is "4" then 45 else 50)

  arrZoomSizeX = [0,4,8,16,32,64]
  arrZoomSizeY = [0,4,8,16,32,64]

  tileImageDir = "swfData/mosaic/#{UID}/web/"
  zoomImageDir = "img/data/#{DT}/orig_images_220/"

setInitData = (data) ->
  DOMAIN = data.domain
  APP_FILE = data.app
  cache = if data.cache is false then "" else '?'+Utility.getRandom()
  tileWidth = data.tileWidth
  tileHeight = data.tileHeight
  motifWidth = data.motifWidth
  motifHeight = data.motifHeight
  arrZoomSizeX = data.arrZoomSize
  arrZoomSizeY = data.arrZoomSize2
  initialZoomSizeArr = data.initialZoomSizeArr
  tileImageDir = data.blockimgPath
  zoomImageDir = data.zoomImagePath
  searchApi = data.searchApi
  bgImageApi = data.bgImageApi
  indiTwitterText = data.indiTwitterText
  campTwitterText = data.campTwitterText

  snsLinkage = data.snsLinkage

  i=0
  for x in arrZoomSizeX
    xz = motifWidth*minBlockSize*arrZoomSizeX[i]
    yz = motifHeight*minBlockSize*arrZoomSizeY[i]
    zoomSize.push [xz,yz]
    i++

  pmviewer = new PhotomosaicViewer
  return pmviewer

$(window).on 'load', ->
  getSection "#{INIT_FILE}"+cache,null,setInitData
  #list = getList()

