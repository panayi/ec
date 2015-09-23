`import Ember from 'ember'`
`import StateManager from 'ember-states/state-manager'`
`import State from 'ember-states/state'`
`import util from '../util'`

elementsStateManager = StateManager.extend
  initialState: 'focusedOut'

  focusin: Ember.K
  focusout: Ember.K
  mouseup: Ember.K
  keyup: Ember.K
  keypress: Ember.K
  click: Ember.K
  paste: Ember.K

  mousedown: (manager, event) ->
    element = util.getParentDOMElement(event.target)
    if element and $(element).hasClass('is-empty')
      event.preventDefault()
      util.moveCursorAtBeginning(element)

  change: (manager, event) ->
    elementsView = manager.get('elementsView')
    $elementsView = elementsView.$()
    elements = elementsView.get('elements').slice()
    $elements = util.getDOMElements($elementsView)
    elementsLength = elements.get('length')

    $elements.each ->
      $element = $(this)
      dataName = $element.attr('data-name')

      # unless element object already exists
      unless elements.findBy('data-name', dataName)
        elementsView.insertElement($element.get(0))

    elements.forEach (element) ->
      dataName = element.get('data-name')

      # element no longer exists in DOM
      isInDOM = $elements.filter("[data-name='#{dataName}']").length > 0
      element.get('manager').send('didDestroy') unless isInDOM

    manager.send('selectionchange')

  selectionchange: (manager, selectionStart) ->
    elementsView = manager.get('elementsView')
    elementObjects = elementsView.get('elements')
    element = util.getElementStart()
    if element
      currentSelectedElement = elementsView.get('selectedElement')
      newSelectedElement = util.getElementByDOMElement(element, elementObjects)
      elementsView.set('selectedElement', newSelectedElement) unless newSelectedElement is currentSelectedElement
    else
      # Ensure there is at least one element
      if Ember.isEmpty(util.getDOMElements(elementsView.$()))
        console.warn 'No elements left. Inserting an empty element'
        elementsView.insertEmptyDOMElement()

    # Only for debugging. TODO: remove
    if not element and elementsView.get('isFocused')
      # selection is orphan (not under an element)
      console.warn 'Selection is orphan', util.getSelectionStart()

  keydown: (manager, event) ->
    selectedElement = manager.get('elementsView.selectedElement')
    return unless selectedElement
    selectedElementManager = selectedElement.get('manager')

    keyCode = event.keyCode || event.which

    if util.isEnterKey(event)
      if util.isSelectionWithinEmptyListItem()
        Ember.run.next ->
          # Move inserted <div> after current element
          # Solves issue where cursor is trapped inside an element when <ul> is present
          $div = $(util.getSelectionStart())
          $div.detach().insertAfter($(util.getElementStart()))
          Ember.run -> util.moveCursorAtBeginning($div.get(0))
          Ember.run.next -> selectedElement.manager.send('enterKeyPressed', event)
      else if not util.isSelectionWithin('ul,ol')
        selectedElementManager.send('enterKeyPressed', event)
    else if util.isEscKey(event)
      selectedElementManager.send('escKeyPressed', event)

  eventOccured: (manager, event) ->
    manager.send(event.type, event)
    selectedElement = manager.get('elementsView.selectedElement')
    manager = selectedElement and selectedElement.get('manager')
    manager.send('eventOccured', event) if manager

  focusedOut: State.extend
    enter: (manager) ->
      manager.get('elementsView').set('isFocused', false)

    focusin: (manager, event) ->
      manager.transitionTo('focusedIn')

  focusedIn: State.extend
    enter: (manager) ->
      manager.set('elementsView.isFocused', true)

    focusout: (manager) ->
      manager.transitionTo('focusedOut')
      selectedElement = manager.get('elementsView.selectedElement')
      selectedElement.get('manager').send('focusout') if selectedElement

`export default elementsStateManager`
