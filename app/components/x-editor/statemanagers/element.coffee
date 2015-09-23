`import Ember from 'ember'`
`import StateManager from 'ember-states/state-manager'`
`import State from 'ember-states/state'`
`import util from '../util'`

elementStateManager = StateManager.extend
  initialState: ( ->
    if @get('element').hasBody() then 'inDOM.focusedOut.filled' else 'inDOM.focusedOut.empty'
  ).property()

  focusin: Ember.K
  focusout: Ember.K
  mouseup: Ember.K
  mousedown: Ember.K
  keyup: Ember.K
  keydown: Ember.K
  keypress: Ember.K
  click: Ember.K
  change: Ember.K
  paste: Ember.K
  enterKeyPressed: Ember.K
  escKeyPressed: Ember.K
  didInsert: Ember.K
  didDestroy: Ember.K
  selectedElementWillChange: Ember.K
  selectedElementDidChange: Ember.K
  didEmpty: Ember.K
  didFill: Ember.K

  eventOccured: (manager, event) ->
    manager.send(event.type, event)
    Ember.run.next ->
      component = manager.get('component')
      component.send('setSelectedText')
      component.sendAction("on#{Ember.String.capitalize(event.type)}")

  inDOM: State.extend
    enter: (manager) ->
      manager.set('element.inDOM', true)
      manager.get('element').trigger('didInsertElement')
      Ember.run -> manager.get('element').bodyDidChange()

    didDestroy: (manager) ->
      # Safer to just destroy the object.
      # It will be re-created in case the user undoes,
      # and the element re-appears in the DOM.
      destroyedElement = manager.get('element').destroy()
      manager.get('elementsView.elements').removeObject(destroyedElement)

    focusedOut: State.extend
      selectedElementDidChange: (manager, currentSelectedElement) ->
        manager.send('focusin') if currentSelectedElement is manager.get('element')

      focusin: (manager) ->
        nextState = if manager.get('element').hasBody() then 'inDOM.focusedIn.filled' else 'inDOM.focusedIn.empty'
        manager.transitionTo(nextState)

      empty: State.extend
        enter: (manager) ->
          element = manager.get('element')
          element.set('isEmpty', true)
          # element.setBody(element.get('placeholder'))

        didFill: (manager) ->
          manager.transitionTo('focusedOut.filled')

      filled: State.extend
        enter: (manager) ->
          manager.get('element').set('isEmpty', false)

        didEmpty: (manager) ->
          manager.transitionTo('focusedOut.empty')

    focusedIn: State.extend
      enter: (manager) ->
        element = manager.get('element')
        manager.set('elementsView.selectedElement', element)

      focusout: (manager) ->
        nextState = if manager.get('element').hasBody() then 'inDOM.focusedOut.filled' else 'inDOM.focusedOut.empty'
        manager.transitionTo(nextState)

      selectedElementWillChange: (manager, currentSelectedElement) ->
        manager.send('focusout')

      enterKeyPressed: (manager, event) ->
        elementObject = manager.get('element')
        $currentElement = elementObject.get('element')
        currentElement = $currentElement.get(0)
        tagName = currentElement.tagName.toLowerCase()
        isHeader = /h\d/i.test(tagName)
        caretOffsets = util.getCaretOffsets(currentElement)
        isAtStart = caretOffsets.left is 0
        isAtEnd = caretOffsets.right is 0
        if isHeader and (isAtStart or isAtEnd)
          event.preventDefault()
          util.insertHTMLCommand('<p><br></p>')
          element = $(util.getSelectionStart()).closest('p').get(0)
          util.moveCursorAtBeginning(currentElement) if isAtStart
        else if elementObject.get('isEmpty') and not Ember.isEmpty($currentElement.has('.placeholder'))
          event.preventDefault()
          util.moveCursorAfter(currentElement)
          Ember.run ->
            util.insertHTMLCommand('<p><br></p>')
            element = $(util.getSelectionStart()).closest('p').get(0)
        Ember.run.next ->
          element = element or util.getElementStart()
          element.removeAttribute('data-placeholder', '')
          element.removeAttribute('data-id', '')
          element.removeAttribute('class', '')
          util.generateName(element)

      paste: (manager, event) ->
        component = manager.get('component')
        elementObject = manager.get('element')
        html = ""
        dataFormatHTML = "text/html"
        dataFormatPlain = "text/plain"

        Ember.run ->
          if window.clipboardData and event.clipboardData is `undefined`
            event.clipboardData = window.clipboardData

            # If window.clipboardData exists, but event.clipboardData doesn't exist,
            # we're probably in IE. IE only has two possibilities for clipboard
            # data format: 'Text' and 'URL'.
            #
            # Of the two, we want 'Text':
            dataFormatHTML = "Text"
            dataFormatPlain = "Text"

          if event.clipboardData and event.clipboardData.getData
            event.preventDefault()

            manager.get('elementsView').send('unuseTagInElement', elementObject) if elementObject.get('isEmpty')

            Ember.run ->
              if data = event.clipboardData.getData(dataFormatHTML)
                elements = manager.get('elementsView').$().get(0)
                util.cleanPaste(component, elementObject, data)
              else
                paragraphs = event.clipboardData.getData(dataFormatPlain).split(/[\r\n]/g)
                html = util.htmlEntities(paragraphs[0])
                p = 1
                while p < paragraphs.length
                  if paragraphs[p] isnt ""
                    uuid = Ember.uuid()
                    html += "<p data-name='#{uuid}'>" + util.htmlEntities(paragraphs[p]) + "</p>"
                  p += 1

                util.insertHTMLCommand(html)

              Ember.run -> elementObject.bodyDidChange()

      empty: State.extend
        enter: (manager) ->
          element = manager.get('element')
          element.set('isEmpty', true)
          el = element.get('element').get(0)

        keydown: (manager, event) ->
          isBackspaceKey = util.isBackspaceKey(event)
          if isBackspaceKey and manager.get('element').get('isOnlyOne')
            event.preventDefault()
          else if isBackspaceKey
            manager.send('keypress', event)

        keypress: (manager, event) ->
          unless util.isEnterKey(event)
            manager.get('element.element').find('.placeholder').remove()
            manager.send('didFill')

        escKeyPressed: (manager, event) ->
          manager.get('component.addTagView').send('escKeyPressed', event)

        didFill: (manager) ->
          manager.transitionTo('focusedIn.filled')

      filled: State.extend
        enter: (manager) ->
          manager.get('element').set('isEmpty', false)

        keydown: (manager, event) ->
          component = manager.get('component')
          if component.get('isToolbarVisible') and util.triggerShortcut(component.$(), event)
            event.preventDefault()

        keyup: (manager, event) ->
          Ember.run.debounce this, ->
            manager.get('element').bodyDidChange()
          , 100

        didEmpty: (manager) ->
          manager.transitionTo('focusedIn.empty')

`export default elementStateManager`
