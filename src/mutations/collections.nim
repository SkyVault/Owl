import ../types/database
import cascade, oids, sequtils, sugar, tables, sets

proc addFragmentToCollection* (db: Database, collectionId, fragmentId: string): Database =
  var collections = db.collections.filter(c => c.id != collectionId)

  var 
    coll = findCollection(db, collectionId)
    frag = findFragment(db, fragmentId)

  coll.fragments.incl frag.id
  collections.add(coll)

  cascade db:
    collections = collections
  
proc removeFragmentFromCollection* (db: Database, collectionId, fragmentId: string): Database =
  var collections = db.collections.filter(c => c.id != collectionId)

  var 
    coll = findCollection(db, collectionId)
    frag = findFragment(db, fragmentId)

  coll.fragments.excl frag.id
  collections.add(coll)

  cascade db:
    collections = collections

proc newCollectionMutation* (db: Database, request: Dict): Database =
  cascade db:      
    collections.add(
      Collection(
        id: $genOid(),
        title: request["title"],
        description: request["description"],
      )
    )

proc deleteCollectionMutation* (db: Database, collectionId: string): Database =
  cascade db:
    collections = db.collections.filter(f => f.id != collectionId)
