`import elementObjectClass from './views/element'`

util = {}

util.generateName = (obj) ->
  if util.isString(obj)
    $matches = $('<body/>').html(obj).find('div,p,h1,h2,figure').each (->
      name = Ember.uuid()
      $(this).attr('data-name', name)
    )
    $matches.end().html()
  else if util.isDOMElement(obj)
    name = Ember.uuid()
    obj.setAttribute('data-name', name)
    obj
  else if util.isJqueryObject(obj)
    name = Ember.uuid()
    obj.attr('data-name', name)

util.getDOMElements = ($wrapper) ->
  els = $wrapper.find('*[data-name],*[data-placeholder]')
  els.each (index, el) ->
    util.generateName(el) unless el.hasAttribute('data-name')
  els

# DOM Node to element Object
util.serializeElement = (el, component, options = {}) ->
  $el = $(el)
  properties = options
  properties._el = el
  $(el.attributes).toArray().forEach (attribute) ->
    properties[attribute.nodeName] = attribute.value
  properties.component = component

  elementObjectClass.create(properties)

# Construct body by deserializing each element
util.serializeBody = (elements, changedElement) ->
  elements.sortBy('contentIndex').reduce((body, element) ->
    isChangedElement = element is changedElement
    if isChangedElement and element.get('isDestroyed')
      body
    else if isChangedElement
      body + util.deserializeElement(element)
    else
      body + element.get('computedHtml')
  , '')

# Javascript Object to HTML
util.deserializeElement = (object) ->
  object.html()

util.getElementByDOMElement = (domElement, elementObjects) ->
  (elementObjects or []).findBy('data-name', domElement.getAttribute('data-name')) if domElement and domElement.getAttribute

util.getParentDOMElement = (node) ->
  while node.parentNode and node.attributes and typeof node.attributes['data-name'] is 'undefined'
    node = node.parentNode

  node

util.getParentElement = (node, elementObjects) ->
  util.getElementByDOMElement(util.getParentDOMElement(node), elementObjects)

util.getSelectionStart = ->
  if window.getSelection
    selection = window.getSelection()
    node = selection.anchorNode
  else if document.selection
    selection = document.selection
    range = (if selection.getRangeAt then selection.getRangeAt(0) else selection.createRange())
    node = (if range.commonAncestorContainer then range.commonAncestorContainer else (if range.parentElement then range.parentElement() else range.item(0)))

  node = node.parentNode if node and (node.nodeName is '#text')
  node

util.getElementStart = ->
  node = util.getSelectionStart()
  $(node).closest('[data-name]').get(0)

util.getSelectionHtml = ->
  html = ""
  unless typeof window.getSelection is "undefined"
    sel = window.getSelection()
    if sel.rangeCount
      container = document.createElement("div")
      i = 0
      len = sel.rangeCount

      while i < len
        container.appendChild sel.getRangeAt(i).cloneContents()
        ++i
      html = container.innerHTML
  else html = document.selection.createRange().htmlText  if document.selection.type is "Text"  unless typeof document.selection is "undefined"
  html

util.getSelectionText = ->
  if window.getSelection
    window.getSelection().toString()
  else if document.selection and document.selection.type is 'Text'
    document.selection.createRange().text
  else
    ''

util.getSelectedElements = (component) ->
  elementObjects = component.get('elementsView.elements')
  selectedHtml = util.getSelectionHtml()

  # used when current selection crosses multiple elements
  $el = $('<body/>').html(selectedHtml)
  domElements = util.getDOMElements($el)

  # used when current selection is confined within a single element
  if domElements.length < 1
    $el = $('<body/>').html(util.getElementStart().outerHTML)
    domElements = util.getDOMElements($el)

  domElements.toArray().map (domElement) ->
    util.getElementByDOMElement(domElement, elementObjects)

util.getSelectedNodes = (range) ->
  getNextNode = (node) ->
    return node.firstChild if node.firstChild
    while node
      return node.nextSibling if node.nextSibling
      node = node.parentNode

  start = range.startContainer
  end = range.endContainer
  commonAncestor = range.commonAncestorContainer
  nodes = []

  # walk parent nodes from start to common ancestor
  node = start.parentNode
  while node
    nodes.push node
    break  if node is commonAncestor
    node = node.parentNode
  nodes.reverse()

  # walk children and siblings from start until end is found
  node = start
  while node
    nodes.push node
    break if node is end
    node = getNextNode(node)
  nodes

util.getTextFromCaretToEndOfElement = ->
  sel = window.getSelection()
  if sel.rangeCount
    selRange = sel.getRangeAt(0)
    el = util.getSelectionStart()
    if el
      range = selRange.cloneRange()
      range.selectNodeContents el
      range.setStart selRange.endContainer, selRange.endOffset
      range.cloneContents().textContent

util.getCaretOffsets = (element, range) ->
  range = range or window.getSelection().getRangeAt(0)
  preCaretRange = range.cloneRange()
  postCaretRange = range.cloneRange()
  preCaretRange.selectNodeContents element
  preCaretRange.setEnd range.endContainer, range.endOffset
  postCaretRange.selectNodeContents element
  postCaretRange.setStart range.endContainer, range.endOffset
  {
    left: preCaretRange.toString().length
    right: postCaretRange.toString().length
  }

util.isSelectionWithin = (selector) ->
  selection = util.getSelectionStart()
  $selection = $(selection)
  if $selection.is(selector)
    $selection.get(0)
  else if $match = $selection.is(selector) and $match.length > 0
    $match.get(0)
  else
    false

util.isSelectionWithinEmptyListItem = ->
  selection = util.getSelectionStart()
  $li = if selection.tagName is 'LI' then $(selection) else $(selection).closest('li')
  not Ember.isEmpty($li) and $li.text().length < 1

util.setSelection = (el, controller) ->
  range = document.createRange()
  range.selectNodeContents(el)
  sel = window.getSelection()
  sel.removeAllRanges()
  sel.addRange(range)
  controller.send('setSelectedText') if controller

util.saveSelection = ->
  if window.getSelection
    sel = window.getSelection()
    if sel.getRangeAt and sel.rangeCount
      ranges = []
      i = 0
      len = sel.rangeCount

      while i < len
        ranges.push sel.getRangeAt(i)
        ++i
      return ranges
  else if document.selection and document.selection.createRange
    document.selection.createRange()

util.restoreSelection = (savedSel) ->
  if savedSel
    if window.getSelection
      sel = window.getSelection()
      sel.removeAllRanges()
      i = 0
      len = savedSel.length

      while i < len
        sel.addRange savedSel[i]
        ++i
    else if document.selection and savedSel.select
      savedSel.select()

util.moveCursorAtBeginning = (el) ->
  Ember.run.later ->
    if window.getSelection and document.createRange
      range = document.createRange()
      range.selectNodeContents(el)
      range.collapse true
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange(range)
    else if document.body.createTextRange
      range = document.body.createTextRange()
      range.moveToElementText(el)
      range.collapse(true)
      range.select()
  , 1

util.moveCursorAtEnd = (el) ->
  Ember.run.later ->
    if window.getSelection and document.createRange
      range = document.createRange()
      range.selectNodeContents el
      range.collapse false
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange range
    else if document.body.createTextRange
      textRange = document.body.createTextRange()
      textRange.moveToElementText el
      textRange.collapse false
      textRange.select()
  , 1

util.moveCursorAfter = (el) ->
  if window.getSelection
    range = document.createRange()
    range.setStartAfter el
    range.collapse true
    selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange range

util.moveCursorBefore = (el) ->
  if window.getSelection
    range = document.createRange()
    range.setStartBefore el
    range.collapse true
    selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange range

util.insertHTMLCommand = (html) ->
  document = window.document
  return document.execCommand("insertHTML", false, html) if document.queryCommandSupported("insertHTML")
  selection = window.getSelection()
  if selection.getRangeAt and selection.rangeCount
    range = selection.getRangeAt(0)
    range.deleteContents()
    el = document.createElement("div")
    el.innerHTML = html
    fragment = document.createDocumentFragment()
    while el.firstChild
      node = el.firstChild
      lastNode = fragment.appendChild(node)
    range.insertNode fragment

    # Preserve the selection:
    if lastNode
      range = range.cloneRange()
      range.setStartAfter lastNode
      range.collapse true
      selection.removeAllRanges()
      selection.addRange range

util.cleanPaste = (component, elementObject, text) ->
  elementsView = component.get('elementsView')
  elements = elementsView.$().get(0)
  element = elementObject.get('element').get(0)

  console.log('START PASTE INPUT')
  console.log(text)
  console.log('END PASTE INPUT')

  multiline = /<p|<br|<div|<h1|<h2|<ul/.test(text)
  # Grab HTML tags with: <TAG\b[^>]*>(.*?)</TAG>
  # See http://www.regular-expressions.info/examples.html
  tagRegex = (tagName) ->
    "<#{tagName}\\b[^>]*>(.*?)<\/#{tagName}>"

  replacements = [
    # replace all 3 types of line breaks with a space
    [
      /(\r\n|\n|\r)/gm
      " "
    ]
    # remove <DOCTYPE>
    [
      new RegExp(/<!DOCTYPE\b[^>]*>/g)
      ""
    ]
    # replace two bogus tags that begin pastes from google docs
    [
      new RegExp(/<[^>]*docs-internal-guid[^>]*>/g)
      ""
    ]
    [
      new RegExp(/<\/b>(<br[^>]*>)?$/g)
      ""
    ]
    # un-html spaces and newlines inserted by OS X
    [
      new RegExp(/<span class="Apple-converted-space">\s+<\/span>/g)
      " "
    ]
    [
      new RegExp(/<br class="Apple-interchange-newline">/g)
      "<br>"
    ]
    # replace google docs italics+bold with a span to be replaced once the html is inserted
    [
      new RegExp(/<span[^>]*(font-style:italic;font-weight:bold|font-weight:bold;font-style:italic)[^>]*>/g)
      "<span class=\"replace-with italic bold\">"
    ]
    # replace google docs italics with a span to be replaced once the html is inserted
    [
      new RegExp(/<span[^>]*font-style:italic[^>]*>/g)
      "<span class=\"replace-with italic\">"
    ]
    #[replace google docs bolds with a span to be replaced once the html is inserted
    [
      new RegExp(/<span[^>]*font-weight:bold[^>]*>/g)
      "<span class=\"replace-with bold\">"
    ]
    # replace manually entered b/i/a tags with real ones
    [
      new RegExp(/&lt;(\/?)(i|b|a)&gt;/g)
      "<$1$2>"
    ]
    # replace manually a tags with real ones, converting smart-quotes from google docs
    [
      new RegExp(/&lt;a\s+href=(&quot;|&rdquo;|&ldquo;|“|”)([^&]+)(&quot;|&rdquo;|&ldquo;|“|”)&gt;/g)
      "<a href=\"$2\">"
    ]
    # replace strong with b
    [
      new RegExp(tagRegex('strong'), 'g')
      "<b>$1<\/b>"
    ]
    # replace em with i
    [
      new RegExp(tagRegex('em'), 'g')
      "<i>$1<\/i>"
    ]
  ]

  # unwrap some tags
  [
    "html"
    "body"
    "code"
    "dt"
    "dd"
    "button"
    "label"
    "textarea"
    "fieldset"
    "select"
    "option"
    "caption"
    "tbody"
    "thead"
    "tr"
    "td"
    "th"
    "tfoot"
    "font"
    "form"
    "time"
  ].forEach (tagName) ->
    replacements.push([new RegExp(tagRegex(tagName), 'g'), "$1"])

  # remove some tags
  [
    "head"
    "title"
    "style"
    "select"
    "option"
    "meta"
    "canvas"
    "iframe"
    "object"
    "script",
    "noscript",
    "xsl:variable"
  ].forEach (tagName) ->
    replacements.push([new RegExp(tagRegex(tagName), 'g'), ""])

  # remove some singleton tags
  [
    "input"
    "area"
    "base"
    "col"
    "command"
    "embed"
    "keygen"
    "track"
    "wbr"
    "link"
    "meta"
    "param"
    "source"
    "base"
  ].forEach (tagName) ->
    replacements.push([new RegExp("<#{tagName}\\b[^>\/]*\/?>", 'g'), ""])

  # replace with p
  [
    "h3"
    "h4"
    "h5"
    "h6"
    "table"
    "address"
    "dl"
    "div"
    "blockquote"
    "aside"
    "header"
    "section"
    "hgroup"
    "figure"
    "pre"
  ].forEach (tagName) ->
    replacements.push([new RegExp("<#{tagName}\\b[^>]*>", 'g'), "<p>"])
    replacements.push([new RegExp("<\/#{tagName}>", 'g'), "</p>"])

  # replace ol,menu,dir with ul
  [
    "ol"
    "menu"
    "dir"
  ].forEach (tagName) ->
    replacements.push([new RegExp(tagRegex(tagName), 'g'), "<ul>$1<\/ul>"])

  i = 0
  while i < replacements.length
    text = text.replace(replacements[i][0], replacements[i][1])
    i += 1

  isEmpty = elementObject.get('isEmpty')

  if multiline
    # double br's aren't converted to p tags, but we want p's.
    elList = text.split("<br><br>")
    text = "<p>" + elList.join("</p><p>") + "</p>"

    prepend = if isEmpty or component.get('isTextSelected') then '' else '<br>'

    util.pasteHTML(text, prepend, true)

    # Format and cleanup
    elList = elements.querySelectorAll("a,br,img")
    i = 0
    while i < elList.length
      workEl = elList[i]
      workElTagName = workEl.tagName.toLowerCase()
      if workElTagName is 'a'
        util.setTargetBlank workEl
      else if workElTagName is 'br'
        util.filterLineBreak workEl
      else if workElTagName is 'img'
        util.removeBrokenImages workEl
      i += 1

    # Remove empty <p>
    elList = elements.querySelectorAll("p")
    i = 0
    while i < elList.length
      util.filterCommonBlocks elList[i]
      i += 1

    # Generate data-names
    elList = elements.children
    i = 0
    while i < elList.length
      workEl = elList[i]
      workElTagName = workEl.tagName.toLowerCase()
      if ['p', 'h1', 'h2'].contains(workElTagName)
        util.generateName(workEl) unless workEl.hasAttribute('data-name')
      i += 1

    # Upload images
    # elList = elements.querySelector('img')
    # i = 0
    # while i < elList.length
    #   workEl = elList[i]
    #   src = workEl.getAttribute('src')
  else
    util.pasteHTML(text, '', false)

util.pasteHTML = (html, prepend, multiline) ->
  pasteBlock = window.document.createDocumentFragment()
  pasteBlock.appendChild window.document.createElement("body")
  fragmentBody = pasteBlock.querySelector("body")
  fragmentBody.innerHTML = html
  util.cleanupSpans fragmentBody

  # Delete ugly attributes
  elList = fragmentBody.querySelectorAll("*")
  i = 0
  while i < elList.length
    el = elList[i]
    el.removeAttribute "class"
    el.removeAttribute "style"
    el.removeAttribute "dir"
    el.removeAttribute "title"
    el.removeAttribute "name"
    el.removeAttribute "id"
    el.removeAttribute "itemprop"
    el.removeAttribute "align"
    ++i

  html = prepend + fragmentBody.innerHTML.replace(/&nbsp;/g, " ")
  html = html + '<p><br></p>' if multiline
  util.insertHTMLCommand(html)

util.setTargetBlank = (el) ->
  el = el or util.getSelectionStart()
  if el.tagName.toLowerCase() is "a"
    el.target = "_blank"
  else
    el = el.getElementsByTagName("a")
    i = 0
    while i < el.length
      el[i].target = "_blank"
      i += 1

util.filterCommonBlocks = (el) ->
  if el.innerHTML.trim().length < 1
    if $(util.getSelectionStart()).closest(el).length > 0
      # If the cursor is in this block element, move it to previous sibling
      util.moveCursorAtEnd(el.previousSibling)
    Ember.run -> el.parentNode.removeChild el

util.filterLineBreak = (el) ->
  if util.isCommonBlock(el.previousElementSibling)
    # remove stray br's following common block elements
    el.parentNode.removeChild el
  else if util.isCommonBlock(el.parentNode) and
      (el.parentNode.firstChild is el or el.parentNode.lastChild is el)
    # remove br's just inside open or close tags of a p
    el.parentNode.removeChild el
  # and br's that are the only child of a p
  else if el.parentNode.childElementCount is 1 and el.parentNode.textContent is ''
    util.removeWithParent el

util.removeBrokenImages = (el) ->
  el.onerror = ->
    $this = $(this)
    parentParagraph = $this.closest('p')
    $this.remove()
    Ember.run -> util.filterCommonBlocks(parentParagraph.get(0))

util.removeWithParent = (el) ->
  if el and el.parentNode
    if el.parentNode.parentNode and el.parentNode.childElementCount is 1
      el.parentNode.parentNode.removeChild el.parentNode
    else
      el.parentNode.removeChild el.parentNode

util.cleanupSpans = (container_el) ->
  spans = container_el.querySelectorAll(".replace-with")
  i = 0
  while i < spans.length
    el = spans[i]
    new_el = window.document.createElement((if el.classList.contains("bold") then "b" else "i"))
    if el.classList.contains("bold") and el.classList.contains("italic")
      # add an i tag as well if this has both italics and bold
      new_el.innerHTML = "<i>" + el.innerHTML + "</i>"
    else
      new_el.innerHTML = el.innerHTML
    el.parentNode.replaceChild new_el, el
    i += 1

  spans = container_el.querySelectorAll("span")
  i = 0
  while i < spans.length
    el = spans[i]
    # remove empty spans, replace others with their contents
    if /^\s*$/.test(el.innerHTML)
      el.parentNode.removeChild el
    else
      $(el).contents().unwrap()
    i += 1

util.isCommonBlock = (el) ->
  el and (el.tagName.toLowerCase() is "p")

util.isDOMElement = (obj) ->
  if obj.tagName then true else false

util.isJqueryObject = (obj) ->
  obj instanceof jQuery

util.isString = (obj) ->
  (typeof obj is 'string') or (obj instanceof String)

util.htmlEntities = (str) ->
  # converts special characters (like <) into their escaped/encoded values (like &lt;).
  # This allows you to show to display the string without the browser reading it as HTML.
  String(str).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace /"/g, "&quot;"

util.nativeExecCommand = (command, showDefault = false, value = null) ->
  document.execCommand(command, showDefault, value)

util.stripHtml = (string) ->
  $('<div>').html(string).text().trim()

util.getExternalContents = ($el) ->
  $el.find('[data-external-content-id]')

util.containsExternalContent = ($el) ->
  util.getExternalContents($el).length > 0

# String starts with 'http:', 'ftp:', 'mailto:', ......
util.urlHasScheme  = (str) ->
  regex = /^[A-Za-z0-9\+\.\-]+\:/
  regex.test(str)

util.safeAttribute = (s, preserveCR) ->
  preserveCR = if preserveCR then '&#13;' else '\n'
  ('' + s)
  .replace(/&/g, '&amp;')
  .replace(/'/g, '&apos;')
  .replace(/"/g, '&quot;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;')
  .replace(/\r\n/g, preserveCR)
  .replace(/[\r\n]/g, preserveCR)

# ---
# generated by js2coffee 2.0.0

util.isEnterKey = (event) ->
  keyCode = event.keyCode || event.which
  keyCode is 13

util.isBackspaceKey = (event) ->
  keyCode = event.keyCode || event.which
  keyCode is 8

util.isTabKey = (event) ->
  keyCode = event.keyCode || event.which
  keyCode is 9

util.isEscKey = (event) ->
  keyCode = event.keyCode || event.which
  keyCode is 27

util.triggerShortcut = ($component, event) ->
  keyCode = event.keyCode || event.which
  isMetaKey = event.metaKey
  isAltKey = event.altKey
  # ⌘ + B, Ctrl + B => Bold
  # ⌘ + I, Ctrl + I => Italic
  # Above are handled natively

  # ⌘ + U, Ctrl + U => Underline
  if isMetaKey and keyCode is 85
    return $component.find('.editor-toolbar li.underline a').trigger('click')

  # ⌘ + K, Ctrl + K => Link
  if isMetaKey and keyCode is 75
    return $component.find('.editor-toolbar li.link a').trigger('click')

  # ⌘ + Alt + 1, Ctrl + Alt + 1 => H1
  if isMetaKey and isAltKey and keyCode is 49
    return $component.find('.editor-toolbar li.h1 a').trigger('click')

  # ⌘ + Alt + 2, Ctrl + Alt + 2 => H2
  if isMetaKey and isAltKey and keyCode is 50
    return $component.find('.editor-toolbar li.h2 a').trigger('click')

`export default util`
