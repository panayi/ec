`import Ember from 'ember'`

PopOverComponent = Ember.Component.extend
  classNames: ['popover']
  classNameBindings: ['isOpened', 'openOnHover']

  openOnHover: true
  isOpened: false
  hoverChild: false
  offsetTop: 0
  offsetLeft: 0
  height: 0
  width: 0
  popoverDirectionAbove: false
  popoverDirectionBelow: false
  popoverDirectionLeft: false
  popoverDirectionRight: false
  popoverDirectionMiddle: false

  setupPosition: ( ->
    @setOffset()
    @setDirection()
  ).on('didInsertElement')


  click: ->
    @setOffset()
    unless @get('openOnHover') or @get('isOpened')
      @set('isOpened', true)

  setOffset: ->
    @set 'offsetLeft', this.$().offset().left
    @set 'offsetTop', this.$().offset().top
    @set 'height', this.$().outerHeight()
    @set 'width', this.$().outerWidth()

  setDirection: ->
    closest = this.$().closest '.popover-direction'

    if closest.attr('class')?
      classes = closest.attr('class').split(/\s+/)

      hasClass = false
      for className in classes
        switch className.trim().toLowerCase()
          when 'popover-above' then @set('popoverDirectionAbove', true)
          when 'popover-below'
            @set('popoverDirectionBelow', true)
            hasClass = true
          when 'popover-left'
            @set('popoverDirectionLeft', true)
            hasClass = true
          when 'popover-right'
            @set('popoverDirectionRight', true)
            hasClass = true
          when 'popover-middle'
            @set('popoverDirectionMiddle', true)
            hasClass = true

      @set('popoverDirectionAbove', not hasClass)

  isOpenedDidChange: ( ->
    if @get('isOpened')
      $('body').on 'click.closePopover', =>
        @set('isOpened', false) if not @get('isDestroyed') and not @get('isDestroying')
    else
      $('body').off('click.closePopover')
  ).observes('isOpened')

  mouseEnter: (event)->
    @setOffset()
    @set 'isOpened', true  if @get 'openOnHover'

  mouseLeave: (event)->
    setTimeout ( =>
      @set 'isOpened', false  if @get('openOnHover') and not @get('hoverChild')
    ), 50

`export default PopOverComponent`
