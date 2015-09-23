options =
  # 'unorderedList' # TODO: currently breaks editor
  buttons: 'bold,italic,underline,h1,h2,fontColor,link'
  colors: [
    { value: '#1D2023', style: 'color:#1D2023;' }
    { value: '#B4722F', style: 'color:#B4722F;' }
    { value: '#59A80F', style: 'color:#59A80F;' }
    { value: '#1693A5', style: 'color:#1693A5;' }
    { value: '#9532F4', style: 'color:#9532F4;' }
    { value: '#B11623', style: 'color:#B11623;' }
    { value: '#FF003C', style: 'color:#FF003C;' }
    { value: '#FA6900', style: 'color:#FA6900;' }
    { value: '#FDCB35', style: 'color:#FDCB35;' }
  ]
  defaultBody: '<h1 data-placeholder="Title">
                  <span class="placeholder">Title</span><br>
                </h1>
                <p data-placeholder="Write a story...">
                  <span class="placeholder">Write a story...</span><br>
                </p>'
  tags: [
    {
      label: 'Insert Image'
      tagName: 'figure'
      type: 'image'
    }
  ]

`export default options`
