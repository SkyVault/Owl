import ../types/database
import cascade, oids, sequtils, sugar, tables

proc newFragmentMutation* (db: Database, request: Dict): Database =
  cascade db:      
    echo request
    fragments.add(
      Fragment(
        id: $genOid(),
        kind: FragmentKind.h1,
        title: request["title"],
        description: request["description"],
        h1: "hello"
      )
    )

proc deleteFragmentMutation* (db: Database, fragmentId: string): Database =
  cascade db:
    fragments = db.fragments.filter(f => f.id != fragmentId)
