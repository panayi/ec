`import Ember from 'ember'`
`import util from '../util'`
`import elementStateManager from '../statemanagers/element'`

elementObject = Ember.Object.extend Ember.Evented,
  classNameBindings: ['isFocused', 'isEmpty', 'isFirst', 'isLast']
  attributeBindings: ['data-name', 'data-id', 'data-placeholder']

  elementsView: Ember.computed.alias('component.elementsView')
  elements: Ember.computed.alias('elementsView.elements')
  inDOMElements: Ember.computed.alias('elementsView.inDOMElements')
  selectedElement: Ember.computed.alias('elementsView.selectedElement')

  contentIndex: (->
    util.getDOMElements(@get('elementsView').$()).index(@get('element'))
  ).property('elements.@each.element', 'data-name')

  isFirst: (->
    @getWithDefault('inDOMElements', []).get('firstObject') is this
  ).property('inDOMElements.firstObject')

  isLast: (->
    @getWithDefault('inDOMElements', []).get('lastObject') is this
  ).property('inDOMElements.lastObject')

  isOnlyOne: Ember.computed.and('isFirst', 'isLast')

  isFocused: (->
    @get('selectedElement') is this
  ).property('selectedElement')

  placeholder: (->
    @get('data-placeholder') or ''
  ).property('data-placeholder')

  hasBody: ->
    element = @get('element')
    element and Ember.isEmpty(element.has('.placeholder')) and (element.html().trim() isnt '<br>')

  onHasBodyChange: (->
    actionName = if @hasBody() then 'didFill' else 'didEmpty'
    manager.send(actionName) if manager = @get('manager')
  ).observes('body', 'placeholder', 'manager')

  onAttributesChange: (->
    element = @get('element')
    return unless element
    @attributeBindings.forEach (name) =>
      element.attr(name, @get(name))
  ).observes('data-name', 'data-id', 'data-placeholder').on('didInsertElement')

  onClassesChange: ( ->
    element = @get('element')
    return unless element
    @classNameBindings.forEach (className) =>
      klass = Ember.String.dasherize(className)
      if @get(className)
        element.addClass(klass)
      else
        element.removeClass(klass)
  ).observes('isFocused', 'isEmpty', 'isFirst', 'isLast').on('didInsertElement')

  selectedElementWillChange: (->
    manager.send('selectedElementWillChange', @get('selectedElement')) if manager = @get('manager')
  ).observesBefore('selectedElement', 'manager')

  selectedElementDidChange: (->
    manager.send('selectedElementDidChange', @get('selectedElement')) if manager = @get('manager')
  ).observes('selectedElement', 'manager')

  checkIfShouldFocusOnInsert: (->
    element = @get('element')
    if @get('focusOnInsert') and element and (util.getElementStart() isnt element.get(0))
      util.moveCursorAtBeginning(element.get(0))
  ).on('didInsertElement')

  element: (->
    dataName = @get('data-name')
    elementsView = @get('elementsView')
    if elementsView and elementsView.get('isInserted') and not elementsView.get('isDestroyed')
      elementsView.$().find("[data-name='#{dataName}']")
    else
      null
  ).property('elementsView.isInserted', 'data-name', 'inDOM')

  html: ->
    $el = @get('element').clone()
    return '' if Ember.isEmpty($el)

    $el.html('<br>') if @get('isEmpty')

    # We don't need to persist the element classes
    $el.removeClass()

    # Remove all spans. Fixes an issue with Chrome,
    # see https://code.google.com/p/chromium/issues/detail?id=226941
    $el.find('span').not('.placeholder').contents().unwrap()

    # Remove zero-space character &#8203
    $el.html($el.html().replace(/\u200B/g, ''))

    $el.get(0).outerHTML

  computedHtml: (->
    @html()
  ).property('element', 'body', 'isEmpty')

  attachFile: (src) ->
    @get('manager').send('attachFile', src)

  setBody: (value) ->
    element = @get('element')
    @get('element').html(value)

  bodyDidChange: ->
    @set('body', element.html()) if element = @get('element')
    component.bodyDidChange(this) if component = @get('component')

  willDestroy: ->
    @get('component').bodyDidChange(this)
    @_super()

  setupManager: (->
    manager = elementStateManager.create
      elementsView: @get('elementsView')
      element: this
      component: @get('component')
    @set('manager', manager)
  ).on('setup')

`export default elementObject`
