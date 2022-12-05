import htmlgen, strformat

proc modal* (id: string): tuple[markup: string, js: string, css: string] =
  let markup = `div`(
    id=id,
    class="modal",
    `div`(class="modal-content")
  )

  let styles = """
  .modal { display: none; position: fixed; z-index: 1; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0,0.4); }
  .modal-content { background-color: #fefefe; margin: 15% auto; padding: 20px; border: 1px solid #888; width: 80%; height: 500px; }
  .close { color: #aaa; float: right; font-size: 28px; font-weight: bold; }
  .close: hover, .close: focus { color: black; text-decoration: none; cursor: pointer; }
  """

  let winContent = &"""
    const modal = document.getElementById("{id}");
    if (ev.target == modal) modal.style.display = "none";
    if (ev.target == modal) window.location.reload();
  """
  let win = "window.onclick = ev =>{" & winContent & "}"

  let content = &"""
    let modal = document.getElementById("{id}");
    modal.style.display = "block";
    const frame = document.createElement("iframe");
    frame.src = url;
    frame.style = "minWidth: 500px; minHeight: 500px; width: 100%; height: 100%";
    while (modal.firstChild.firstChild) modal.firstChild.removeChild(modal.firstChild.firstChild);
    modal.firstChild.appendChild(frame);
    modal.firstChild.focus();
    {win}
  """
  let body = "{" & content & "}"
  let js = &"const show_{id} = (url) => {body}"

  result = (markup: markup, js: js, css: styles)

proc postButton* (label, url: string): string =
  form(action=url, `method`="post", input(type="submit", value=label))