`import Ember from 'ember'`

readFile = (file, callback) ->
  reader = new FileReader()
  reader.onload = callback
  reader.readAsDataURL(file)

XEditorController = Ember.Controller.extend
  exportHref: ( ->
    body = @get('model.body') or ''
    'data:text/html;charset=utf-8,' + encodeURIComponent(body)
  ).property('model.body')

  actions:
    uploadFiles: (files, elementObject) ->
      files = [files] if files instanceof File
      length = files.length
      [0..length-1].map (index) =>
        readFile files[index], (event) =>
          @get('editorInstance').send('attachFile', event.target.result, elementObject)



`export default XEditorController`
