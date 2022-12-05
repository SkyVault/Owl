import tables, sets, oids, os, jsony

type
  Id* = string

  Dict* = Table[string, string]

  Atom* = object of RootObj
    id* : Id
    title* : string
    description* : string

  FragmentKind* {.pure.} = enum
    document
    h1

  Fragment* = object of Atom
    tags* : HashSet[string]
    status* : string
    case kind* : FragmentKind
      of FragmentKind.document:
        fragments* : seq[Fragment]
      of FragmentKind.h1:
        h1* : string

  Collection* = object of Atom
    fragments* : HashSet[Id]

  Database* = object
    collections* : seq[Collection]
    fragments* : seq[Fragment]

proc statuses* (database: Database): HashSet[string] =
  result.incl "Backlog";
  result.incl "In-Progress";
  result.incl "Completed";
  result.incl "Feedback";
  result.incl "Testing";
  for f in database.fragments:
    result.incl(f.status)

proc findFragment* (database: Database, fragmentId: Id): Fragment =
  for f in database.fragments:
    if f.id == fragmentId:
      return f

proc findCollection* (database: Database, collectionId: Id): Collection =
  for c in database.collections:
    if c.id == collectionId:
      return c

proc nextId* (): Id =
  result = Id($genOid())

proc saveDatabase* (database: Database): Database {.discardable.} =
  let js = database.toJson()
  writeFile("database.json", js)
  database

proc loadDatabase* (): Database =
  if fileExists("database.json"):
    result = readFile("database.json").fromJson(Database)
  else:
    result = Database(
      collections: @[],
      fragments: @[
        Fragment(
          id: "hello",
          kind: FragmentKind.h1,
          title: "Hello",
          description: "Description of the fragment",
          h1: "hello",
          status: "Backlog",
        )
      ]
    )
    saveDatabase(result)
