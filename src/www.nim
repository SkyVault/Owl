import htmlgen, strformat, strutils

proc modal* (id: string): tuple[markup: string, js: string, css: string] =
  let markup = `div`(
    id=id,
    class="modal",
    `div`(class="modal-content")
  )

  let styles = """
  .modal { display: none; position: fixed; z-index: 1; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0,0.4); }
  .modal-content { background-color: black; color: white; margin-left: auto; margin-right: auto; padding: 4px; top: 0; border: 1px solid white; width: 500px; height: 500px }
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

proc selectionModal* (id: string): tuple[markup, js, css: string] =
  let markup = `div`(
    id=id,
    class="smodal",
    `div`(class="smodal-content")
  )
  let styles = """
  .smodal { display: none; position: fixed; z-index: 1; width: 100%; height: 100% }
  .smodal-content { background-color: black; color: white; margin-left: auto; margin-right: auto; padding: 4px; top: 0; border: 1px solid white; width: 100px; }
  """

  let winContent = &"""
    const modal = document.getElementById("{id}");
    if (ev.target == modal) modal.style.display = "none";
  """
  let win = "window.onclick = ev =>{" & winContent & "}"

  let content = fmt"""
    let modal = document.getElementById("{id}");
    modal.style.display = "block";
    modal.style.left = "0";

    const container = document.createElement("div");
    container.class = "flex flex-column";

    xs.forEach(x => {{ 
      const item = document.createElement('div');
      item.class = "text-white underline px-2 rounded-full mb-1 bg-pink-300";
      item.innerText = x;
      item.onclick = () => call(x);
      container.appendChild(item);
    }});

    container.style = "width: 100%; height: 100%; background-color: black;";

    while (modal.firstChild.firstChild) modal.firstChild.removeChild(modal.firstChild.firstChild);
    modal.firstChild.appendChild(container);
    modal.firstChild.focus();
    {win}
  """
  let body = "{" & content & "}"
  var js = &"const open_{id} = (call, xs) => {body};"
  js &= &"const close_{id} = () => document.getElementById('{id}').style.display = 'none'";

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
    class="max-w-2xl mx-auto",
    children.join("\n"),
  )

proc textInput* (name: string, label: string): string =
  `div`(
    label(`for`=name, label & ": "), 
    input(class="bg-slate-700 text-white", type="text", name=name)
  )

proc textArea* (name: string, label: string): string =
  `div`(
    p(label & ": "),
    textarea(class="bg-slate-700 text-white", name=name, rows="6", cols="30")
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