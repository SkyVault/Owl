import htmlgen, strformat, strutils

proc modal* (id: string): tuple[markup: string, js: string, css: string] =
  let markup = `div`(
    id=id,
    class="modal",
    `div`(class="modal-content")
  )

  let styles = """
  .modal { 
    display: none; position: fixed; z-index: 1; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0,0.4); }
  .modal-content { 
    background-color: black;
    color: white;
    margin-left: auto; margin-right: auto;
    padding: 4px; top: 0; border: 1px solid white; width: 500px; height: 500px }
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
    frame.style = "width: 100%; height: 100%; background-color: black;";
    while (modal.firstChild.firstChild) modal.firstChild.removeChild(modal.firstChild.firstChild);
    modal.firstChild.appendChild(frame);
    modal.firstChild.focus();
    {win}
  """
  let body = "{" & content & "}"
  let js = &"const show_{id} = (url) => {body}"

  result = (markup: markup, js: js, css: styles)

const BTN_STYLE = "rounded-full px-2 text-black"

proc pageBase* (children: varargs[string]): string =
  let (m, modalJs, modalCss) = modal("modal")
  `div`(
    script(src="https://cdn.tailwindcss.com"),
    script(modalJs),
    style(modalCss),
    style("""
      body { background-color: black; color: white; } 
    """),
    m,
    class="max-w-lg mx-auto",
    children.join("\n"),
  )

proc textInput* (name: string, label: string): string =
  `div`(
    label(`for`=name, label & ": "), 
    input(class="bg-slate-700 text-white", type="text", name=name)
  )

proc submitInputButton* (label: string): string =
  input(type="submit", value=label, class=fmt"{BTN_STYLE} bg-green-300")

proc actionButton* (title, onclick, color = "bg-blue-300"): string =
  button(class=fmt"{BTN_STYLE} {color}", onclick=onclick, title)

proc postButton* (label, url: string): string =
  form(style="margin: 0;", action=url, `method`="post", 
    input(class=fmt"{BTN_STYLE} bg-red-300", type="submit", value=label))

proc reloadParent* (): string =
  discard """
    Used to reload the parent of a iframe, useful for closing modals and refreshing contents
  """
  script("window.parent.location.reload()")

proc reload* (): string =
  script("window.location.reload()")