`import Ember from 'ember'`
`import selectionChange from './selection-change-polyfill'`
`import defaultOptions from './options'`
`import util from './util'`
`import elementsViewClass from './views/elements'`
`import toolbarViewClass from './views/toolbar'`
`import addTagViewClass from './views/add-tag'`
`import linkPopoverViewClass from './views/link-popover'`
`import fileInputComponent from '../file-input'`
`import popoveBodyComponent from '../pop-over'`

XEditorComponent = Ember.Component.extend
  classNames: ['editor']

  # Default Options
  buttons: defaultOptions.buttons
  colors: defaultOptions.colors
  placeholder: defaultOptions.placeholder
  tags: defaultOptions.tags

  # Views
  elementsViewClass: elementsViewClass
  toolbarViewClass: toolbarViewClass
  addTagViewClass: addTagViewClass
  linkPopoverViewClass: linkPopoverViewClass
  elementsView: Ember.computed.alias('dropAbleView.elementsView')

  isTextSelected: Ember.computed.gt('selectedText.length', 0)
  isToolbarVisible: Ember.computed.or('isTextSelected', 'isInsertingLink')
  selectedElement: Ember.computed.alias('elementsView.selectedElement')
  selectedAndEmptyElement: Ember.computed.alias('elementsView.selectedAndEmptyElement')

  initializeBody: ( ->
    body = @get('body')
    if body.length < 1
      body = util.generateName(defaultOptions.defaultBody)
      @set('body', body)
  ).on('init')

  bodyDidChange: (changedElement) ->
    Ember.run.debounce(this, =>
      elements = @get('elementsView.elements')
      if elements = @get('elementsView.elements')
        body = util.serializeBody(elements, changedElement)
        @set('body', body)
    , 200, false)

  _endLinkInsert: (event) ->
    event.preventDefault()
    @send('endLinkInsert')

  _endColorSelect: (event) ->
    event.preventDefault()
    @send('endSelectColor')

  setIsInserted: ( ->
    @set('isInserted', true)
  ).on('didInsertElement')

  registerComponent: ( ->
    this.set('register-as', this)
  ).on('init')

  actions:
    beginLinkInsert: (selection) ->
      @set('link', null)
      @set('isInsertingLink', true)
      @_linkForSelection = selection

      $('body').on('click.isInsertingLink', null, @_endLinkInsert.bind(this))

    endLinkInsert: (link) ->
      util.restoreSelection(@_linkForSelection)
      @_linkForSelection = null
      Ember.run.next =>
        if link
          link = "http://#{link}" unless util.urlHasScheme(link)
          util.nativeExecCommand('createLink', false, link)
          Ember.run -> util.setTargetBlank()
        @set('isInsertingLink', false)

      $('body').off('.isInsertingLink')

    beginSelectColor: (selection) ->
      @set('isSelectingColor', true)
      @_colorForSelection = selection
      @_colorForElement = @get('selectedElement')
      $('body').on('click.isSelectingColor', null, @_endColorSelect.bind(this))

    endSelectColor: (color) ->
      util.restoreSelection(@_colorForSelection)
      @_colorForSelection = null
      $('body').off('.isSelectingColor')

      Ember.run =>
        util.nativeExecCommand('foreColor', false, color) if color
        @set('isSelectingColor', false)

        Ember.run =>
          @_colorForElement.bodyDidChange()

    keyPressedInLinkInput: (event) ->
      if util.isEnterKey(event)
        event.preventDefault()
        @send('endLinkInsert', @get('link'))

    setSelectedText: ->
      Ember.run.next =>
        unless @get('isDestroyed')
          selection = util.getSelectionStart()
          $elementsView = @get('elementsView').$()
          if jQuery.contains($elementsView.get(0), selection)
            @set('selectedText', util.getSelectionText())
          else
            @set('selectedText', null)

    uploadFiles: (files, elementObject) ->
      @sendAction('uploadFiles', files, elementObject)

    attachFile: (src, elementObject) ->
      @get('elementsView').$().focus()
      Ember.run.later ->
        util.moveCursorAtEnd(elementObject.get('element').get(0))
        Ember.run.later ->
          html = "<br><figure>
                    <img src=\"#{src}\"><br>
                  </figure>"
          html = util.generateName(html)
          util.insertHTMLCommand(html)
        , 400
      , 50

    dropFiles: (event) ->
      fileList = event.dataTransfer.files
      if fileList.length > 0
        target = event.target
        elementObject = util.getParentElement(target, @get('elementsView.elements'))
        @send('uploadFiles', fileList, elementObject)

    triggerFileUpload: ->
      Ember.run =>
        @get('uploaderView.input').$().trigger('click')

`export default XEditorComponent`
