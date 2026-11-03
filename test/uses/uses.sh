# Compiles a use of each refused value listed in $2, under the prelude whose
# compiled interfaces are in $1, and checks that it fails on the value's
# type. Prints each value that does not.
objs=$1
uses=$2
dir=uses.tmp
rm -rf "$dir"
mkdir "$dir"
failed=0
while read -r kind use; do
  printf 'open! Hermetic\nlet _ : int = %s\n' "$use" > "$dir/use.ml"
  if ocamlc -I "$objs" -c -o "$dir/use.cmo" "$dir/use.ml" > "$dir/log" 2>&1; then
    echo "$use: builds"
    failed=1
  elif ! tr -d '"' < "$dir/log" | tr '\n' ' ' | tr -s ' ' |
      grep -q "has type [A-Za-z_.]*$kind"; then
    echo "$use: not refused as $kind"
    failed=1
  fi
done < "$uses"
rm -rf "$dir"
exit $failed
