class Views.DiscussionView extends View
  @content: ->
    @div class: 'discussion column', =>
      @subview 'commentsList', new Views.RelationView(
        buildItem: (comment) -> new Views.CommentItem(comment)
      )
      @div class: 'text-entry', =>
        @textarea rows: 2, outlet: 'textarea'
        @button "Submit Comment", class: 'btn pull-right', click: 'createComment'

  autoScroll: true

  initialize: (@comments) ->
    @commentsList.scroll => @assignAutoscroll()
    @commentsList.onInsert = => @scrollToBottom() if @autoScroll
    @commentsList.setRelation(@comments)

    @textarea.keydown (e) =>
      if e.keyCode == 13 && !e.ctrlKey # enter (not ctrl-enter though)
        e.preventDefault()
        @createComment()

  afterAttach: ->
    @scrollToBottom()

  createComment: ->
    body = @textarea.val()
    if /\S/.test(body)
      @textarea.val('')
      @comments.create({body})

  scrollToBottom: ->
    @commentsList.scrollTop(@maxScroll())

  maxScroll: ->
    @commentsList.scrollTop() + @commentsList.outerHeight()

  assignAutoscroll: ->
    @autoScroll = (@commentsList.prop('scrollHeight') == @maxScroll())

  remove: (selector, keepData) ->
    unless keepData
      @commentsList.remove()
