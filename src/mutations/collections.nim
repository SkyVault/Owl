import ../types/database
import cascade, oids, sequtils, sugar, tables, sets

proc addFragmentToCollection* (db: Database, collectionId, fragmentId: string): Database =
  var 
    coll = findCollection(db, collectionId)
    frag = findFragment(db, fragmentId)

  coll.fragments.incl frag.id
  return db
  

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
