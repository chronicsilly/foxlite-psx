#!/bin/bash
haxe docs/docs.hxml
haxelib run dox -i docs/doc.xml -o pages --title "FoxLite Documentation" -in "foxlite" --toplevel-package foxlite --keep-field-order --include-private