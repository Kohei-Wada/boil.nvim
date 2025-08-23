{{function_name}}() {
  local result
  result=$({{__selection__}}) || {
    echo "Error in {{function_name}}: Command failed" >&2
    return 1
  }
  echo "$result"
}
