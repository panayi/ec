`import Ember from 'ember'`
`import util from '../util'`
`import elementsStateManager from '../statemanagers/elements'`

$('body')
  .on 'focus', '[contenteditable]', ->
    $this = $(this)
    $this.data 'before', $this.html()
    $this
  .on 'blur keyup paste input', '[contenteditable]', ->
    $this = $(this)
    if $this.data('before') isnt $this.html()
      $this.data 'before', $this.html()
      $this.trigger('change')
      $this

elementsView = Ember.View.extend
  classNames: ['editable', 'editor-style']
  classNameBindings: ['isFocused']
  attributeBindings: ['contenteditable']
  contenteditable: 'true'

  body: Ember.computed.alias('component.body')
  tags: Ember.computed.alias('component.tags')
  placeholder: Ember.computed.alias('component.placeholder')

  inDOMElements: Ember.computed.filterBy('elements', 'inDOM')

  selectedAndEmptyElement: ( ->
    selectedElement = @get('selectedElement')
    selectedElement if selectedElement and selectedElement.get('isEmpty')
  ).property('selectedElement.isEmpty')

  bindSelectionChangeEvent: ( ->
    selectionChangeHandler = (event) =>
      @manager.send('selectionchange')

    selectionchange.start()
    $(document).on('selectionchange', selectionChangeHandler)

    @on 'willDestroyElement', ->
      $(document).off('selectionchange', selectionChangeHandler)
      selectionchange.stop()
  ).on('didInsertElement')

  bindPasteEvent: ( ->
    el = this.$().get(0)
    el.onpaste = (event) =>
      @manager.send('eventOccured', event)
  ).on('didInsertElement')

  sendEventsToManager: ( (event) ->
    @manager.send('eventOccured', event)
  ).on('focusIn', 'focusOut', 'keyUp', 'keyDown', 'keyPress', 'mouseUp', 'mouseDown', 'click', 'change')

  serializeElements: ( ->
    Ember.run.scheduleOnce 'afterRender', =>
      body = @get('body')
      $wrapper = $('<div/>')
      $wrapper.html(body)
      @set('elements', [])
      $elements = util.getDOMElements($wrapper).toArray()
      $elements.forEach (domElement) =>
        @insertElement(domElement, true)
  ).on('didInsertElement')

  insertElement: (domElement, focusOnInsert = false) ->
    elements = @get('elements')
    dataName = domElement.getAttribute('data-name')

    options = { focusOnInsert: focusOnInsert }
    element = util.serializeElement(domElement, @get('component'), options)
    elements.pushObject(element)

    Ember.run.later -> element.trigger('setup')
    element

  insertEmptyDOMElement: (placeholder = '<br>') ->
    safePlaceholder = util.safeAttribute(placeholder)
    html = util.generateName("<p data-placeholder='#{safePlaceholder}'><span class='placeholder'>#{placeholder}</span></p>")
    util.insertHTMLCommand(html)

  setIsInserted: ( ->
    Ember.run.scheduleOnce 'afterRender', =>
      @set('isInserted', true)
  ).on('didInsertElement')

  teardownElementObjectsOnDestroy: ( ->
    @getWithDefault('elements', []).invoke('destroy')
  ).on('willDestroyElement')

  setupManager: ( ->
    Ember.run.scheduleOnce 'afterRender', =>
      component = @get('component')
      @manager = elementsStateManager.create({ elementsView: this, component: component })
  ).on('didInsertElement')

  actions:
    unuseTagInElement: (elementObject) ->
      elementObject.setProperties
        'data-tag-id': null
        'data-placeholder': null

      placeholder = elementObject.get('placeholder')
      elementObject.setBody("<span class='placeholder'>#{placeholder}</span>")
      Ember.run ->
        elementObject.bodyDidChange()

`export default elementsView`
