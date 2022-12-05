import htmlgen, oids, sets, os, sugar, strutils, uri, sequtils, strformat
import jester, pipe
import jsony
import fp/either
import www
import cascade
import types/database
import mutations/[collections, fragments]

type Action = tuple[title: string; actionEl: string]

proc actionTitle(title: string, actions: varargs[string]): string =
  span(
    style="display: flex; align-items: center; column-gap: 8px",
    `div`(class="text-xl", title), 
    `div`(style="display: flex; column-gap: 8px", actions.join(""))
  )

proc actionSubTitle(title: string, actions: varargs[string]): string =
  span(
    style="display: flex; align-items: center; column-gap: 8px; justify-content: space-between",
    p(title), 
    `div`(style="display: flex; column-gap: 8px", actions.join(""))
  )

proc statusLabel* (fragmentId: string, status: string, statusList: string): string =
    if status != "": 
      `div`(
        onclick=fmt"open_selection_modal((it) => {{ window.location.href = '/set-fragment-status/{fragmentId}/' + it; close_selection_modal() }}, [{statusList}])",
        class="text-pink-400 rounded bg-slate-700 px-2", 
        status
      ) 
    else: 
      ""

proc fragmentDetails(db: Database, fragmentId: string): string =
  let fragment = findFragment(db, fragmentId)
  let 
    (sm, smJs, smCss) = selectionModal("selection_modal")
    statuses = db.statuses()
    statusXs = collect(for s in statuses: &"'{s}'").join(", ")

  pageBase(
    sm,
    script(smJs),
    style(smCss),
    `div`(
      class="flex",
      `div`(class="text-3xl mt-2", fragment.title),
      statusLabel(fragment.id, fragment.status, statusXs)
    ),
    `div`(class="text-xl text-slate-400", fragment.description)
  )

proc collectionDetailsActions(db: Database, id: Id): string =
  span(
    actionButton("+", onclick="show_modal('/select-fragment/add-fragment-to-collection/" & id & "')", "bg-green-300")
  )

proc collectionDetails(db: Database, collectionId: string): string =
  let collection = findCollection(db, collectionId)
  let 
    (sm, smJs, smCss) = selectionModal("selection_modal")
    statuses = db.statuses()
    statusXs = collect(for s in statuses: &"'{s}'").join(", ")

  let fragments = collect:
    for id in collection.fragments.items:
      let frag = findFragment(db, id)
      `div`(
        class="flex justify-between mb-2 gap-2",
        `div`(
          class="flex gap-2",
          postButton("-", "/remove-fragment-from-collection/" & collectionId & "/" & frag.id),
          p(frag.title),
        ),
        statusLabel(frag.id, frag.status, statusXs)
      )

  pageBase(
    sm, script(smJs), style(smCss),
    `div`(class="text-3xl mt-2", collection.title),
    `div`(class="text-xl text-slate-400", collection.description),
    fragments.join(""), br(),
    collectionDetailsActions(db, collection.id)
  )

proc createFragmentForm(db: Database): string =
  let allStatuses = db.statuses()
  let os = collect(
    for s in allStatuses.items:
      option(value=s, s)
  ).join("\n")

  form(action="/new-fragment", `method`="post",
    script(src="https://cdn.tailwindcss.com"),
    `div`(
      class="text-white",
      `div`(class="text-3xl","NEW FRAGMENT"),
      textInput("title", "Title"), br(),
      textArea("description", "Description"), br(),
      `div`(
        label(`for`="status", "Status: "), 
        input(name="status", class="bg-slate-700 text-white", type="text", list="statuses")
      ),
      datalist(id="statuses", class="text-white bg-slate-700", os),
      br(),
      submitInputButton("Submit"),
    )
  )

proc createCollectionForm(db: Database): string =
  form(action="/new-collection", `method`="post",
    script(src="https://cdn.tailwindcss.com"),
    `div`(
      class="text-white",
      `div`(class="text-3xl", "NEW COLLECTION"),
      textInput("title", "Title"), br(),
      textArea("description", "Description"), br(),
      submitInputButton("Submit"),
    )
  )

proc selectFragment(db: Database, postPrefix, postDest: string): string =
  `div`(
    script(src="https://cdn.tailwindcss.com"),
    collect(
      for f in db.fragments:
        `div`(
          class="text-white flex gap-2",
          p(f.title), 
          actionButton("Select", onclick="window.location.href = '/" & postPrefix & "/" & postDest & "/" & f.id & "'"))
    ).join("")
  )

proc dashboard(db: Database): string =
  let 
    (sm, smJs, smCss) = selectionModal("selection_modal")
    statuses = db.statuses()
    statusXs = collect(for s in statuses: &"'{s}'").join(", ")

  pageBase(
    sm,
    script(smJs),
    style(smCss),
    `div`(class="text-4xl mb-2", "Database"),
    `div`(
      class="mb-4",
      actionTitle(
        "Collections",
        actionButton("+", onclick="show_modal('/create-collection')", "bg-green-300")
      ),
      ul(
        collect(
          for c in db.collections:
            `div`(
              class="mb-1",
              actionSubTitle(
                a(class="text-blue-600", onclick=fmt"show_modal('/collection/{c.id}')", c.title),
                actionButton("Open", onclick=fmt"window.location.href += 'collection/" & c.id & "'"),
                postButton("X", "/delete-collection/" & c.id)
              )
            )
        ).join("")
      )
    ),
    
    `div`(
      actionTitle(
        "Fragments",
        actionButton("+", onclick=fmt"show_modal('/create-fragment')", "bg-green-300")
      ),
      `div`(
        collect(
          for f in db.fragments:
            `div`(
              class="flex justify-between w-100 mb-2",
              `div`(
                class="flex flex-row gap-1",
                a(class="text-blue-600", onclick=fmt"show_modal('/fragment/{f.id}')", f.title),
              ),
              `div`(
                class="flex flex-row gap-1",
                statusLabel(f.id, f.status, statusXs),
                actionButton("Open", onclick=fmt"window.location.href += 'fragment/" & f.id & "'"),
                postButton("X", "/delete-fragment/" & f.id),
              )
            )
        ).join("")
      )
    )
  )

proc toTable* [K, V](xs: seq[tuple[key: K, value: V]]): Table[K, V] =
  for (k, v) in xs:
    result[k] = v

routes:
  get "/":
    resp dashboard(loadDatabase())
  
  get "/fragment/@fragment-id":
    resp fragmentDetails(loadDatabase(), @"fragment-id")

  get "/collection/@collection-id":
    resp collectionDetails(loadDatabase(), @"collection-id")

  get "/create-fragment":
    resp createFragmentForm(loadDatabase())

  get "/create-collection":
    resp createCollectionForm(loadDatabase())

  get "/select-fragment/@post-prefix/@post-dest":
    resp selectFragment(loadDatabase(), @"post-prefix", @"post-dest") 

  get "/add-fragment-to-collection/@collection-id/@fragment-id":
    loadDatabase() |> addFragmentToCollection(@"collection-id", @"fragment-id") |> saveDatabase
    resp reloadParent()

  get "/set-fragment-status/@fragment-id/@status":
    loadDatabase() |> setFragmentStatusMutation(@"fragment-id", encodeUrl(@"status")) |> saveDatabase
    resp script("window.parent.location.replace('/')")

  post "/remove-fragment-from-collection/@collection-id/@fragment-id":
    loadDatabase() |> removeFragmentFromCollection(@"collection-id", @"fragment-id") |> saveDatabase
    resp script("window.location.replace('/collection/" & @"collection-id" & "')")

  post "/delete-fragment/@fragment-id":
    loadDatabase() |> deleteFragmentMutation(@"fragment-id") |> saveDatabase
    resp script(""" window.top.location.href = "/" """)

  post "/delete-collection/@collection-id":
    loadDatabase() |> deleteCollectionMutation(@"collection-id") |> saveDatabase
    resp script(""" window.top.location.href = "/" """)

  post "/new-fragment":
    let body = request.body.decodeQuery.toSeq.toTable
    loadDatabase() |> newFragmentMutation(body) |> saveDatabase
    resp script(""" window.top.location.href = "/" """)

  post "/new-collection":
    let body = request.body.decodeQuery.toSeq.toTable
    loadDatabase() |> newCollectionMutation(body) |> saveDatabase
    resp script(""" window.top.location.href = "/" """)

when isMainModule:
  echo("Hello, World!")
