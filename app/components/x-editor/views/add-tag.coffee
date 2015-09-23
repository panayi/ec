`import Ember from 'ember'`

debouncedObserver = (keys..., time, func, immediate) ->
  Em.observer ->
    Em.run.debounce @, func, time, immediate
  , keys...

addTagView = Ember.View.extend
  classNames: ['add-tag']
  isVisible: false

  tags: Ember.computed.alias('component.tags')
  selectedAndEmptyElement: Ember.computed.alias('component.selectedAndEmptyElement')
  elementsView: Ember.computed.alias('component.elementsView')
  elements: Ember.computed.alias('component.elementsView.elements')

  followSelectedAndEmptyElement: debouncedObserver('selectedAndEmptyElement', 'elements.@each.isDestroyed', 'isInserted', 100, ->
    return unless @get('isInserted')
    selectedAndEmptyElement = @get('selectedAndEmptyElement')
    element = selectedAndEmptyElement and selectedAndEmptyElement.get('element')
    unless Ember.isEmpty(element)
      position = element.position()
      height = element.height()
      this.$().css({ top: position.top + height/2, left: position.left - 40 })
      Ember.run =>
        @set('isVisible', true)
    else
      @set('isVisible', false)
  , false)

  setIsInserted: ( ->
    @set('isInserted', true)
  ).on('didInsertElement')

  actions:
    clickedTag: (tag) ->
      if tag.type is 'image'
        @get('component').send('triggerFileUpload')
      # else # TODO: add more tags, like video

    escKeyPressed: (event) ->
      if @get('isOpened')
        event.stopPropagation()
        @set('isOpened', false)

`export default addTagView`
