document$.subscribe(({ body }) => {
  GraphViewer.processElements()
})