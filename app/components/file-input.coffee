`import Ember from 'ember'`

FileInputComponent = Ember.Component.extend
  multiple: false
  drop: false
  hideList: false

  fileInput: Ember.TextField.extend
    type: 'file'
    attributeBindings: ['multiple']
    multiple: Ember.computed.alias('component.multiple')

    inputDidChange: ( ->
      fileList = this.$()[0].files
      @get('component').addFiles(fileList)
    ).on('change')

  addFiles: (fileList) ->
    @initialize()
    length = fileList.length
    unless @get('multiple')
      @get('files').forEach (file) =>
        @send('remove', file)
    if length > 0
      [0..length-1].forEach (index) =>
        file = fileList[index]
        @send('add', file)
      @didAddFiles()

  didAddFiles: ->
    param = @get('param')
    files = @get('files')
    files = files[0] unless @get('multiple')
    @sendAction('onSelect', files, param)

  initialize: ( ->
    @set('files', [])
  ).on('init')

  actions:
    add: (file) ->
      @get('files').pushObject(file)

    remove: (file) ->
      @get('files').removeObject(file)
      @sendAction('onDeselect', file, @get('param'))

    drop: (event) ->
      fileList = event.dataTransfer.files
      @addFiles(fileList) if fileList.length > 0

`export default FileInputComponent`
