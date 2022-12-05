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
    h2(title), 
    `div`(style="display: flex; column-gap: 8px", actions.join(""))
  )

proc actionSubTitle(title: string, actions: varargs[string]): string =
  span(
    style="display: flex; align-items: center; column-gap: 8px; justify-content: space-between",
    p(title), 
    `div`(style="display: flex; column-gap: 8px", actions.join(""))
  )

proc fragmentDetails(db: Database, fragmentId: string): string =
  let fragment = findFragment(db, fragmentId)
  `div`(
    h3(fragment.title),
    p(fragment.description)
  )

proc collectionDetailsActions(db: Database, id: Id): string =
  span(
    button("+", onclick="show_addfrag('/select-fragment/add-fragment-to-collection/" & id & "')")
  )

proc collectionDetails(db: Database, collectionId: string): string =
  let (addFrag, modalJs, modalCss) = modal("addfrag")

  let collection = findCollection(db, collectionId)
  `div`(
    script(modalJs),
    style(modalCss),
    addFrag,
    h3(collection.title),
    p(collection.description),
    collectionDetailsActions(db, collection.id)
  )

proc createFragmentForm(db: Database): string =
  form(action="/new-fragment", `method`="post",
    h2("NEW FRAGMENT"),
    label(`for`="title", "Title: "), 
    input(type="text", name="title"), br(),
    label(`for`="description", "Description: "), 
    input(type="text", name="description"), br(),
    input(type="submit", value="Submit")
  )

proc createCollectionForm(db: Database): string =
  form(action="/new-collection", `method`="post",
    h2("NEW COLLECTION"),
    label(`for`="title", "Title: "), 
    input(type="text", name="title"), br(),
    label(`for`="description", "Description: "), 
    input(type="text", name="description"), br(),
    input(type="submit", value="Submit")
  )

proc selectFragment(db: Database, postPrefix, postDest: string): string =
  `div`(
    collect(
      for f in db.fragments:
        span(
          style="display: flex; column-gap: 8px; align-items: center;",
          p(f.title), button(
            style="height: 24px",
            "select", onclick="window.location.href = '/" & postPrefix & "/" & postDest & "/" & f.id & "'"))
    ).join("")
  )

proc dashboard(db: Database): string =
  let (fragmentDetailsModal, modalJs, modalCss) = modal("fragment_details")
  let (collectionDetailsModal, collModalJs, _) = modal("collection_details")
  let (createFragmentsModal, createFragmentsJs, _) = modal("createf")
  let (createCollectionModal, createCollectionJs, _) = modal("createc")

  `div`(
    style(modalCss, "\n"),
    script(modalJs, "\n", collModalJs,"\n" , createFragmentsJs, "\n", createCollectionJs),
    fragmentDetailsModal,
    collectionDetailsModal,
    createFragmentsModal,
    createCollectionModal,
    `div`(
      h1("Database"),
      actionTitle(
        "Collections",
        button("+", onclick="show_createc('/create-collection')")
      ),
      ul(
        collect(
          for c in db.collections:
            actionSubTitle(
              a(onclick=fmt"show_collection_details('/collection/{c.id}')", c.title),
              button(style="height: 24px", "Open", onclick=fmt"window.location.href += 'collection/" & c.id & "'"),
              postButton("Delete", "/delete-collection/" & c.id)
            )
        ).join("")
      )
    ),
    
    `div`(
      actionTitle(
        "Fragments",
        button("+", onclick=fmt"show_createf('/create-fragment')")
      ),
      ul(
        collect(
          for f in db.fragments:
            actionSubTitle(
              a(onclick=fmt"show_fragment_details('/fragment/{f.id}')", f.title), 
              button(style="height: 24px", "Open", onclick=fmt"window.location.href += 'fragment/" & f.id & "'"),
              postButton("Delete", "/delete-fragment/" & f.id)
            ),
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
    
    resp script(""" window.top.location.href = "/" """)

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
