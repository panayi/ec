`import Ember from 'ember'`

defaultMatcher = (value, query) ->
  value.toLowerCase().indexOf(query.trim().toLowerCase()) is 0

getArray = (context, key) ->
  context.get(key) or []

customSelectOptionView = Ember.View.extend
  classNameBindings: ['active', 'controller.selected']
  isVisible: Ember.computed.alias('controller.isVisible')

  onInsert: ( ->
    @get('controller').set('customSelectOption', this)
  ).on('didInsertElement')

  activateOnMouseEnter: ( ->
    @get('controller').send('activate')
  ).on('mouseEnter')

  selectOnMouseDown: ( ->
    @get('controller').send('select')
  ).on('mouseDown')

  onMatchingChange: ( ->
    @send('deactivate') unless @get('controller.matching')
  ).observes('controller.matching')

  actions:
    activate: ->
      @set('active', true) unless @get('isDestroyed')

    deactivate: ->
      @set('active', false) unless @get('isDestroyed')

nativeSelectionOptionView = Ember.SelectOption.extend
  onInsert: ( ->
    componentView = @get('parentView.parentView')
    componentView.didInsertNativeSelectOption(this, @get('content'))
  ).on('didInsertElement')

  onDestroy: ( ->
    componentView = @get('parentView.parentView')
    componentView.didDestroyNativeSelectOption(@get('content'))
  ).on('willDestroyElement')

proxiesController = Ember.ArrayController.extend()

proxyController = Ember.Controller.extend
  label: Ember.computed.alias('nativeSelectOption.label')
  value: Ember.computed.alias('nativeSelectOption.value')
  active: Ember.computed.alias('customSelectOption.active')

  selected: ( ->
    @get('component').isSelectedComputer(this)
  ).property('component.selection.[]', 'content')

  isVisible: ( ->
    @get('component').isVisibleComputer(this)
  ).property('matching', 'selected', 'value')

  matching: ( ->
    matcher = @get('component._matcher')
    query = @get('component.query')
    label = @get('label')

    if query.length < 1 then true else matcher.call(this, label, query)
  ).property('component.{_matcher,query}', 'label')

  notifyDropdownInstance: ->
    @get('component.dropdownInstance').trigger('change')

  actions:
    select: ->
      @get('nativeSelectOption').$().prop('selected', true)
      @get('component').afterSelect()
      Ember.run =>
        @notifyDropdownInstance()

    deselect: ->
      @get('nativeSelectOption').$().prop('selected', false)
      Ember.run =>
        @notifyDropdownInstance()

    activate: ->
      return if @get('active')
      @get('component').send('deactivateAll')
      Ember.run =>
        @get('customSelectOption').send('activate')

    deactivate: ->
      @get('customSelectOption').send('deactivate')

keyResponderMixin = Ember.Mixin.create
  activeProxy: ( ->
    proxies = getArray(this, 'proxies')
    proxies.findBy('active')
  ).property('proxies.@each.active')

  handleKeyPress: ((e) ->
    @set('isOpened', true)
    code = e.keyCode || e.which
    if code is 38 # up arrow
      @activateAdjacent(-1)
    else if code is 40 # down arrow
      @activateAdjacent(1)
    else if code is 13 # enter
      activeProxy = @get('activeProxy')
      (@get('allowInsert') and @insertItem()) or (activeProxy and activeProxy.send('select'))
    else if code is 27 # ESC
      @send('close')
  ).on('keyDown')

  activateAdjacent: (move) ->
    activeProxy = @get('activeProxy')
    proxies = @get('visibleProxies')

    if activeProxy
      activeIndex = proxies.indexOf(activeProxy)
      newactiveProxyIndex = activeIndex + move
      if newactiveProxyIndex < 0
        newactiveProxyIndex = proxies.length - 1
      else if newactiveProxyIndex > proxies.length - 1
        newactiveProxyIndex = 0
    else if move < 0
      newactiveProxyIndex = proxies.length - 1
    else if move > 0
      newactiveProxyIndex = 0

    targetProxy = proxies.objectAt(newactiveProxyIndex)
    targetProxy.send('activate') if targetProxy

multipleOptionsMixin = Ember.Mixin.create
  placeholder: ( ->
    if @get('selection.length') > 0 then '' else @get('prompt')
  ).property('prompt', 'selection.length')

  hasSelectedItems: Ember.computed.notEmpty('selection.[]')

  isSelectedComputer: (proxy) ->
    content = proxy.get('content')
    selection = @get('selection')
    selection and selection.indexOf(content.valueOf()) > -1

  isVisibleComputer: (proxy) ->
    proxy.get('value') and proxy.get('matching') and not proxy.get('selected')

  afterSelect: ->
    Ember.run.later =>
      @send('focusInTextField')
    , 1

singleOptionMixin = Ember.Mixin.create
  selectedProxy: ( ->
    @get('proxies').findBy('selected')
  ).property('proxies.@each.selected')

  placeholder: ( ->
    @get('prompt') unless @get('selection')
  ).property('prompt', 'selection')

  hasSelectedItems: ( ->
    !!@get('selection')
  ).property('selection')

  isSelectedComputer: (proxy) ->
    proxy.get('content') is @get('selection.content') or proxy.get('content') is @get('selection')

  isVisibleComputer: (proxy) ->
    proxy.get('value') and proxy.get('matching')

  afterSelect: ->
    Ember.run.later =>
      @send('close')
    , 1

SelectBoxComponent = Ember.Component.extend keyResponderMixin,
  classNames: ['select-box']
  classNameBindings: ['isOpened', 'hasSelectedItems', 'disabled']
  attributeBindings: ['tabIndex']
  tabIndex: -1

  customSelectOptionView: customSelectOptionView
  nativeSelectionOptionView: nativeSelectionOptionView

  optionValuePath: 'content'
  optionLabelPath: 'content'
  optionGroupPath: null
  sortAscending: true
  isOpened: false
  query: ''
  noSelectedItems: Ember.computed.not('hasSelectedItems')
  isInvalid: Ember.computed.and('required', 'noSelectedItems')

  _sortProperties: ( ->
    sortProperties = @get('sortProperties')
    if sortProperties then sortProperties.split(',') else [@get('optionLabelPath')]
  ).property('sortProperties', 'optionLabelPath')

  setup: ( ->
    sortProperties = @get('_sortProperties')
    sortAscending = @get('sortAscending')
    proxies = proxiesController.create({ sortProperties: sortProperties, sortAscending: sortAscending })
    @set('proxies', proxies)
    @set('inserts', []) unless @get('inserts')
    mixin = (if @get('multiple') then multipleOptionsMixin else singleOptionMixin)
    @reopen(mixin)
  ).on('init')

  didInsertNativeSelectOption: (nativeSelectOptionView, item) ->
    proxies = @get('proxies')
    newProxy = proxyController.create
      content: item
      nativeSelectOption: nativeSelectOptionView
      component: this
    proxies.pushObject(newProxy)

  didDestroyNativeSelectOption: (item) ->
    proxies = @get('proxies')
    proxies.removeObject(proxies.findBy('content', item))

  visibleProxies: ( ->
    @get('proxies').filterBy('isVisible')
  ).property('proxies.@each.isVisible')

  allAreSelected: ( ->
    @get('selection.length') is @get('content.length')
  ).property('selection.length', 'content.length')

  _matcher: ( ->
    @get('matcher') or defaultMatcher
  ).property('matcher')

  focusIn: ->
    @send('open')

  focusOut: ->
    @send('close')

  insertItem:  ->
    query = @get('query') or ''
    query = query.trim()
    if query.length > 0
      @get('inserts').pushObject(query)
      @set('query', '')
      true

  actions:
    deactivateAll: ->
      @get('proxies').invoke('send', 'deactivate')

    clickedInputBox: ->
      return if @get('disabled')
      if @get('isOpened')
        this.$().blur()
        @get('queryInput').$().blur()
      else
        @send('open')
        @send('focusInTextField')

    open: ->
      unless @get('disabled')
        @set('isOpened', true)
        @set('didFocusOnce', true)

    close: ->
      @set('isOpened', false) unless @get('disabled')

    focusInTextField: ->
      @get('queryInput').$().focus() unless @get('disabled')

    removeManualInsert: (item) ->
      @get('inserts').removeObject(item)

`export default SelectBoxComponent`
