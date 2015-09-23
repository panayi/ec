`import Ember from 'ember'`

linkPopoverView = Ember.View.extend
  classNames: ['link-popover']
  classNameBindings: ['isMouseOver']

  elementsView: Ember.computed.alias('component.elementsView')
  isTextSelected: Ember.computed.alias('component.isTextSelected')

  mouseEnteredLink: (event) ->
    return if @get('isTextSelected')

    $this = this.$()
    $target = $(event.target).closest('a')
    href = $target.attr('href')
    return unless href

    @setProperties
      isMouseOver: true
      anchor: href

    targetPosition = $target.position()
    targetHeight = $target.outerHeight()
    targetWidth = $target.outerWidth()
    top = targetPosition.top + targetHeight
    left = targetPosition.left + targetWidth/2
    $this.css({ top: top, left: left, position: 'absolute' })

  mouseLeftLink: (event) ->
    @set('isMouseOver', false)

  onTextSelect: ( ->
    @set('isMouseOver', false) if @get('isTextSelected')
  ).observes('isTextSelected')

  bindHoverLinksEvent: ( ->
    elementsView = @get('elementsView')
    return unless elementsView and elementsView.get('isInserted')

    elementsView.$().on('mouseenter.editorLinkHover', 'a', @mouseEnteredLink.bind(this))
    elementsView.$().on('mouseleave.editorLinkHover', 'a', @mouseLeftLink.bind(this))
  ).on('didInsertElement').observes('elementsView.isInserted')

  teardownHoverLinksEvent: ( ->
    elementsView = @get('elementsView')
    elementsView.$().off('mouseenter.editorLinkHover', 'a', @mouseEnteredLink.bind(this))
    elementsView.$().off('mouseleave.editorLinkHover', 'a', @mouseLeftLink.bind(this))
  ).on('willDestroyElement')

`export default linkPopoverView`
