import ../types/database
import cascade, oids, sequtils, sugar, tables

proc newFragmentMutation* (db: Database, request: Dict): Database =
  cascade db:      
    fragments.add(
      Fragment(
        id: $genOid(),
        kind: FragmentKind.h1,
        status: request["status"],
        title: request["title"],
        description: request["description"],
        h1: "hello"
      )
    )

proc setFragmentStatusMutation* (db: Database, fragmentId: string, status: string): Database =
  var 
    fs = db.fragments.filter(f => f.id != fragmentId)
    fr = findFragment(db, fragmentId)

  fr.status = status

  fs.add(fr)

  cascade db:
    fragments = fs

proc deleteFragmentMutation* (db: Database, fragmentId: string): Database =
  cascade db:
    fragments = db.fragments.filter(f => f.id != fragmentId)
