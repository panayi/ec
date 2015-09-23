`import Ember from 'ember'`

PopOverBodyComponent = Ember.Component.extend
  classNames: ['popover-body']
  classNameBindings: ['isOpened']

  isOpened: Ember.computed.alias('parentView.isOpened')
  openOnHover: Ember.computed.alias('parentView.openOnHover')
  hoverChild: Ember.computed.alias('parentView.hoverChild')
  offsetTop: Ember.computed.alias('parentView.offsetTop')
  offsetLeft: Ember.computed.alias('parentView.offsetLeft')
  parentWidth: Ember.computed.alias('parentView.width')
  parentHeight: Ember.computed.alias('parentView.height')
  popoverDirectionAbove: Ember.computed.alias('parentView.popoverDirectionAbove')
  popoverDirectionBelow: Ember.computed.alias('parentView.popoverDirectionBelow')
  popoverDirectionLeft: Ember.computed.alias('parentView.popoverDirectionLeft')
  popoverDirectionRight: Ember.computed.alias('parentView.popoverDirectionRight')
  popoverDirectionMiddle: Ember.computed.alias('parentView.popoverDirectionMiddle')

  offsetDidChange: (->
    top = @get 'offsetTop'
    left = @get 'offsetLeft'
    width = @get 'parentWidth'
    height = @get 'parentHeight'

    top = top + height if @get('popoverDirectionBelow')

    if @get('popoverDirectionLeft')
      left = left + width
    else if @get('popoverDirectionMiddle')
      left = left + width/2


    this.$().css 'left', left
    this.$().css 'top', top
  ).observes('offsetTop,offsetLeft,parentWidth,parentHeight,popoverDirectionBelow,popoverDirectionLeft,popoverDirectionMiddle')

  moveToRoot: ( ->
    this.$().appendTo('body')
  ).on('didInsertElement')

  isAbove: (->
    this.$().addClass 'popover-above' if @get('popoverDirectionAbove')
  ).observes('popoverDirectionAbove')
  isBelow: (->
    this.$().addClass 'popover-below' if @get('popoverDirectionBelow')
  ).observes('popoverDirectionBelow')
  isLeft: (->
    this.$().addClass 'popover-left' if @get('popoverDirectionLeft')
  ).observes('popoverDirectionLeft')
  isRight: (->
    this.$().addClass 'popover-right' if @get('popoverDirectionRight')
  ).observes('popoverDirectionRight')
  isMiddle: (->
    this.$().addClass 'popover-middle' if @get('popoverDirectionMiddle')
  ).observes('popoverDirectionMiddle')

  removeOnDestroy: ( ->
    this.$().remove()
  ).on('willDestroyElement')

  mouseEnter: ->
    @set 'hoverChild', true

  mouseLeave: ->
    @set 'hoverChild', false
    @set 'isOpened', false if @get('openOnHover')

`export default PopOverBodyComponent`
