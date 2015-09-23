`import Ember from 'ember'`
`import util from '../util'`

toolbarView = Ember.View.extend
  selectedElement: Ember.computed.alias('component.selectedElement')
  isTextSelected: Ember.computed.alias('component.isTextSelected')

  buttons: ( ->
    buttons = @get('component.buttons') or ''
    buttons.split(',')
  ).property('component.buttons')

  # TODO: Refactor. Should not manually move Ember.View elements
  moveToRoot: ( ->
    this.$().appendTo('body')
  ).on('didInsertElement')

  removeOnDestroy: ( ->
    this.$().remove()
  ).on('willDestroyElement')

  isFontColorEnabled: ( ->
    !!@getWithDefault('buttonObjects', []).findBy('name', 'fontColor')
  ).property('buttonObjects.@each.name')

  buttonObjects: ( ->
    buttons = []
    component = @get('component')
    @getWithDefault('buttons', []).forEach (name) =>
      button = allButtons.findBy('name', name)
      if button
        button.component = component
        button.toolbar = this
        buttonObject = buttonClass.extend(button)
        buttons.pushObject(buttonObject.create())
    buttons
  ).property('buttons.[]')

  setPosition: ( ->
    selectedElement = @get('selectedElement')
    return unless selectedElement and @get('isTextSelected')
    $toolbar = this.$('.editor-toolbar')
    $toolbar.hide()

    Ember.run.later ->
      range = window.getSelection().getRangeAt(0)
      bound = range.getBoundingClientRect()
      if bound
        top = bound.top - $toolbar.outerHeight() + 3
        left = bound.left + bound.width/2 - $toolbar.outerWidth()/2
        $toolbar.css({ top: top + 5, left: left }).show().animate({ top: top, left: left }, 50)
    , 1
  ).observes('isTextSelected', 'selectedElement', 'component.isInsertingLink', 'component.isSelectingColor')

  actions:
    buttonClicked: (button) ->
      component = @get('component')
      button.actionHandler(component)
      selectedElement = @get('selectedElement')
      Ember.run.next ->
        component.get('elementsView').$().trigger('change')
        util.getSelectedElements(component).invoke('bodyDidChange')

allButtons = [
  # Bold
  name: 'bold'
  tagName: 'B'
  activeTargetSelector: 'B,H1,H2'
  headerButtons: ( ->
    @getWithDefault('toolbar.buttonObjects', []).filter (buttonObject) ->
      ['h1', 'h2'].contains(buttonObject.get('name'))
  ).property('toolbar.buttonObjects.@each.name')

  isVisible: ( ->
    @getWithDefault('headerButtons', []).isEvery('isActive', false)
  ).property('headerButtons.@each.isActive')
,
  # Italic
  name: 'italic'
  tagName: 'I'
,
  # Underline
  name: 'underline'
  tagName: 'U'
  activeTargetSelector: 'U,IMG'
,
  # Bulleted List
  name: 'unorderedList'
  tagName: 'UL'
,
  # Numbered List
  name: 'orderedList'
  tagName: 'OL'
,
  # Link
  name: 'link'
  tagName: 'A'
,
  # Indent
  name: 'indent'
  tagName: 'BLOCKQUOTE'
,
  # Outdent
  name: 'outdent'
  tagName: null
,
  # H1
  name: 'h1'
  tagName: 'H1'
,
  # H2
  name: 'h2'
  tagName: 'H2'
,
  # Red Color
  name: 'fontColor'
  tagName: 'FONT'
,
  # Quote
  name: 'quote'
  tagName: 'Q'
]

buttonHandler = {}

buttonHandler.bold = (component) ->
  util.nativeExecCommand('bold')

buttonHandler.italic = (component) ->
  util.nativeExecCommand('italic')

buttonHandler.underline = (component) ->
  util.nativeExecCommand('underline')

buttonHandler.unorderedList = (component) ->
  util.nativeExecCommand('insertUnorderedList')

buttonHandler.orderedList = (component) ->
  util.nativeExecCommand('insertOrderedList')

buttonHandler.link = (component) ->
  if @get('isActive')
    util.nativeExecCommand('unlink')
  else
    selection = util.saveSelection()
    component.send('beginLinkInsert', selection)

buttonHandler.indent = (component) ->
  util.nativeExecCommand('indent')

buttonHandler.outdent = (component) ->
  util.nativeExecCommand('outdent')

buttonHandler.h1 = (component) ->
  if @get('isActive')
    util.nativeExecCommand('formatBlock', false, 'p')
    Ember.run ->
      selection = util.getSelectionStart()
      util.generateName($(selection).closest('p'))
  else
    util.nativeExecCommand('formatBlock', false, 'h1')
    Ember.run ->
      selection = util.getSelectionStart()
      util.generateName($(selection).closest('h1'))

buttonHandler.h2 = (component) ->
  if @get('isActive')
    util.nativeExecCommand('formatBlock', false, 'p')
    Ember.run ->
      selection = util.getSelectionStart()
      util.generateName($(selection).closest('p'))
  else
    util.nativeExecCommand('formatBlock', false, 'h2')
    Ember.run ->
      selection = util.getSelectionStart()
      util.generateName($(selection).closest('h2'))

buttonHandler.fontColor = (component) ->
  selection = util.saveSelection()
  component.send('beginSelectColor', selection)

buttonHandler.quote = (component) ->
  selectedText = component.get('selectedText')
  html = "<span>&#8220;#{selectedText}&#8221;</span>"
  util.insertHTMLCommand(html)

# Button Class
buttonClass = Ember.Object.extend
  isVisible: true

  actionHandler: Ember.K

  setActionHandler: ( ->
    name = @get('name')
    @actionHandler = buttonHandler[name] if name
    @set('activeTargetSelector', @get('tagName')) unless @get('activeTargetSelector')
  ).observes('name').on('init')

  isActive: ( ->
    return unless @get('component.isTextSelected')
    selection = window.getSelection()
    range = selection.getRangeAt(0) if selection.rangeCount
    @isWithinMatchingHTML(range) if range
  ).property('component.{selectedText,body}', 'tagName')

  isWithinMatchingHTML: (range) ->
    tagName = @get('tagName')
    activeTargetSelector = @get('activeTargetSelector')
    activeTargets = activeTargetSelector.split(',')
    elementsNode = @get('component.elementsView').$().get(0)
    selectedNodes = util.getSelectedNodes(range)

    selectedTextNodes = selectedNodes.filterBy('nodeType', 3)
    return false if Ember.isEmpty(selectedTextNodes)

    selectedNodes.filter (node) ->
      hasDataName = node.hasAttribute and node.hasAttribute('data-name')
      isTextNode = node.nodeType is 3
      childNodes = Array.prototype.slice.call(node.childNodes or [])
      hasChildNodes = !Ember.isEmpty(childNodes)

      elementsNode.contains(node) and
      node isnt elementsNode and
      not hasDataName and
      # if its a leaf node and not a textNode, it should have child nodes
      (hasChildNodes or isTextNode) and
      # assuming this node has child nodes, it needs to have at least one text node selected
      not hasChildNodes or Ember.EnumerableUtils.intersection((childNodes.filterBy('nodeType', 3)), selectedTextNodes).filter (textNode) ->
        textNode.textContent.length > 0
      .length > 0
    .every (node) ->
      isTextNode = node.nodeType is 3

      activeTargets.contains(node.tagName) or
      $(node).parents(activeTargetSelector).length > 0 or
      $(node).find(activeTargetSelector).length > 0 or
      (isTextNode and node.textContent.trim().length < 1)

  isInTag: (startParentNode, endParentNode, tagName) ->
    startTag = startParentNode.tagName
    endTag = endParentNode.tagName
    (startTag is tagName) and (endTag is tagName)

`export default toolbarView`
